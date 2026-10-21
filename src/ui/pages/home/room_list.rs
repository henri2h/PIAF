use std::cell::RefCell;
use std::rc::Rc;

use freya::prelude::*;

use super::filter_bar::FILTER_BAR_HEIGHT;
use super::room_list_item::{ROOM_ROW_HEIGHT, RoomListItem};
use super::room_menu::{RoomSheet, room_sheet};
use super::room_list_model::{Mailbox, RoomFilter, visible_rooms};
use crate::{ROOM_MAILBOX_RX, WIDE_MODE};
use crate::app::keys::{Area, KeyCommand, KeyNav, use_key_commands};
use crate::app::navigation::navigate_to_room;
use crate::logging::RenderTimer;
use crate::ui::components::{empty_state, loading_state};
use crate::utils::const_values::AppColors;
use crate::utils::room_actions::{RoomAction, run};
use crate::utils::room_list;
use crate::utils::room_list::RoomSummary;
use crate::utils::{use_app_colors, use_watch, use_watch_tick};

/// The filter bar overlaid on the list, which slides out as it scrolls.
#[derive(Clone, Copy, PartialEq)]
pub struct FilterBarScroll {
    /// Pixels of the bar slid out of view.
    pub hidden: State<f32>,
    /// Whether the bar is mostly in view.
    pub visible: State<bool>,
    /// Whether the list is scrolled away from the top (the bars above tint).
    pub scrolled: State<bool>,
}

/// Shared with the rows: the list's scroll (a resting finger is no long
/// press while it drags) and the Android room actions sheet.
#[derive(Clone, Copy)]
pub(super) struct RoomListCtx {
    #[cfg_attr(not(target_os = "android"), allow(dead_code))]
    pub scroll: ScrollController,
    pub sheet: State<Option<RoomSheet>>,
}

/// Filtered room list with loading / empty states. Reads the list published
/// by `utils::room_list`; builds nothing itself.
#[derive(PartialEq)]
pub struct RoomList {
    pub mailbox: Mailbox,
    pub filter: RoomFilter,
    /// `None` for lists shown without the filter bar.
    pub filter_bar: Option<FilterBarScroll>,
}

impl Component for RoomList {
    fn render(&self) -> impl IntoElement {
        let _timer = RenderTimer::new("RoomList");
        let c = use_app_colors();
        let snapshot = use_watch(room_list::receiver());
        let mailbox_tick = use_watch_tick(ROOM_MAILBOX_RX.get().expect("not initialized"));

        let scroll = use_scroll_controller(ScrollConfig::default);
        let sheet = use_state(|| None::<RoomSheet>);
        use_provide_context(|| RoomListCtx { scroll, sheet });
        let mut viewport_height = use_state(|| 0.0f32);
        // Latest visible rooms, for the key handler (its closure outlives renders).
        let shown: Rc<RefCell<Rc<Vec<RoomSummary>>>> = use_hook(Default::default);
        let bar_height = if self.filter_bar.is_some() {
            FILTER_BAR_HEIGHT
        } else {
            0.
        };
        use_list_keys(shown.clone(), scroll, viewport_height, bar_height);
        use_chips_follow_scroll(scroll, self.filter_bar);

        let snapshot = snapshot.read().clone();
        let filtered_rooms = Rc::new({
            let mailbox = ROOM_MAILBOX_RX.get().expect("not initialized").borrow();
            visible_rooms(&snapshot.rooms, self.mailbox, &self.filter, &mailbox)
        });
        *shown.borrow_mut() = filtered_rooms.clone();
        let rooms_len = filtered_rooms.len();
        if rooms_len > 0 {
            static FIRST: std::sync::Once = std::sync::Once::new();
            FIRST.call_once(|| crate::logging::boot("room list shown"));
        }
        let initial_loading = snapshot.version == 0;

        // Below the filter bar, which overlays the top of the list.
        let below_bar = |content: Element| {
            rect()
                .expanded()
                .padding(Gaps::new(bar_height, 0., 0., 0.))
                .child(content)
                .into_element()
        };
        if initial_loading && rooms_len == 0 {
            return below_bar(loading_state(Some("Loading conversations…"), c).into_element());
        }
        if rooms_len == 0 {
            return below_bar(no_rooms(c, self.mailbox, &self.filter));
        }

        // The builder closure captures `filtered_rooms`, which either input can change.
        let list_key = (snapshot.version, *mailbox_tick.read());
        rect()
            .expanded()
            .child(
                VirtualScrollView::new_with_data(list_key, move |item, _| {
                    let Some(summary) = filtered_rooms.get(item.index) else {
                        return rect().into_element();
                    };
                    // Keyed by room: unkeyed, rows are matched by position, so every
                    // scroll step hands each row a new room and all of them re-render.
                    rect()
                        .key(&summary.room_id)
                        .width(Size::fill())
                        .child(RoomListItem {
                            summary: summary.clone(),
                        })
                        .into_element()
                })
                .length(rooms_len)
                .item_size(ROOM_ROW_HEIGHT)
                .leading_space(bar_height)
                .height(Size::fill())
                .scroll_controller(scroll)
                .on_sized(move |e: Event<SizedEventData>| {
                    viewport_height.set_if_modified(e.area.height());
                })
                .into_element(),
            )
            .maybe_child(room_sheet(sheet, c))
            .into_element()
    }
}

/// Slides the filter bar out as the list scrolls down and back in as soon as
/// it scrolls up ("quick return"), pixel for pixel, never further than the
/// list has scrolled, so it is fully in place at the top. Follows the animated
/// position, so flings move it smoothly too, without re-rendering the list.
fn use_chips_follow_scroll(scroll: ScrollController, filter_bar: Option<FilterBarScroll>) {
    let last_y = use_hook(|| Rc::new(std::cell::Cell::new(0f32)));
    use_side_effect(move || {
        let (x, y): (i32, i32) = scroll.into();
        let y = scroll
            .animated_position(freya::torin::geometry::Point2D::new(x as f32, y as f32))
            .y
            .min(0.);
        // Offsets are negative: scrolling down makes `y` smaller.
        let delta = y - last_y.replace(y);
        let Some(FilterBarScroll {
            mut hidden,
            visible: mut chips_visible,
            mut scrolled,
        }) = filter_bar
        else {
            return;
        };
        let is_scrolled = y < -1.;
        if *scrolled.peek() != is_scrolled {
            scrolled.set(is_scrolled);
        }
        if WIDE_MODE.load(std::sync::atomic::Ordering::Relaxed) {
            return;
        }
        let next = (*hidden.peek() - delta).clamp(0., FILTER_BAR_HEIGHT).min(-y);
        if next != *hidden.peek() {
            hidden.set(next);
        }
        let visible = next < FILTER_BAR_HEIGHT / 2.;
        if visible != *chips_visible.peek() {
            chips_visible.set(visible);
        }
    });
}

/// j/k, gg/G, J/K, Enter and the room actions, while the list has keyboard focus.
fn use_list_keys(
    shown: Rc<RefCell<Rc<Vec<RoomSummary>>>>,
    scroll: ScrollController,
    viewport_height: State<f32>,
    bar_height: f32,
) {
    use_key_commands(move |nav, command| {
        if *nav.area.peek() == Area::List {
            let rooms = shown.borrow().clone();
            list_command(command, &rooms, nav, scroll, *viewport_height.peek(), bar_height);
        }
    });
}

fn list_command(
    command: KeyCommand,
    rooms: &[RoomSummary],
    nav: KeyNav,
    mut scroll: ScrollController,
    viewport_height: f32,
    bar_height: f32,
) {
    let Some(last) = rooms.len().checked_sub(1) else {
        return;
    };
    let current = {
        let selected = nav.selected.peek();
        selected
            .as_deref()
            .and_then(|id| rooms.iter().position(|r| r.room_id == id))
    };
    let is_unread = |i: &usize| rooms[*i].is_unread();
    let target = match command {
        KeyCommand::Down => Some(current.map_or(0, |i| (i + 1).min(last))),
        KeyCommand::Up => Some(current.map_or(0, |i| i.saturating_sub(1))),
        KeyCommand::Top => Some(0),
        KeyCommand::Bottom => Some(last),
        KeyCommand::NextUnread => (current.map_or(0, |i| i + 1)..=last).find(is_unread),
        KeyCommand::PrevUnread => (0..current.unwrap_or(0)).rev().find(is_unread),
        _ => None,
    };
    if let Some(index) = target {
        let mut selected = nav.selected;
        selected.set(Some(rooms[index].room_id.clone()));
        scroll_into_view(&mut scroll, index, viewport_height, bar_height);
        return;
    }
    let Some(room) = current.map(|i| &rooms[i]) else {
        return;
    };
    let id = room.room_id.clone();
    match command {
        KeyCommand::Open => {
            // Invites have no composer: the request would linger and steal
            // focus on a later open.
            if !room.is_invite {
                let mut focus_composer = nav.focus_composer;
                focus_composer.set(true);
            }
            navigate_to_room(id);
        }
        KeyCommand::ToggleFavourite => run(id, RoomAction::Favourite(!room.is_favourite)),
        KeyCommand::ToggleRead if room.is_unread() => run(id, RoomAction::MarkRead),
        KeyCommand::ToggleRead => run(id, RoomAction::MarkUnread),
        KeyCommand::Archive => {
            tokio::spawn(async move { crate::utils::room_mailbox::archive_room(&id).await });
        }
        _ => {}
    }
}

/// Scrolls just enough for row `index` to be fully visible.
fn scroll_into_view(
    scroll: &mut ScrollController,
    index: usize,
    viewport_height: f32,
    bar_height: f32,
) {
    let top = bar_height + index as f32 * ROOM_ROW_HEIGHT;
    let bottom = top + ROOM_ROW_HEIGHT;
    let (_, y) = Into::<(i32, i32)>::into(*scroll);
    let view_top = -y as f32;
    if top < view_top {
        scroll.scroll_to_y(-(top as i32));
    } else if bottom > view_top + viewport_height {
        scroll.scroll_to_y(-((bottom - viewport_height) as i32));
    }
}

fn no_rooms(c: AppColors, mailbox: Mailbox, filter: &RoomFilter) -> Element {
    let (title, subtitle) = match (mailbox, filter) {
        (Mailbox::Recontact, RoomFilter::All) => {
            ("Nothing to recontact", "Mark a room to recontact it later")
        }
        (Mailbox::Archived, RoomFilter::All) => (
            "Nothing archived",
            "Archive a room once you're done with it",
        ),
        (Mailbox::Inbox, _) => (filter.empty_title(), filter.empty_subtitle()),
        _ => ("No matching rooms", "Try another filter"),
    };
    empty_state(
        freya_icons::lucide::message_circle(),
        title,
        Some(subtitle),
        c,
    )
    .into()
}
