use std::cell::{Cell, RefCell};
use std::rc::Rc;
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

thread_local! {
    /// Overlays that take the system back gesture before the router
    /// (innermost last): an open media viewer closes instead of the page.
    static BACK_HANDLERS: RefCell<Vec<(u64, Rc<dyn Fn() -> bool>)>> = const { RefCell::new(Vec::new()) };
    static NEXT_BACK_HANDLER: Cell<u64> = const { Cell::new(0) };
}

/// While the component is mounted, the back gesture first runs `handler`;
/// it returns whether it handled it (else the router goes back).
pub fn use_back_handler(handler: impl Fn() -> bool + 'static) {
    let id = freya::prelude::use_hook(|| {
        let id = NEXT_BACK_HANDLER.replace(NEXT_BACK_HANDLER.get() + 1);
        let handler: Rc<dyn Fn() -> bool> = Rc::new(handler);
        BACK_HANDLERS.with(|h| h.borrow_mut().push((id, handler)));
        id
    });
    freya::prelude::use_drop(move || {
        BACK_HANDLERS.with(|h| h.borrow_mut().retain(|(i, _)| *i != id));
    });
}

/// Gives the back gesture to the innermost overlay that takes it.
pub fn handle_back() -> bool {
    let handlers: Vec<_> =
        BACK_HANDLERS.with(|h| h.borrow().iter().map(|(_, f)| f.clone()).collect());
    handlers.iter().rev().any(|f| f())
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
static OPEN_ROOM_REQUEST: LazyLock<watch::Sender<Option<OpenRoom>>> =
    LazyLock::new(|| watch::Sender::new(None));

#[derive(Clone, PartialEq)]
struct OpenRoom {
    /// The account the room is in; `None`: the active one.
    account: Option<String>,
    room_id: String,
}

/// Asks the UI to open `room_id` as soon as it can (see [`use_open_room_requests`]).
#[cfg_attr(not(target_os = "android"), allow(dead_code))]
pub fn request_open_room(account: Option<String>, room_id: String) {
    OPEN_ROOM_REQUEST.send_replace(Some(OpenRoom { account, room_id }));
}

/// Opens requested rooms once the app is past the welcome / login pages
/// (opening earlier would be pushed under the home page by the session
/// restore). A room of another account restarts the app into it.
#[cfg_attr(not(target_os = "android"), allow(dead_code))]
pub fn use_open_room_requests(ready: bool) {
    use freya::prelude::*;

    let requested = crate::utils::use_watch(&OPEN_ROOM_REQUEST.subscribe());
    let request = requested.read().clone();
    use_side_effect_with_deps(&(request, ready), |(request, ready)| {
        let (Some(request), true) = (request, *ready) else {
            return;
        };
        OPEN_ROOM_REQUEST.send_replace(None);
        let active = crate::utils::matrix::ACCOUNT.get().map(|(id, _)| id);
        match &request.account {
            Some(account) if active != Some(account) => {
                // Signed out of it since: nothing to open.
                let usable = crate::utils::accounts::registry()
                    .get(account)
                    .is_some_and(|a| !a.expired);
                if usable {
                    crate::utils::accounts::switch_to(account, Some(&request.room_id))
                }
            }
            _ => open_room(request.room_id.clone()),
        }
    });
}
