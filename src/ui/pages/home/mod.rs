mod app_bar;
mod filter_bar;
mod filter_chip;
mod room_list;
pub mod room_list_item;
mod room_list_model;
#[cfg(not(target_os = "android"))]
mod room_row_actions;
#[cfg(target_os = "android")]
mod room_swipe;
pub mod search;
mod search_panel;
mod search_tile;

use std::sync::atomic::Ordering;

use app_bar::HomeAppBar;
use filter_bar::RoomFilterBar;
use freya::prelude::*;
use room_list::RoomList;
use room_list_model::RoomFilter;
use search_panel::SearchResults;

use crate::utils::{use_app_colors, use_tokio_track_watcher};
use crate::{ACTIVE_ROOM_RX, WIDE_MODE};

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

        // Re-render whenever a room's recontact/archived state changes.
        let mailbox_tick: State<u64> = use_state(|| 0u64);
        use_tokio_track_watcher(
            crate::ROOM_MAILBOX_RX
                .get()
                .expect("ROOM_MAILBOX_RX not initialized"),
            mailbox_tick,
        );

        let is_wide = WIDE_MODE.load(Ordering::Relaxed);
        let search_active = !search.read().trim().is_empty();
        let show_filters = !search_active && (*chips_visible.read() || is_wide);
        let sync_tick_val = *sync_tick.read();
        let mailbox_tick_val = *mailbox_tick.read();

        eprintln!(
            "[piaf] HomePage::render is_wide={is_wide} search_active={search_active} show_filters={show_filters} sync_tick={sync_tick_val}"
        );

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(HomeAppBar {
                search,
                search_open,
            })
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
                    mailbox_tick: mailbox_tick_val,
                }
                .into_element()
            })
    }
}
