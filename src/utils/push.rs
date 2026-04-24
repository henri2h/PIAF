use std::path::Path;
use std::sync::OnceLock;

#[cfg(target_os = "android")]
pub static JAVA_VM: OnceLock<jni::JavaVM> = OnceLock::new();
#[cfg(target_os = "android")]
pub static ANDROID_APP_CONTEXT: OnceLock<jni::objects::GlobalRef> = OnceLock::new();
/// The app's ClassLoader, cached at startup.
///
/// `JNIEnv::find_class` uses the *calling thread's* context ClassLoader.
/// On plain background (tokio) threads that context is the system ClassLoader,
/// which can't see app DEX classes.  We cache the Application ClassLoader here
/// and use it explicitly whenever we need to look up `dev.piaf.app.*` classes
/// from a non-main thread.
#[cfg(target_os = "android")]
pub static APP_CLASS_LOADER: OnceLock<jni::objects::GlobalRef> = OnceLock::new();

use matrix_sdk::{
    Client,
    media::MediaFormat,
    ruma::{
        EventId, OwnedRoomId, RoomId,
        api::client::push::{PusherIds, PusherInit, PusherKind},
        events::{
            AnySyncMessageLikeEvent, AnySyncTimelineEvent, SyncMessageLikeEvent,
            room::message::MessageType,
        },
        push::{HttpPusherData, PushFormat},
    },
};
use tokio::fs;

const APP_ID: &str = "app.piaf.android";
const ENDPOINT_FILENAME: &str = "push_endpoint";
const GATEWAY_FILENAME: &str = "push_gateway";
const DEFAULT_GATEWAY: &str = "https://matrix.gateway.unifiedpush.org/_matrix/push/v1/notify";

fn endpoint_file(base_dir: &Path) -> std::path::PathBuf {
    base_dir.join(ENDPOINT_FILENAME)
}

fn gateway_file(base_dir: &Path) -> std::path::PathBuf {
    base_dir.join(GATEWAY_FILENAME)
}

async fn resolve_gateway() -> String {
    let Some(dir) = base_dir() else {
        return DEFAULT_GATEWAY.to_string();
    };
    match fs::read_to_string(gateway_file(&dir)).await {
        Ok(gw) => {
            let gw = gw.trim().to_string();
            if gw.is_empty() {
                DEFAULT_GATEWAY.to_string()
            } else {
                gw
            }
        }
        Err(_) => DEFAULT_GATEWAY.to_string(),
    }
}

pub async fn get_push_gateway() -> String {
    resolve_gateway().await
}

pub async fn set_push_gateway(gateway: &str) {
    let Some(dir) = base_dir() else { return };
    if gateway.trim().is_empty() {
        let _ = fs::remove_file(gateway_file(&dir)).await;
    } else {
        let _ = fs::write(gateway_file(&dir), gateway.trim()).await;
    }
}

/// Read the persisted UP endpoint (if any) and register it with the homeserver.
pub async fn register_pusher_if_stored(client: &Client, base_dir: &Path) {
    let file = endpoint_file(base_dir);
    match fs::read_to_string(&file).await {
        Ok(endpoint) => {
            let endpoint = endpoint.trim().to_string();
            if !endpoint.is_empty() {
                println!("Registering persisted UP pusher: {endpoint}");
                register_pusher(client, &endpoint).await;
            }
        }
        Err(_) => {} // no endpoint stored yet — nothing to do
    }
}

/// Register (or update) an HTTP pusher for the given UP endpoint URL.
///
/// The pushkey is the UP endpoint URL itself so the push gateway can route
/// the notification back to the correct UP subscriber.
pub async fn register_pusher(client: &Client, endpoint: &str) {
    let gw = resolve_gateway().await;
    println!("Registering UP pusher: gateway={gw}");

    let mut http_data = HttpPusherData::new(gw);
    http_data.format = Some(PushFormat::EventIdOnly);

    let pusher = PusherInit {
        ids: PusherIds::new(endpoint.to_string(), APP_ID.to_string()),
        kind: PusherKind::Http(http_data),
        app_display_name: "PIAF".to_string(),
        device_display_name: client
            .device_id()
            .map(|d| d.to_string())
            .unwrap_or_else(|| "Android".to_string()),
        lang: "en".to_string(),
        // Store device_id in profile_tag so we can correlate with device list.
        profile_tag: client.device_id().map(|d| d.to_string()),
    };

    match client.pusher().set(pusher.into()).await {
        Ok(_) => println!("UP pusher registered successfully"),
        Err(e) => println!("Failed to register UP pusher: {e}"),
    }
}

/// Unregister the HTTP pusher and delete the endpoint file.
pub async fn unregister_pusher(client: &Client, base_dir: &Path) {
    let endpoint = match fs::read_to_string(endpoint_file(base_dir)).await {
        Ok(s) => s.trim().to_string(),
        Err(_) => return,
    };
    if endpoint.is_empty() {
        return;
    }

    let ids = PusherIds::new(endpoint, APP_ID.to_string());
    if let Err(e) = client.pusher().delete(ids).await {
        println!("Failed to delete UP pusher: {e}");
    }

    let _ = fs::remove_file(endpoint_file(base_dir)).await;
}

/// Persist the endpoint URL to disk so it survives app restarts.
pub async fn persist_endpoint(base_dir: &Path, endpoint: &str) {
    let _ = fs::write(endpoint_file(base_dir), endpoint).await;
}

/// Delete the persisted endpoint file.
pub async fn clear_endpoint(base_dir: &Path) {
    let _ = fs::remove_file(endpoint_file(base_dir)).await;
}

/// Return the base dir (parent of DATA_DIR's persist_session folder).
fn base_dir() -> Option<std::path::PathBuf> {
    crate::utils::matrix::DATA_DIR
        .get()
        .and_then(|d| d.parent())
        .map(|p| p.to_path_buf())
}

/// Read the currently stored UP endpoint URL, if any.
pub async fn get_current_endpoint() -> Option<String> {
    let dir = base_dir()?;
    fs::read_to_string(endpoint_file(&dir))
        .await
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
}

/// Check whether a pusher for this app is currently registered on the homeserver.
pub async fn is_pusher_registered(client: &Client) -> bool {
    use matrix_sdk::ruma::api::client::push::get_pushers;
    client
        .send(get_pushers::v3::Request::new())
        .await
        .map(|r| r.pushers.iter().any(|p| p.ids.app_id == APP_ID))
        .unwrap_or(false)
}

/// Re-register using the stored endpoint (convenience for UI actions).
/// Returns `Ok(endpoint_url)` on success, `Err(message)` on failure.
pub async fn reregister(client: &Client) -> Result<String, String> {
    let Some(dir) = base_dir() else {
        return Err("Data directory not available".into());
    };
    let Some(endpoint) = fs::read_to_string(endpoint_file(&dir))
        .await
        .ok()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
    else {
        return Err("No UP endpoint stored — open the app after installing a distributor".into());
    };
    register_pusher(client, &endpoint).await;
    Ok(endpoint)
}

/// Unregister using the globally known base dir (convenience for UI actions).
pub async fn unregister(client: &Client) -> Result<(), String> {
    let Some(dir) = base_dir() else {
        return Err("Data directory not available".into());
    };
    unregister_pusher(client, &dir).await;
    Ok(())
}

// ---------------------------------------------------------------------------
// Notification enrichment helpers
// ---------------------------------------------------------------------------

pub struct NotifPayload {
    pub room_name: String,
    pub sender_id: String,
    pub sender_display_name: String,
    pub body: String,
    pub is_image: bool,
}

/// Fetch enriched notification content for a given room + event.
/// Returns None if the event can't be found or isn't a displayable message.
pub async fn fetch_notification_payload(
    client: &Client,
    room_id_str: &str,
    event_id_str: &str,
) -> Option<NotifPayload> {
    use matrix_sdk::ruma::UserId;
    use matrix_sdk::ruma::events::room::MediaSource;

    let room_id = RoomId::parse(room_id_str).ok()?;
    let event_id = EventId::parse(event_id_str).ok()?;
    let room = client.get_room(&room_id)?;

    let room_name = room
        .display_name()
        .await
        .ok()
        .map(|n| n.to_string())
        .unwrap_or_else(|| "PIAF".to_string());

    let timeline_event = room.event(&event_id, None).await.ok()?;

    let (sender_id, body, is_image) = match timeline_event.kind.raw().deserialize().ok()? {
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
            SyncMessageLikeEvent::Original(msg),
        )) => {
            let (body, is_image) = match msg.content.msgtype {
                MessageType::Text(t) => (t.body, false),
                MessageType::Image(_) => ("📷 Image".to_string(), true),
                MessageType::File(_) => ("📎 File".to_string(), false),
                MessageType::Audio(_) => ("🎵 Audio".to_string(), false),
                MessageType::Video(_) => ("🎬 Video".to_string(), false),
                _ => return None,
            };
            (msg.sender.to_string(), body, is_image)
        }
        _ => return None,
    };

    let sender_uid = UserId::parse(&sender_id).ok()?;
    let sender_display_name = room
        .get_member_no_sync(&sender_uid)
        .await
        .ok()
        .flatten()
        .and_then(|m| m.display_name().map(|s| s.to_string()))
        .unwrap_or_else(|| {
            sender_id
                .trim_start_matches('@')
                .split(':')
                .next()
                .unwrap_or(&sender_id)
                .to_string()
        });

    Some(NotifPayload {
        room_name,
        sender_id,
        sender_display_name,
        body,
        is_image,
    })
}

/// Fetch the sender's avatar bytes for a given room member.
pub async fn fetch_sender_avatar(
    client: &Client,
    room_id_str: &str,
    sender_id_str: &str,
) -> Option<Vec<u8>> {
    use matrix_sdk::media::{MediaFormat, MediaRequestParameters};
    use matrix_sdk::ruma::events::room::MediaSource;
    use matrix_sdk::ruma::{RoomId, UserId};

    let room_id = RoomId::parse(room_id_str).ok()?;
    let sender_id = UserId::parse(sender_id_str).ok()?;
    let room = client.get_room(&room_id)?;
    let member = room.get_member_no_sync(&sender_id).await.ok().flatten()?;
    let avatar_url = member.avatar_url()?;
    let request = MediaRequestParameters {
        source: MediaSource::Plain(avatar_url.to_owned()),
        format: MediaFormat::File,
    };
    client
        .media()
        .get_media_content(&request, true)
        .await
        .ok()
        .map(|b| b.to_vec())
}

/// Fetch the image bytes for an image message event (for notification thumbnail).
pub async fn fetch_event_image(
    client: &Client,
    room_id_str: &str,
    event_id_str: &str,
) -> Option<Vec<u8>> {
    use matrix_sdk::media::{MediaFormat, MediaRequestParameters};

    let room_id = RoomId::parse(room_id_str).ok()?;
    let event_id = EventId::parse(event_id_str).ok()?;
    let room = client.get_room(&room_id)?;
    let timeline_event = room.event(&event_id, None).await.ok()?;

    let source = match timeline_event.kind.raw().deserialize().ok()? {
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
            SyncMessageLikeEvent::Original(msg),
        )) => match msg.content.msgtype {
            MessageType::Image(img) => img.source,
            _ => return None,
        },
        _ => return None,
    };

    let request = MediaRequestParameters {
        source,
        format: MediaFormat::File,
    };
    client
        .media()
        .get_media_content(&request, true)
        .await
        .ok()
        .map(|b| b.to_vec())
}

/// Fetch the room avatar as raw bytes (for use as notification large icon).
pub async fn fetch_room_avatar(client: &Client, room_id_str: &str) -> Option<Vec<u8>> {
    let room_id: OwnedRoomId = RoomId::parse(room_id_str).ok()?;
    let room = client.get_room(&room_id)?;
    room.avatar(MediaFormat::File).await.ok().flatten()
}

/// Returns the subset of `entries` where the user's read receipt post-dates
/// the notification timestamp, i.e. the room was read (on any device) after
/// the notification was shown.
///
/// Each entry is `(room_id, notification_ts_ms)` where `notification_ts_ms`
/// is the millisecond wall-clock time when the notification was displayed.
pub async fn get_read_rooms(client: &Client, entries: Vec<(String, u64)>) -> Vec<String> {
    use matrix_sdk::ruma::events::receipt::{ReceiptThread, ReceiptType};

    let user_id = match client.user_id() {
        Some(id) => id.to_owned(),
        None => return vec![],
    };

    let mut read = Vec::new();
    for (room_id_str, notif_ts_ms) in entries {
        let room_id = match RoomId::parse(&room_id_str) {
            Ok(id) => id,
            Err(_) => continue,
        };
        let room = match client.get_room(&room_id) {
            Some(r) => r,
            None => continue,
        };

        let receipt = room
            .load_user_receipt(ReceiptType::Read, ReceiptThread::Unthreaded, &user_id)
            .await
            .ok()
            .flatten();

        if let Some((_receipt_event_id, receipt)) = receipt {
            if let Some(ts) = receipt.ts {
                let receipt_ms = u64::from(ts.get());
                if receipt_ms >= notif_ts_ms {
                    read.push(room_id_str);
                }
            }
        }
    }
    read
}

/// Look up an app class using the cached Application ClassLoader.
///
/// `JNIEnv::find_class` on a bare background thread uses the system ClassLoader
/// and cannot see DEX classes.  This helper uses the ClassLoader stored in
/// `APP_CLASS_LOADER` (set during `android_main`) which can resolve all app classes.
#[cfg(target_os = "android")]
fn find_app_class<'a>(
    env: &mut jni::JNIEnv<'a>,
    class_name: &str,
) -> Option<jni::objects::JClass<'a>> {
    // Dots in the class name (loadClass style); slashes for find_class.
    // The ClassLoader.loadClass API uses dots.
    let dotted = class_name.replace('/', ".");
    let loader = APP_CLASS_LOADER.get()?;
    let name_jstr = env.new_string(&dotted).ok()?;
    let cls_obj = env
        .call_method(
            loader.as_obj(),
            "loadClass",
            "(Ljava/lang/String;)Ljava/lang/Class;",
            &[(&name_jstr).into()],
        )
        .and_then(|v| v.l())
        .ok()?;
    if cls_obj.is_null() {
        return None;
    }
    Some(jni::objects::JClass::from(cls_obj))
}

/// Called after every sync batch on Android: checks the notified-room list (stored in
/// Kotlin SharedPreferences) and cancels any notifications for rooms whose unread count
/// has dropped to zero — including rooms read on a different device.
///
/// Flow (no re-entrant block_on):
///   1. JNI call → Kotlin `getNotifiedRoomsJson` (reads SharedPrefs, no Rust call-back)
///   2. `get_read_rooms` runs in native async context
///   3. JNI call → Kotlin `cancelNotificationsForRooms` (NotificationManager + SharedPrefs cleanup)
#[cfg(target_os = "android")]
pub async fn cancel_read_notifications_after_sync(client: &Client) {
    use matrix_sdk::ruma::exports::serde_json;

    let vm = match JAVA_VM.get() {
        Some(v) => v,
        None => return,
    };
    let app_ctx = match ANDROID_APP_CONTEXT.get() {
        Some(c) => c,
        None => return,
    };

    // Step 1: ask Kotlin for the current notified-room list (JSON array of room_id strings).
    let notified_json: String = {
        let mut env = match vm.attach_current_thread() {
            Ok(e) => e,
            Err(_) => return,
        };
        let cls = match find_app_class(&mut env, "dev/piaf/app/PushReceiver") {
            Some(c) => c,
            None => return,
        };
        let ctx = app_ctx.as_obj();
        let result = env.call_static_method(
            &cls,
            "getNotifiedRoomsJson",
            "(Landroid/content/Context;)Ljava/lang/String;",
            &[(&ctx).into()],
        );
        match result.and_then(|v| v.l()) {
            Ok(obj) if !obj.is_null() => match env.get_string(&jni::objects::JString::from(obj)) {
                Ok(s) => String::from(s),
                Err(_) => return,
            },
            _ => return,
        }
    };

    // Step 2: parse [{roomId, ts}] and check — pure Rust async, no JNI.
    let entries: Vec<(String, u64)> = {
        let arr: Vec<serde_json::Value> = match serde_json::from_str(&notified_json) {
            Ok(v) => v,
            Err(_) => return,
        };
        arr.into_iter()
            .filter_map(|v| {
                let room_id = v.get("roomId")?.as_str()?.to_string();
                let ts = v.get("ts")?.as_u64().unwrap_or(0);
                Some((room_id, ts))
            })
            .collect()
    };
    if entries.is_empty() {
        return;
    }

    let read_rooms = get_read_rooms(client, entries).await;
    if read_rooms.is_empty() {
        return;
    }

    let read_json = match serde_json::to_string(&read_rooms) {
        Ok(s) => s,
        Err(_) => return,
    };

    // Step 3: tell Kotlin to cancel the notifications and clean up SharedPrefs.
    let mut env = match vm.attach_current_thread() {
        Ok(e) => e,
        Err(_) => return,
    };
    let cls = match find_app_class(&mut env, "dev/piaf/app/PushReceiver") {
        Some(c) => c,
        None => return,
    };
    let ctx = app_ctx.as_obj();
    let jstr: jni::objects::JString<'_> = match env.new_string(&read_json) {
        Ok(s) => s,
        Err(_) => return,
    };
    let _ = env.call_static_method(
        &cls,
        "cancelNotificationsForRooms",
        "(Landroid/content/Context;Ljava/lang/String;)V",
        &[(&ctx).into(), (&jstr).into()],
    );
}

pub struct PusherInfo {
    pub device_name: String,
    pub pushkey: String,
    pub app_id: String,
    /// Milliseconds since Unix epoch of the last known activity for this session.
    pub last_seen_ts: Option<u64>,
}

/// List all pushers registered with the homeserver, sorted by last-seen date (newest first).
pub async fn get_registered_pushers(client: &Client) -> Vec<PusherInfo> {
    use matrix_sdk::ruma::api::client::{device::get_devices, push::get_pushers};

    let pushers = client
        .send(get_pushers::v3::Request::new())
        .await
        .map(|r| r.pushers)
        .unwrap_or_default();

    let devices = client
        .send(get_devices::v3::Request::new())
        .await
        .map(|r| r.devices)
        .unwrap_or_default();

    // Map device_id -> last_seen_ts
    let device_ts: std::collections::HashMap<String, u64> = devices
        .into_iter()
        .filter_map(|d| {
            let ts = u64::from(d.last_seen_ts?.get());
            Some((d.device_id.to_string(), ts))
        })
        .collect();

    let mut infos: Vec<PusherInfo> = pushers
        .into_iter()
        .map(|p| {
            // profile_tag holds the device_id when set by the current PIAF version.
            let last_seen_ts = p
                .profile_tag
                .as_deref()
                .and_then(|tag| device_ts.get(tag).copied());
            PusherInfo {
                device_name: p.device_display_name,
                pushkey: p.ids.pushkey,
                app_id: p.ids.app_id,
                last_seen_ts,
            }
        })
        .collect();

    // Most-recently-active first; pushers without a timestamp go last.
    infos.sort_by(|a, b| b.last_seen_ts.cmp(&a.last_seen_ts));
    infos
}
