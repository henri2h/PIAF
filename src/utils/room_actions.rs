//! Room list actions (context menu). Each runs on tokio, logs failures, and
//! wakes the UI; the change itself also comes back through sync.

use matrix_sdk::Room;
use matrix_sdk::latest_events::LatestEventValue;
use matrix_sdk::notification_settings::RoomNotificationMode;
use matrix_sdk::ruma::api::client::receipt::create_receipt::v3::ReceiptType;
use matrix_sdk::ruma::events::receipt::ReceiptThread;

use crate::utils::matrix::get_room;
use crate::utils::room_list::{Pending, update_pending};

#[derive(Clone, Copy, Debug)]
pub enum RoomAction {
    MarkRead,
    MarkUnread,
    Favourite(bool),
    LowPriority(bool),
    Mute(bool),
    Leave,
}

/// Shows the change immediately (pending override), sends it, then drops the
/// override once the server's echo lands; on failure the row reverts.
pub fn run(room_id: String, action: RoomAction) {
    update_pending(&room_id, |p| set_pending(p, action, true));
    tokio::spawn(async move {
        if let Some(room) = get_room(&room_id) {
            match apply(&room, action).await {
                Ok(()) => wait_for_echo(&room, action).await,
                Err(e) => tracing::warn!("room action {action:?} failed for {room_id}: {e}"),
            }
        }
        update_pending(&room_id, |p| set_pending(p, action, false));
    });
}

/// Sets (`on`) or clears this action's field only, so concurrent actions on
/// the same room don't clear each other.
fn set_pending(p: &mut Pending, action: RoomAction, on: bool) {
    match action {
        RoomAction::MarkRead => p.read = on,
        RoomAction::MarkUnread => p.marked_unread = on.then_some(true),
        RoomAction::Favourite(v) => p.favourite = on.then_some(v),
        RoomAction::LowPriority(v) => p.low_priority = on.then_some(v),
        RoomAction::Mute(v) => p.muted = on.then_some(v),
        RoomAction::Leave => p.left = on,
    }
}

/// Tags and the unread flag only change locally when the server's echo comes
/// back through sync, which may not produce a room update; wait for it.
async fn wait_for_echo(room: &Room, action: RoomAction) {
    let applied = || match action {
        RoomAction::MarkRead => {
            !room.is_marked_unread()
                && room.num_unread_notifications() == 0
                && room.num_unread_messages() == 0
        }
        RoomAction::MarkUnread => room.is_marked_unread(),
        RoomAction::Favourite(on) => room.is_favourite() == on,
        RoomAction::LowPriority(on) => room.is_low_priority() == on,
        RoomAction::Mute(on) => {
            (room.cached_user_defined_notification_mode() == Some(RoomNotificationMode::Mute)) == on
        }
        RoomAction::Leave => room.state() != matrix_sdk::RoomState::Joined,
    };
    for _ in 0..50 {
        if applied() {
            return;
        }
        tokio::time::sleep(std::time::Duration::from_millis(100)).await;
    }
    tracing::debug!("room action {action:?}: no echo within 5s");
}

async fn apply(room: &Room, action: RoomAction) -> anyhow::Result<()> {
    match action {
        RoomAction::MarkRead => {
            if let LatestEventValue::Remote(event) = room.latest_event()
                && let Some(event_id) = event.event_id()
            {
                room.send_single_receipt(ReceiptType::Read, ReceiptThread::Unthreaded, event_id)
                    .await?;
            }
            room.set_unread_flag(false).await?;
        }
        RoomAction::MarkUnread => room.set_unread_flag(true).await?,
        RoomAction::Favourite(on) => room.set_is_favourite(on, None).await?,
        RoomAction::LowPriority(on) => room.set_is_low_priority(on, None).await?,
        RoomAction::Mute(on) => {
            let settings = room.client().notification_settings().await;
            if on {
                settings
                    .set_room_notification_mode(room.room_id(), RoomNotificationMode::Mute)
                    .await?;
            } else {
                settings
                    .delete_user_defined_room_rules(room.room_id())
                    .await?;
            }
        }
        RoomAction::Leave => room.leave().await?,
    }
    Ok(())
}
