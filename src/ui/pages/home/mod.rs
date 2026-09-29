mod app_bar;
mod filter_bar;
mod filter_chip;
mod room_list;
pub mod room_list_item;
mod room_list_model;
mod room_menu;
mod row_interaction;
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

use crate::logging::RenderTimer;
use crate::utils::const_values::AppColors;
use crate::utils::{use_app_colors, use_watch, use_watch_tick};
use crate::{ACTIVE_ROOM_RX, WIDE_MODE};

// ---------------------------------------------------------------------------
// Shared context for the currently active room ID
// ---------------------------------------------------------------------------

/// Provided by HomePage; consumed by RoomListItem to highlight the active room.
#[derive(Clone, Copy)]
pub struct ActiveRoomCtx(pub State<Option<String>>);

/// Mirrors ACTIVE_ROOM_RX as context so rows re-render in place (highlight)
/// without remounting VirtualScrollView, which would reset scroll position.
fn provide_active_room_context() {
    let active_room = use_watch(ACTIVE_ROOM_RX.get().expect("not initialized"));
    use_provide_context(|| ActiveRoomCtx(active_room));
}

// ---------------------------------------------------------------------------
// HomePage
// ---------------------------------------------------------------------------

#[derive(PartialEq)]
pub struct HomePage {}

impl Component for HomePage {
    fn render(&self) -> impl IntoElement {
        let _timer = RenderTimer::new("HomePage");
        let c = use_app_colors();
        provide_active_room_context();

        let search: State<String> = use_state(String::new);
        let search_open: State<bool> = use_state(|| false);
        let filter: State<RoomFilter> = use_state(|| RoomFilter::All);
        // Shown by default; scrolling down hides them, scrolling up brings them back.
        let chips_visible: State<bool> = use_state(|| true);

        // Re-render on sync ticks so the session-expired banner appears.
        let _sync = use_watch_tick(crate::SYNC_RX.get().expect("not initialized"));

        let is_wide = WIDE_MODE.load(Ordering::Relaxed);
        let search_active = !search.read().trim().is_empty();
        let show_filters = !search_active && (*chips_visible.read() || is_wide);
        let session_expired = crate::SESSION_EXPIRED.load(Ordering::Relaxed);

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(HomeAppBar {
                search,
                search_open,
            })
            .child(if session_expired {
                session_expired_banner(c)
            } else {
                rect().into_element()
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
                }
                .into_element()
            })
    }
}

/// Shown once the server revokes our token; sync has stopped. The session file
/// is already set aside, so a restart lands on the login page.
fn session_expired_banner(c: AppColors) -> Element {
    rect()
        .horizontal()
        .content(Content::Flex)
        .width(Size::fill())
        .padding(Gaps::new(8., 8., 8., 16.))
        .spacing(12.)
        .cross_align(Alignment::Center)
        .background(c.error)
        .child(
            label()
                .width(Size::flex(1.))
                .text("Session expired: this device was signed out.")
                .font_size(13.)
                .color(c.on_primary),
        )
        .child(
            rect()
                .padding(Gaps::new(8., 14., 8., 14.))
                .corner_radius(16.)
                .background(c.on_primary)
                .on_press(|_| crate::app::restart::restart())
                .child(
                    label()
                        .text("Sign in again")
                        .font_size(13.)
                        .font_weight(FontWeight::MEDIUM)
                        .color(c.error),
                ),
        )
        .into()
}
