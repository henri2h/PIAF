mod app_bar;
mod filter_bar;
mod filter_chip;
mod room_list;
pub mod room_list_item;
pub mod search;
mod search_panel;
mod search_tile;

use std::sync::atomic::Ordering;

use app_bar::HomeAppBar;
use filter_bar::RoomFilterBar;
use filter_chip::RoomFilter;
use freya::prelude::*;
use freya_router::prelude::RouterContext;
use room_list::RoomList;
use search_panel::SearchResults;

use crate::utils::{use_app_colors, use_tokio_track_watcher};
use crate::{ACTIVE_ROOM_RX, ACTIVE_ROOM_TX, Route, WIDE_MODE};

// ---------------------------------------------------------------------------
// Shared helpers used by submodules
// ---------------------------------------------------------------------------

/// Navigate to a room: in wide mode sends to ACTIVE_ROOM_TX, always pushes the route.
pub(crate) fn navigate_to_room(room_id: String) {
    if WIDE_MODE.load(Ordering::Relaxed) {
        if let Some(tx) = ACTIVE_ROOM_TX.get() {
            let _ = tx.send(Some(room_id.clone()));
        }
    }
    let _ = RouterContext::get().push(Route::RoomPage { room_id });
}

/// Primary key for room sorting: latest-event timestamp (client-side, always
/// accurate), with recency_stamp (server-side sliding-sync bump) as fallback.
fn room_sort_key(r: &matrix_sdk::Room) -> u64 {
    r.latest_event()
        .timestamp()
        .map(|ts| ts.get().into())
        .or_else(|| r.recency_stamp().map(u64::from))
        .unwrap_or(0)
}

/// Sort a room slice in-place by descending recency.
fn sort_rooms_by_recency(rooms: &mut Vec<matrix_sdk::Room>) {
    rooms.sort_unstable_by(|a, b| room_sort_key(b).cmp(&room_sort_key(a)));
}

// ---------------------------------------------------------------------------
// Shared context for the currently active room ID
// ---------------------------------------------------------------------------

/// Provided by HomePage; consumed by RoomListItem to highlight the active room.
#[derive(Clone, Copy)]
pub struct ActiveRoomCtx(pub State<Option<String>>);

/// Mirrors ACTIVE_ROOM_RX into reactive state and provides it as context, so
/// RoomListItem re-renders in-place (highlighting the active room) without
/// remounting VirtualScrollView, which would reset scroll position.
fn provide_active_room_context() {
    let active_room: State<Option<String>> =
        use_state(|| ACTIVE_ROOM_RX.get().and_then(|rx| rx.borrow().clone()));
    use_hook(|| {
        let mut active_room = active_room;
        if let Some(rx) = ACTIVE_ROOM_RX.get() {
            let (tx, mut chan) = futures::channel::mpsc::unbounded::<Option<String>>();
            let mut rx = rx.clone();
            tokio::task::spawn(async move {
                while rx.changed().await.is_ok() {
                    let val = rx.borrow().clone();
                    if tx.unbounded_send(val).is_err() {
                        break;
                    }
                }
            });
            spawn(async move {
                use futures::StreamExt;
                while let Some(val) = chan.next().await {
                    *active_room.write() = val;
                }
            });
        }
    });
    use_provide_context(|| ActiveRoomCtx(active_room));
}

// ---------------------------------------------------------------------------
// HomePage
// ---------------------------------------------------------------------------

#[derive(PartialEq)]
pub struct HomePage {}

impl Component for HomePage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        provide_active_room_context();

        let search: State<String> = use_state(String::new);
        let search_open: State<bool> = use_state(|| false);
        let filter: State<RoomFilter> = use_state(|| RoomFilter::All);
        let chips_visible: State<bool> = use_state(|| false);

        // Re-render on every sync tick so room ordering stays current.
        let sync_tick: State<u64> = use_state(|| 0u64);
        use_tokio_track_watcher(
            crate::SYNC_RX.get().expect("SYNC_RX not initialized"),
            sync_tick,
        );

        let is_wide = WIDE_MODE.load(Ordering::Relaxed);
        let search_active = !search.read().trim().is_empty();
        let show_filters = !search_active && (*chips_visible.read() || is_wide);
        let sync_tick_val = *sync_tick.read();

        eprintln!(
            "[piaf] HomePage::render is_wide={is_wide} search_active={search_active} show_filters={show_filters} sync_tick={sync_tick_val}"
        );

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(HomeAppBar { search, search_open })
            .child(if show_filters {
                RoomFilterBar { filter }.into_element()
            } else {
                rect().into_element()
            })
            .child(if search_active {
                SearchResults { search }.into_element()
            } else {
                RoomList {
                    filter: filter.read().clone(),
                    chips_visible,
                    sync_tick: sync_tick_val,
                }
                .into_element()
            })
    }
}
