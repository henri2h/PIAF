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

use crate::ui::components::HoverableExt;
use room_list::RoomList;
use room_list_model::{Mailbox, RoomFilter};
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
        let mailbox: State<Mailbox> = use_state(|| Mailbox::Inbox);
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
                RoomFilterBar { mailbox, filter }.into_element()
            } else {
                rect().into_element()
            })
            .child(if search_active {
                SearchResults { search }.into_element()
            } else {
                RoomList {
                    mailbox: *mailbox.read(),
                    filter: filter.read().clone(),
                    chips_visible,
                }
                .into_element()
            })
            .maybe_child((!search_active).then(|| new_chat_fab(c)))
    }
}

/// Material floating action button, bottom right: start a new chat.
fn new_chat_fab(c: AppColors) -> Element {
    rect()
        .position(Position::new_absolute().bottom(16.).right(16.))
        // Layers grow by one per nesting level, so the list rows sit far above
        // `layer(1)`. Jump well past them, but stay below overlays (popups, menus).
        .layer(1000)
        .corner_radius(16.)
        .shadow(Shadow::new().y(3.).blur(8.).color((0, 0, 0, 60)))
        .child(
            TooltipContainer::new(Tooltip::new_text("New chat"))
                .position(AttachedPosition::Top)
                .child(
                    rect()
                        .center()
                        .width(Size::px(56.))
                        .height(Size::px(56.))
                        .corner_radius(16.)
                        .background(c.primary)
                        // Solid nodes only block hover for events they listen to: without
                        // this, room rows (`on_pointer_over`) underneath light up too.
                        .on_pointer_over(|_| {})
                        .on_press(|_| {
                            let _ = freya_router::prelude::RouterContext::get()
                                .push(crate::Route::NewChat);
                        })
                        .child(
                            SvgViewer::new(freya_icons::lucide::pencil())
                                .color(c.on_primary)
                                .width(Size::px(24.))
                                .height(Size::px(24.)),
                        )
                        .hoverable(Size::px(56.), Size::px(56.), 16.),
                ),
        )
        .into_element()
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
                )
                .hoverable(Size::auto(), Size::auto(), 16.),
        )
        .into()
}
