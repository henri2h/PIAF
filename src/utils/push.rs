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

use matrix_sdk::ruma::exports::serde_json;
use matrix_sdk::{
    Client,
    ruma::{
        EventId, RoomId,
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
                // Never log the endpoint: anyone holding it can push to this device.
                tracing::info!("Registering persisted UP pusher");
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
    tracing::info!("Registering UP pusher: gateway={gw}");

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

    // `append: false` (the spec default): replaces a pusher with the same push key.
    match client.pusher().set(pusher.into(), false).await {
        Ok(_) => tracing::info!("UP pusher registered successfully"),
        Err(e) => tracing::warn!("failed to register UP pusher: {e}"),
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
        tracing::warn!("failed to delete UP pusher: {e}");
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
    pub is_dm: bool,
    pub sender_id: String,
    pub sender_display_name: String,
    pub body: String,
    pub is_image: bool,
}

/// What a push for an event should show.
pub enum NotifOutcome {
    Show(NotifPayload),
    /// Nothing to show: not a message (reaction, state…), an edit, or redacted.
    Skip,
    /// The event or room couldn't be loaded; the caller falls back to a
    /// generic notification.
    Unavailable,
}

impl NotifPayload {
    /// JSON handed to the Kotlin `PushReceiver`.
    pub fn to_json(&self, room_id: &str) -> serde_json::Value {
        let hex = |id: &str| {
            let (r, g, b) = crate::utils::id_color(id);
            format!("#{r:02x}{g:02x}{b:02x}")
        };
        serde_json::json!({
            "roomName": self.room_name,
            "isDm": self.is_dm,
            "roomColor": hex(room_id),
            "senderId": self.sender_id,
            "senderName": self.sender_display_name,
            "senderColor": hex(&self.sender_id),
            "body": self.body,
            "isImage": self.is_image,
        })
    }
}

/// Builds the notification content for a pushed room + event.
pub async fn fetch_notification_payload(
    client: &Client,
    room_id_str: &str,
    event_id_str: &str,
) -> NotifOutcome {
    use matrix_sdk::ruma::events::room::message::Relation;

    let (Ok(room_id), Ok(event_id)) = (RoomId::parse(room_id_str), EventId::parse(event_id_str))
    else {
        return NotifOutcome::Skip;
    };
    let Some(room) = client.get_room(&room_id) else {
        return NotifOutcome::Unavailable;
    };
    let Ok(timeline_event) = room.event(&event_id, None).await else {
        return NotifOutcome::Unavailable;
    };
    let Ok(event) = timeline_event.kind.raw().deserialize() else {
        return NotifOutcome::Unavailable;
    };

    let AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
        SyncMessageLikeEvent::Original(msg),
    )) = event
    else {
        return NotifOutcome::Skip;
    };
    // An edit re-sends the whole message: the original was already notified.
    if matches!(msg.content.relates_to, Some(Relation::Replacement(_))) {
        return NotifOutcome::Skip;
    }
    let Some(body) = crate::utils::room_preview::message_body(&msg.content.msgtype) else {
        return NotifOutcome::Skip;
    };
    // Pushes can arrive late: skip what was already read (on any device).
    if already_read(client, &room, &event_id, msg.origin_server_ts).await {
        return NotifOutcome::Skip;
    }

    let room_name = room
        .display_name()
        .await
        .map(|n| n.to_string())
        .unwrap_or_else(|_| "PIAF".to_string());
    let sender_display_name = room
        .get_member_no_sync(&msg.sender)
        .await
        .ok()
        .flatten()
        .and_then(|m| m.display_name().map(|s| s.to_string()))
        .unwrap_or_else(|| msg.sender.localpart().to_string());

    NotifOutcome::Show(NotifPayload {
        room_name,
        is_dm: room.is_direct().await.unwrap_or(false),
        sender_id: msg.sender.to_string(),
        sender_display_name,
        body,
        is_image: matches!(msg.content.msgtype, MessageType::Image(_)),
    })
}

/// Whether the user's read receipt (public or private) covers `event_id`: on
/// it, or set after it was sent.
async fn already_read(
    client: &Client,
    room: &matrix_sdk::Room,
    event_id: &EventId,
    sent: matrix_sdk::ruma::MilliSecondsSinceUnixEpoch,
) -> bool {
    use matrix_sdk::ruma::events::receipt::{ReceiptThread, ReceiptType};

    let Some(user_id) = client.user_id() else {
        return false;
    };
    for receipt_type in [ReceiptType::Read, ReceiptType::ReadPrivate] {
        let receipt = room
            .load_user_receipt(receipt_type, &ReceiptThread::Unthreaded, user_id)
            .await
            .ok()
            .flatten();
        if let Some((receipt_event_id, receipt)) = receipt
            && (receipt_event_id == event_id || receipt.ts.is_some_and(|ts| ts >= sent))
        {
            return true;
        }
    }
    false
}

/// Sends a plain text message (a notification's quick reply).
pub async fn send_text(client: &Client, room_id: &str, body: &str) -> bool {
    use matrix_sdk::ruma::events::room::message::RoomMessageEventContent;

    let Some(room) = RoomId::parse(room_id)
        .ok()
        .and_then(|id| client.get_room(&id))
    else {
        return false;
    };
    match room.send(RoomMessageEventContent::text_plain(body)).await {
        Ok(_) => true,
        Err(e) => {
            tracing::warn!("notification reply failed: {e}");
            false
        }
    }
}

/// Marks the room read up to `event_id` (a notification's "Mark as read").
pub async fn mark_read(client: &Client, room_id: &str, event_id: &str) -> bool {
    use matrix_sdk::room::Receipts;

    let (Some(room), Ok(event_id)) = (
        RoomId::parse(room_id)
            .ok()
            .and_then(|id| client.get_room(&id)),
        EventId::parse(event_id),
    ) else {
        return false;
    };
    let receipts = Receipts::new()
        .fully_read_marker(event_id.clone())
        .public_read_receipt(event_id);
    let sent = room.send_multiple_receipts(receipts).await;
    let _ = room.set_unread_flag(false).await;
    if let Err(e) = &sent {
        tracing::warn!("notification mark as read failed: {e}");
    }
    sent.is_ok()
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
            .load_user_receipt(ReceiptType::Read, &ReceiptThread::Unthreaded, &user_id)
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
pub(crate) fn find_app_class<'a>(
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
    cancel_read_notifications(client).await;
}

#[cfg(target_os = "android")]
async fn cancel_read_notifications(client: &Client) -> Option<()> {
    // Step 1: ask Kotlin for the notified rooms: [{roomId, ts}].
    let notified_json: String = with_push_receiver(|env, cls, ctx| {
        let obj = env
            .call_static_method(
                cls,
                "getNotifiedRoomsJson",
                "(Landroid/content/Context;)Ljava/lang/String;",
                &[ctx.into()],
            )
            .and_then(|v| v.l())
            .ok()
            .filter(|obj| !obj.is_null())?;
        env.get_string(&jni::objects::JString::from(obj))
            .ok()
            .map(String::from)
    })?;

    // Step 2: which of them were read since — pure Rust, no JNI.
    let arr: Vec<serde_json::Value> = serde_json::from_str(&notified_json).ok()?;
    let entries: Vec<(String, u64)> = arr
        .into_iter()
        .filter_map(|v| {
            let room_id = v.get("roomId")?.as_str()?.to_string();
            let ts = v.get("ts")?.as_u64().unwrap_or(0);
            Some((room_id, ts))
        })
        .collect();
    if entries.is_empty() {
        return None;
    }
    let read_rooms = get_read_rooms(client, entries).await;
    if read_rooms.is_empty() {
        return None;
    }
    let read_json = serde_json::to_string(&read_rooms).ok()?;

    // Step 3: Kotlin cancels their notifications and cleans up SharedPrefs.
    with_push_receiver(|env, cls, ctx| {
        let jstr = env.new_string(&read_json).ok()?;
        env.call_static_method(
            cls,
            "cancelNotificationsForRooms",
            "(Landroid/content/Context;Ljava/lang/String;)V",
            &[ctx.into(), (&jstr).into()],
        )
        .ok()
        .map(|_| ())
    })
}

/// Runs `f` on this thread attached to the JVM, with Kotlin's `PushReceiver`
/// class and the app context.
#[cfg(target_os = "android")]
fn with_push_receiver<T>(
    f: impl FnOnce(&mut jni::JNIEnv, &jni::objects::JClass, &jni::objects::JObject) -> Option<T>,
) -> Option<T> {
    let vm = JAVA_VM.get()?;
    let ctx = ANDROID_APP_CONTEXT.get()?;
    let mut env = vm.attach_current_thread().ok()?;
    let cls = find_app_class(&mut env, "dev/piaf/app/PushReceiver")?;
    f(&mut env, &cls, ctx.as_obj())
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
