use std::sync::LazyLock;
use std::sync::atomic::Ordering;

use tokio::sync::watch;

use freya_router::prelude::RouterContext;

use super::Route;
use super::state::{ACTIVE_ROOM_TX, FOCUS_EVENT_TX, WIDE_MODE};
use crate::utils::haptics::{self, Haptic};

/// Pushes `route` for a user tap, with haptic feedback. Programmatic
/// redirects (session restore, after leaving a room…) push directly.
pub fn push(route: Route) {
    haptics::play(Haptic::Click);
    let _ = RouterContext::get().push(route);
}

/// Opens a room after a tap (with the navigation haptic).
pub fn navigate_to_room(room_id: String) {
    haptics::play(Haptic::Click);
    open_room(room_id);
}

/// Opens a room. Wide mode also updates the right panel via `ACTIVE_ROOM_TX`.
fn open_room(room_id: String) {
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
    haptics::play(Haptic::Click);
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
    push(Route::PendingDm { user_id });
}

/// Rooms asked to open from outside the UI (a tapped notification). A
/// `LazyLock`, not an `app::state` singleton: Android can deliver the tap
/// before `init` runs.
static OPEN_ROOM_REQUEST: LazyLock<watch::Sender<Option<String>>> =
    LazyLock::new(|| watch::Sender::new(None));

/// Asks the UI to open `room_id` as soon as it can (see [`use_open_room_requests`]).
#[cfg_attr(not(target_os = "android"), allow(dead_code))]
pub fn request_open_room(room_id: String) {
    OPEN_ROOM_REQUEST.send_replace(Some(room_id));
}

/// Opens requested rooms once the app is past the welcome / login pages
/// (opening earlier would be pushed under the home page by the session restore).
#[cfg_attr(not(target_os = "android"), allow(dead_code))]
pub fn use_open_room_requests(ready: bool) {
    use freya::prelude::*;

    let requested = crate::utils::use_watch(&OPEN_ROOM_REQUEST.subscribe());
    let room_id = requested.read().clone();
    use_side_effect_with_deps(&(room_id, ready), |(room_id, ready)| {
        if let (Some(room_id), true) = (room_id, *ready) {
            OPEN_ROOM_REQUEST.send_replace(None);
            open_room(room_id.clone());
        }
    });
}
