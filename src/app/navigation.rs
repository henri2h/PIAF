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
