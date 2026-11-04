//! JNI exports for the Kotlin `PushReceiver.NativeBridge` (push enrichment,
//! UnifiedPush endpoint changes, notification taps and actions, window insets).

use std::future::Future;

use jni::{
    JNIEnv,
    objects::{JClass, JObject, JString},
    sys::{jboolean, jbyteArray, jstring},
};
use matrix_sdk::Client;
use matrix_sdk::ruma::exports::serde_json;

use crate::utils::avatars::{self, AvatarSource};
use crate::utils::push::NotifOutcome;

fn read_string(env: &mut JNIEnv, value: &JString) -> Option<String> {
    env.get_string(value).ok().map(Into::into)
}

fn to_jstring(env: &mut JNIEnv, value: Option<String>) -> jstring {
    value
        .and_then(|value| env.new_string(value).ok())
        .map(|s| s.into_raw())
        .unwrap_or(std::ptr::null_mut())
}

fn to_jbytes(env: &mut JNIEnv, bytes: Option<Vec<u8>>) -> jbyteArray {
    bytes
        .and_then(|bytes| env.byte_array_from_slice(&bytes).ok())
        .map(|array| array.into_raw())
        .unwrap_or(std::ptr::null_mut())
}

/// Runs `work` with the client of `account`, blocking the calling Java
/// thread. `None` until `nativeInitForPush` ran, or if the account can't be
/// opened.
fn with_client<F, Fut>(account: &str, work: F) -> Option<Fut::Output>
where
    F: FnOnce(Client) -> Fut,
    Fut: Future,
{
    crate::utils::matrix::DATA_DIR.get()?;
    super::runtime().block_on(async {
        let client = crate::utils::matrix::account_client(account).await?;
        Some(work(client).await)
    })
}

/// The account's directory, holding its push endpoint and gateway files.
fn account_dir(account: &str) -> Option<std::path::PathBuf> {
    crate::utils::accounts::dir(account)
}

/// Initialise the Rust SDK in a push-notification context (app killed).
///
/// Spins up a Tokio runtime (if not already running) and restores the active
/// account's client from the persisted session so all enrichment JNI
/// functions work, including decryption of E2E events (the other accounts'
/// clients open on their first push). A no-op when already initialised.
/// False when no account is signed in.
/// `context` sets up the TLS verifier, which `android_main` doesn't when the
/// process was started for a push.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeInitForPush(
    mut env: JNIEnv,
    _class: JClass,
    context: JObject,
    data_dir: JString,
) -> jboolean {
    let Ok(vm) = env.get_java_vm() else {
        return 0;
    };
    super::init_tls_verifier_raw(vm.get_java_vm_pointer().cast(), context.as_raw().cast());
    if crate::utils::matrix::DATA_DIR.get().is_some() {
        return has_accounts();
    }
    let Some(data_dir) = read_string(&mut env, &data_dir) else {
        return 0;
    };

    let base_dir = std::path::PathBuf::from(data_dir);
    super::runtime().block_on(async move {
        if let Err(e) = crate::utils::matrix::restore_matrix_client(base_dir).await {
            tracing::warn!("push: could not restore the active account: {e:#}");
        }
    });
    has_accounts()
}

fn has_accounts() -> jboolean {
    !crate::utils::accounts::registry().accounts.is_empty() as jboolean
}

/// A new UnifiedPush endpoint for `account` (its instance): persist it and
/// register the pusher right away. Call `nativeInitForPush` first.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeEndpointChanged(
    mut env: JNIEnv,
    _class: JClass,
    account: JString,
    endpoint: JString,
) {
    let Some((account, endpoint)) =
        read_string(&mut env, &account).zip(read_string(&mut env, &endpoint))
    else {
        return;
    };
    let Some(dir) = account_dir(&account) else {
        return;
    };
    super::runtime().spawn(async move {
        crate::utils::push::persist_endpoint(&dir, &endpoint).await;
        if let Some(client) = crate::utils::matrix::account_client(&account).await {
            crate::utils::push::register_pusher(&client, &dir, &endpoint).await;
        }
    });
}

/// The UnifiedPush registration of `account` was revoked.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeEndpointCleared(
    mut env: JNIEnv,
    _class: JClass,
    account: JString,
) {
    let Some(account) = read_string(&mut env, &account) else {
        return;
    };
    let Some(dir) = account_dir(&account) else {
        return;
    };
    super::runtime().spawn(async move {
        match crate::utils::matrix::account_client(&account).await {
            Some(client) => crate::utils::push::unregister_pusher(&client, &dir).await,
            None => crate::utils::push::clear_endpoint(&dir).await,
        }
    });
}

/// Notification content for a pushed event, as JSON: the fields of
/// `NotifPayload::to_json`, `{"skip":true}` when there is nothing to show, or
/// null when the event couldn't be loaded.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchNotificationPayload(
    mut env: JNIEnv,
    _class: JClass,
    account: JString,
    room_id: JString,
    event_id: JString,
) -> jstring {
    let (Some(account), Some(room_id), Some(event_id)) = (
        read_string(&mut env, &account),
        read_string(&mut env, &room_id),
        read_string(&mut env, &event_id),
    ) else {
        return std::ptr::null_mut();
    };
    let room = room_id.clone();
    let outcome = with_client(&account, |client| async move {
        crate::utils::push::fetch_notification_payload(&client, &room, &event_id).await
    });
    let json = match outcome {
        Some(NotifOutcome::Show(payload)) => Some(payload.to_json(&room_id)),
        Some(NotifOutcome::Skip) => Some(serde_json::json!({ "skip": true })),
        Some(NotifOutcome::Unavailable) | None => None,
    };
    to_jstring(&mut env, json.map(|json| json.to_string()))
}

/// A group's own avatar (the notification's picture, else a letter avatar):
/// not `AvatarSource::Room`, whose fallback to a member's picture would show
/// a random person as the conversation.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchRoomAvatarBytes(
    mut env: JNIEnv,
    _class: JClass,
    account: JString,
    room_id: JString,
) -> jbyteArray {
    let ids = read_string(&mut env, &account).zip(read_string(&mut env, &room_id));
    let bytes = ids.and_then(|(account, room_id)| {
        with_client(&account, |client| async move {
            let room_id = matrix_sdk::ruma::RoomId::parse(&room_id).ok()?;
            avatars::of_room(&client.get_room(&room_id)?).await
        })
        .flatten()
    });
    to_jbytes(&mut env, bytes)
}

/// Avatar of a message's sender, as seen in that room.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchSenderAvatarBytes(
    mut env: JNIEnv,
    _class: JClass,
    account: JString,
    room_id: JString,
    sender_id: JString,
) -> jbyteArray {
    let account = read_string(&mut env, &account);
    let source = read_string(&mut env, &room_id)
        .zip(read_string(&mut env, &sender_id))
        .map(|(room_id, sender_id)| AvatarSource::member(room_id, sender_id));
    let bytes = account.zip(source).and_then(|(account, source)| {
        with_client(&account, |client| async move {
            avatars::fetch_with(&client, &source).await
        })
        .flatten()
    });
    to_jbytes(&mut env, bytes)
}

/// The image of an image message (the notification's picture).
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchEventImageBytes(
    mut env: JNIEnv,
    _class: JClass,
    account: JString,
    room_id: JString,
    event_id: JString,
) -> jbyteArray {
    let account = read_string(&mut env, &account);
    let ids = read_string(&mut env, &room_id).zip(read_string(&mut env, &event_id));
    let bytes = account.zip(ids).and_then(|(account, (room_id, event_id))| {
        with_client(&account, |client| async move {
            crate::utils::push::fetch_event_image(&client, &room_id, &event_id).await
        })
        .flatten()
    });
    to_jbytes(&mut env, bytes)
}

/// Of `[{account, roomId, ts}]` (ts: when the notification was shown, ms),
/// the rooms read since, as `[{account, roomId}]`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeGetReadRooms(
    mut env: JNIEnv,
    _class: JClass,
    room_ids_json: JString,
) -> jstring {
    let mut by_account: Vec<(String, Vec<(String, u64)>)> = Vec::new();
    let values = read_string(&mut env, &room_ids_json)
        .and_then(|json| serde_json::from_str::<Vec<serde_json::Value>>(&json).ok())
        .unwrap_or_default();
    for v in values {
        let (Some(account), Some(room_id)) = (
            v.get("account").and_then(|a| a.as_str()),
            v.get("roomId").and_then(|r| r.as_str()),
        ) else {
            continue;
        };
        let ts = v.get("ts").and_then(|ts| ts.as_u64()).unwrap_or(0);
        let entry = (room_id.to_string(), ts);
        match by_account.iter_mut().find(|(a, _)| a == account) {
            Some((_, entries)) => entries.push(entry),
            None => by_account.push((account.to_string(), vec![entry])),
        }
    }
    let mut read = Vec::new();
    for (account, entries) in by_account {
        let rooms = with_client(&account, |client| async move {
            crate::utils::push::get_read_rooms(&client, entries).await
        })
        .unwrap_or_default();
        read.extend(
            rooms
                .into_iter()
                .map(|room_id| serde_json::json!({ "account": account, "roomId": room_id })),
        );
    }
    let json = serde_json::to_string(&read).unwrap_or_else(|_| "[]".to_string());
    to_jstring(&mut env, Some(json))
}

/// A notification was tapped (`MainActivity`): open its room once the app is
/// ready (in its account: see `navigation::use_open_room_requests`).
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeOpenRoom(
    mut env: JNIEnv,
    _class: JClass,
    account: JString,
    room_id: JString,
) {
    if let Some((account, room_id)) =
        read_string(&mut env, &account).zip(read_string(&mut env, &room_id))
    {
        crate::app::navigation::request_open_room(Some(account), room_id);
    }
}

/// Notification "Reply": sends `body` to the room. Call `nativeInitForPush` first.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeSendReply(
    mut env: JNIEnv,
    _class: JClass,
    account: JString,
    room_id: JString,
    body: JString,
) -> jboolean {
    let Some(account) = read_string(&mut env, &account) else {
        return 0;
    };
    let Some((room_id, body)) = read_string(&mut env, &room_id).zip(read_string(&mut env, &body))
    else {
        return 0;
    };
    with_client(&account, |client| async move {
        crate::utils::push::send_text(&client, &room_id, &body).await
    })
    .unwrap_or(false) as jboolean
}

/// Notification "Mark as read": read receipt + fully-read marker on `event_id`.
/// Call `nativeInitForPush` first.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeMarkRead(
    mut env: JNIEnv,
    _class: JClass,
    account: JString,
    room_id: JString,
    event_id: JString,
) -> jboolean {
    let Some(account) = read_string(&mut env, &account) else {
        return 0;
    };
    let Some((room_id, event_id)) =
        read_string(&mut env, &room_id).zip(read_string(&mut env, &event_id))
    else {
        return 0;
    };
    with_client(&account, |client| async move {
        crate::utils::push::mark_read(&client, &room_id, &event_id).await
    })
    .unwrap_or(false) as jboolean
}

/// System bar and keyboard insets from `MainActivity`, in density-independent
/// pixels (Freya's logical pixels).
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeSetInsets(
    _env: JNIEnv,
    _class: JClass,
    top: jni::sys::jfloat,
    bottom: jni::sys::jfloat,
    ime: jni::sys::jfloat,
) {
    crate::utils::insets::set(crate::utils::insets::Insets { top, bottom, ime });
}
