use std::sync::atomic::Ordering;

use freya_router::prelude::RouterContext;

use super::Route;
use super::state::{ACTIVE_ROOM_TX, FOCUS_EVENT_TX, WIDE_MODE};

/// Opens a room. Wide mode also updates the right panel via `ACTIVE_ROOM_TX`.
pub fn navigate_to_room(room_id: String) {
    if WIDE_MODE.load(Ordering::Relaxed) {
        let _ = ACTIVE_ROOM_TX
            .get()
            .expect("not initialized")
            .send(Some(room_id.clone()));
    }
    let _ = RouterContext::get().push(Route::RoomPage { room_id });
}

/// Opens a room scrolled to `event_id`.
pub fn navigate_to_room_at_event(room_id: String, event_id: String) {
    let _ = FOCUS_EVENT_TX
        .get()
        .expect("not initialized")
        .send(Some((room_id.clone(), event_id)));
    navigate_to_room(room_id);
}

/// Leaves the current room view (e.g. after declining an invite): clears the
/// wide-mode panel and returns to the room list.
pub fn close_room() {
    let _ = ACTIVE_ROOM_TX.get().expect("not initialized").send(None);
    let _ = RouterContext::get().replace(Route::HomePage);
}

/// Back to the previous route, or the room list when there is none.
pub fn go_back_or_home() {
    let router = RouterContext::get();
    if router.can_go_back() {
        router.go_back();
    } else {
        let _ = router.push(Route::HomePage);
    }
}

/// Opens the DM with `user`: the existing room, or the pending-DM page that
/// creates the room with the first message (so a stray tap leaves no empty room).
pub fn open_dm(user: crate::utils::users::UserInfo) {
    let existing = crate::utils::matrix::CLIENT.get().and_then(|client| {
        let user_id = matrix_sdk::ruma::UserId::parse(&user.user_id).ok()?;
        client.get_dm_room(&user_id)
    });
    if let Some(room) = existing {
        navigate_to_room(room.room_id().to_string());
        return;
    }
    let user_id = user.user_id.clone();
    if let Ok(mut pending) = crate::ui::pages::new_chat::draft::PENDING_DM.lock() {
        *pending = Some(user);
    }
    let _ = RouterContext::get().push(Route::PendingDm { user_id });
}
