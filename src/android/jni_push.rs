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

/// Runs `work` with the Matrix client, blocking the calling Java thread.
/// `None` until the runtime and client exist (see `nativeInitForPush`).
fn with_client<F, Fut>(work: F) -> Option<Fut::Output>
where
    F: FnOnce(Client) -> Fut,
    Fut: Future,
{
    let client = crate::utils::matrix::CLIENT.get()?.clone();
    Some(super::runtime().block_on(work(client)))
}

/// Base dir holding the push endpoint and gateway files.
fn base_dir() -> Option<std::path::PathBuf> {
    let data_dir = crate::utils::matrix::DATA_DIR.get()?;
    Some(data_dir.parent().unwrap_or(data_dir).to_path_buf())
}

/// Initialise the Rust SDK in a push-notification context (app killed).
///
/// Spins up a Tokio runtime (if not already running) and restores the Matrix
/// client from the persisted session so all enrichment JNI functions work,
/// including decryption of E2E events. A no-op when already initialised.
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
    if crate::utils::matrix::CLIENT.get().is_some() {
        return 1;
    }
    let Some(data_dir) = read_string(&mut env, &data_dir) else {
        return 0;
    };

    let base_dir = std::path::PathBuf::from(data_dir);
    let restored = super::runtime().block_on(async move {
        crate::utils::matrix::restore_matrix_client(base_dir)
            .await
            .unwrap_or(false)
    });
    restored as jboolean
}

/// A new UnifiedPush endpoint: persist it and register the pusher right away
/// when the client is loaded.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeEndpointChanged(
    mut env: JNIEnv,
    _class: JClass,
    endpoint: JString,
) {
    let Some(endpoint) = read_string(&mut env, &endpoint) else {
        return;
    };
    let handle = super::runtime().handle();
    if let Some(base_dir) = base_dir() {
        let endpoint = endpoint.clone();
        handle.spawn(async move {
            crate::utils::push::persist_endpoint(&base_dir, &endpoint).await;
        });
    }
    if let Some(client) = crate::utils::matrix::CLIENT.get().cloned() {
        handle.spawn(async move {
            crate::utils::push::register_pusher(&client, &endpoint).await;
        });
    }
}

/// The UnifiedPush registration was revoked.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeEndpointCleared(
    _env: JNIEnv,
    _class: JClass,
) {
    let Some(base_dir) = base_dir() else {
        return;
    };
    let client = crate::utils::matrix::CLIENT.get().cloned();
    super::runtime().spawn(async move {
        match client {
            Some(client) => crate::utils::push::unregister_pusher(&client, &base_dir).await,
            None => crate::utils::push::clear_endpoint(&base_dir).await,
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
    room_id: JString,
    event_id: JString,
) -> jstring {
    let (Some(room_id), Some(event_id)) = (
        read_string(&mut env, &room_id),
        read_string(&mut env, &event_id),
    ) else {
        return std::ptr::null_mut();
    };
    let room = room_id.clone();
    let outcome = with_client(|client| async move {
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
    room_id: JString,
) -> jbyteArray {
    let bytes = read_string(&mut env, &room_id).and_then(|room_id| {
        with_client(|_| async move {
            let room = crate::utils::matrix::get_room(&room_id)?;
            avatars::of_room(&room).await
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
    room_id: JString,
    sender_id: JString,
) -> jbyteArray {
    let source = read_string(&mut env, &room_id)
        .zip(read_string(&mut env, &sender_id))
        .map(|(room_id, sender_id)| AvatarSource::member(room_id, sender_id));
    let bytes = source
        .and_then(|source| with_client(|_| async move { avatars::fetch(&source).await }).flatten());
    to_jbytes(&mut env, bytes)
}

/// The image of an image message (the notification's picture).
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchEventImageBytes(
    mut env: JNIEnv,
    _class: JClass,
    room_id: JString,
    event_id: JString,
) -> jbyteArray {
    let ids = read_string(&mut env, &room_id).zip(read_string(&mut env, &event_id));
    let bytes = ids.and_then(|(room_id, event_id)| {
        with_client(|client| async move {
            crate::utils::push::fetch_event_image(&client, &room_id, &event_id).await
        })
        .flatten()
    });
    to_jbytes(&mut env, bytes)
}

/// Of `[{roomId, ts}]` (ts: when the notification was shown, ms), the room IDs
/// read since, as a JSON array.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeGetReadRooms(
    mut env: JNIEnv,
    _class: JClass,
    room_ids_json: JString,
) -> jstring {
    let entries: Vec<(String, u64)> = read_string(&mut env, &room_ids_json)
        .and_then(|json| serde_json::from_str::<Vec<serde_json::Value>>(&json).ok())
        .unwrap_or_default()
        .into_iter()
        .filter_map(|v| {
            let room_id = v.get("roomId")?.as_str()?.to_string();
            let ts = v.get("ts").and_then(|ts| ts.as_u64()).unwrap_or(0);
            Some((room_id, ts))
        })
        .collect();
    let read_rooms =
        with_client(
            |client| async move { crate::utils::push::get_read_rooms(&client, entries).await },
        )
        .unwrap_or_default();
    let json = serde_json::to_string(&read_rooms).unwrap_or_else(|_| "[]".to_string());
    to_jstring(&mut env, Some(json))
}

/// A notification was tapped (`MainActivity`): open its room once the app is ready.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeOpenRoom(
    mut env: JNIEnv,
    _class: JClass,
    room_id: JString,
) {
    if let Some(room_id) = read_string(&mut env, &room_id) {
        crate::app::navigation::request_open_room(room_id);
    }
}

/// Notification "Reply": sends `body` to the room. Call `nativeInitForPush` first.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeSendReply(
    mut env: JNIEnv,
    _class: JClass,
    room_id: JString,
    body: JString,
) -> jboolean {
    let Some((room_id, body)) = read_string(&mut env, &room_id).zip(read_string(&mut env, &body))
    else {
        return 0;
    };
    with_client(
        |client| async move { crate::utils::push::send_text(&client, &room_id, &body).await },
    )
    .unwrap_or(false) as jboolean
}

/// Notification "Mark as read": read receipt + fully-read marker on `event_id`.
/// Call `nativeInitForPush` first.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeMarkRead(
    mut env: JNIEnv,
    _class: JClass,
    room_id: JString,
    event_id: JString,
) -> jboolean {
    let Some((room_id, event_id)) =
        read_string(&mut env, &room_id).zip(read_string(&mut env, &event_id))
    else {
        return 0;
    };
    with_client(|client| async move {
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
