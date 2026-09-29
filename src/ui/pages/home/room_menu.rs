use freya::prelude::*;

use crate::utils::room_actions::{RoomAction, run};
use crate::utils::room_list::RoomSummary;

/// Right-click (desktop) / long-press (Android) menu for a room row.
pub(super) fn open_room_menu(s: &RoomSummary, from_pointer_down: bool) {
    let menu = room_menu(s);
    if from_pointer_down {
        ContextMenu::open_from_down(menu);
    } else {
        ContextMenu::open(menu);
    }
}

fn room_menu(s: &RoomSummary) -> Menu {
    if s.is_invite {
        return Menu::new().child(
            SubMenu::new()
                .label("Decline invite")
                .child(leave_item(&s.room_id, "Decline")),
        );
    }
    let id = &s.room_id;
    Menu::new()
        .child(if s.is_unread() {
            item(id, "Mark as read", RoomAction::MarkRead)
        } else {
            item(id, "Mark as unread", RoomAction::MarkUnread)
        })
        .child(if s.is_favourite {
            item(id, "Remove from favourites", RoomAction::Favourite(false))
        } else {
            item(id, "Add to favourites", RoomAction::Favourite(true))
        })
        .child(if s.is_low_priority {
            item(
                id,
                "Remove from low priority",
                RoomAction::LowPriority(false),
            )
        } else {
            item(id, "Move to low priority", RoomAction::LowPriority(true))
        })
        .child(if s.is_muted {
            item(id, "Unmute", RoomAction::Mute(false))
        } else {
            item(id, "Mute", RoomAction::Mute(true))
        })
        .child({
            let room_id = id.clone();
            MenuButton::new()
                .on_press(move |_| {
                    let room_id = room_id.clone();
                    tokio::spawn(async move {
                        crate::utils::room_mailbox::archive_room(&room_id).await;
                    });
                    ContextMenu::close();
                })
                .child("Archive")
        })
        .child(
            SubMenu::new()
                .label("Leave room")
                .child(leave_item(id, "Leave")),
        )
}

fn item(room_id: &str, text: &'static str, action: RoomAction) -> MenuButton {
    let room_id = room_id.to_string();
    MenuButton::new()
        .on_press(move |_| {
            run(room_id.clone(), action);
            ContextMenu::close();
        })
        .child(text)
}

/// Confirmation step for leaving; also closes the room if it's open.
fn leave_item(room_id: &str, text: &'static str) -> MenuButton {
    let room_id = room_id.to_string();
    MenuButton::new()
        .on_press(move |_| {
            run(room_id.clone(), RoomAction::Leave);
            let active = crate::ACTIVE_ROOM_RX
                .get()
                .expect("not initialized")
                .borrow()
                .clone();
            if active.as_deref() == Some(room_id.as_str()) {
                crate::app::navigation::close_room();
            }
            ContextMenu::close();
        })
        .child(text)
}
