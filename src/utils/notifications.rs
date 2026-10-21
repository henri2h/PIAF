//! Desktop notifications for new messages (desktop only; Android uses push).

use std::sync::OnceLock;
use std::sync::atomic::{AtomicU64, Ordering};

use matrix_sdk::event_handler::RawEvent;
use matrix_sdk::ruma::events::room::message::{MessageType, Relation, RoomMessageEventContent};
use matrix_sdk::ruma::events::{AnySyncTimelineEvent, OriginalSyncMessageLikeEvent};
use matrix_sdk::ruma::serde::Raw;
use matrix_sdk::{Client, Room};

use crate::utils::avatars::AvatarSource;
use crate::utils::room_preview::message_body;

static NOTIFICATION_HANDLER_GUARD: OnceLock<()> = OnceLock::new();

/// Events older than this are catch-up, not something to notify about.
const NOTIFY_MAX_AGE_MS: u64 = 5 * 60 * 1000;
/// When this client session started (ms since epoch); older events never notify.
static NOTIFY_SINCE_MS: AtomicU64 = AtomicU64::new(0);

fn now_ms() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

/// Desktop notification gate: only messages sent since this session started,
/// still fresh, and only while the window is in the background.
fn should_notify(event_ts_ms: u64, now_ms: u64, since_ms: u64, app_focused: bool) -> bool {
    !app_focused
        && event_ts_ms >= since_ms
        && now_ms.saturating_sub(event_ts_ms) <= NOTIFY_MAX_AGE_MS
}

/// Registers the message handler once per process; notifications start from now.
pub fn register(client: &Client) {
    if NOTIFICATION_HANDLER_GUARD.set(()).is_err() {
        return;
    }
    NOTIFY_SINCE_MS.store(now_ms(), Ordering::Relaxed);
    client.add_event_handler(
        |ev: OriginalSyncMessageLikeEvent<RoomMessageEventContent>,
         room: Room,
         client: Client,
         raw: RawEvent| async move {
            send_desktop_notification(ev, raw, room, client).await;
        },
    );
}

/// Whether the account's push rules (room mode, mentions, keywords) ask to
/// notify for this event. Notifies when the rules can't be evaluated.
async fn push_rules_notify(room: &Room, raw: RawEvent) -> bool {
    let raw: Raw<AnySyncTimelineEvent> = Raw::from_json(raw.0);
    match room.event_push_actions(&raw).await {
        Ok(Some(actions)) => actions.iter().any(|action| action.should_notify()),
        _ => true,
    }
}

/// The room's avatar as shown in the app (for a DM, the other user), written
/// to a file for the notification server. `None` when it has none.
async fn icon_path(room: &Room) -> Option<std::path::PathBuf> {
    let source = AvatarSource::Room(room.room_id().to_string());
    let bytes = crate::utils::avatars::fetch(&source).await?;
    let dir = std::env::temp_dir().join("piaf-notification-icons");
    tokio::fs::create_dir_all(&dir).await.ok()?;
    let hash = room
        .room_id()
        .as_str()
        .bytes()
        .fold(0u64, |acc, b| acc.wrapping_mul(31).wrapping_add(b as u64));
    let path = dir.join(format!("{hash:x}"));
    tokio::fs::write(&path, bytes).await.ok()?;
    Some(path)
}

async fn send_desktop_notification(
    ev: OriginalSyncMessageLikeEvent<RoomMessageEventContent>,
    raw: RawEvent,
    room: Room,
    client: Client,
) {
    let event_ts_ms: u64 = ev.origin_server_ts.0.into();
    if !should_notify(
        event_ts_ms,
        now_ms(),
        NOTIFY_SINCE_MS.load(Ordering::Relaxed),
        crate::APP_FOCUSED.load(Ordering::Relaxed),
    ) {
        return;
    }
    if client.user_id() == Some(&*ev.sender) {
        return;
    }
    // An edit re-sends the message: the original was already notified.
    if matches!(ev.content.relates_to, Some(Relation::Replacement(_))) {
        return;
    }
    if !push_rules_notify(&room, raw).await {
        return;
    }

    let room_name = room
        .cached_display_name()
        .map(|n| n.to_string())
        .unwrap_or_else(|| room.room_id().to_string());
    let sender_name = room
        .get_member_no_sync(&ev.sender)
        .await
        .ok()
        .flatten()
        .and_then(|m| m.display_name().map(|s| s.to_string()))
        .unwrap_or_else(|| ev.sender.localpart().to_string());

    let body = match &ev.content.msgtype {
        MessageType::Emote(e) => format!("* {} {}", sender_name, e.body),
        other => message_body(other).unwrap_or_else(|| "New message".to_string()),
    };
    let summary = if room.is_direct().await.unwrap_or(false) {
        sender_name
    } else {
        format!("{sender_name} · {room_name}")
    };
    let icon = icon_path(&room).await;

    let mut notification = notify_rust::Notification::new();
    notification
        .appname("Piaf")
        .summary(&summary)
        .body(&body)
        .icon(
            icon.as_deref()
                .and_then(|path| path.to_str())
                .unwrap_or("dialog-information"),
        )
        .timeout(notify_rust::Timeout::Milliseconds(5000));
    if let Err(e) = notification.show() {
        tracing::debug!("desktop notification failed: {e}");
    }
}

#[cfg(test)]
mod tests {
    use super::{NOTIFY_MAX_AGE_MS, should_notify};

    const SINCE: u64 = 1_000_000;

    #[test]
    fn notifies_fresh_message_in_background() {
        assert!(should_notify(SINCE + 10, SINCE + 20, SINCE, false));
    }

    #[test]
    fn never_while_focused() {
        assert!(!should_notify(SINCE + 10, SINCE + 20, SINCE, true));
    }

    #[test]
    fn skips_history_from_before_session() {
        assert!(!should_notify(SINCE - 1, SINCE + 20, SINCE, false));
    }

    #[test]
    fn skips_stale_catch_up() {
        let ts = SINCE + 10;
        assert!(!should_notify(ts, ts + NOTIFY_MAX_AGE_MS + 1, SINCE, false));
        assert!(should_notify(ts, ts + NOTIFY_MAX_AGE_MS, SINCE, false));
    }

    #[test]
    fn server_clock_ahead_is_fresh() {
        assert!(should_notify(SINCE + 5_000, SINCE + 10, SINCE, false));
    }
}
