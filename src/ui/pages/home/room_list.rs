use std::cell::RefCell;
use std::rc::Rc;

use freya::prelude::*;

use super::room_list_item::{ROOM_ROW_HEIGHT, RoomListItem};
use super::room_list_model::{RoomFilter, visible_rooms};
use crate::ROOM_MAILBOX_RX;
use crate::app::keys::{Area, KeyCommand, KeyNav, use_key_commands};
use crate::app::navigation::navigate_to_room;
use crate::logging::RenderTimer;
use crate::utils::const_values::AppColors;
use crate::utils::room_actions::{RoomAction, run};
use crate::utils::room_list;
use crate::utils::room_list::RoomSummary;
use crate::utils::{use_app_colors, use_watch, use_watch_tick};

/// Filtered room list with loading / empty states. Reads the list published
/// by `utils::room_list`; builds nothing itself.
#[derive(PartialEq)]
pub struct RoomList {
    pub filter: RoomFilter,
    pub chips_visible: State<bool>,
}

impl Component for RoomList {
    fn render(&self) -> impl IntoElement {
        let _timer = RenderTimer::new("RoomList");
        let c = use_app_colors();
        let mut chips_visible = self.chips_visible;
        let snapshot = use_watch(room_list::receiver());
        let mailbox_tick = use_watch_tick(ROOM_MAILBOX_RX.get().expect("not initialized"));

        let scroll = use_scroll_controller(ScrollConfig::default);
        let mut viewport_height = use_state(|| 0.0f32);
        // Latest visible rooms, for the key handler (its closure outlives renders).
        let shown: Rc<RefCell<Rc<Vec<RoomSummary>>>> = use_hook(Default::default);
        use_list_keys(shown.clone(), scroll, viewport_height);

        let snapshot = snapshot.read().clone();
        let filtered_rooms = Rc::new({
            let mailbox = ROOM_MAILBOX_RX.get().expect("not initialized").borrow();
            visible_rooms(&snapshot.rooms, &self.filter, &mailbox)
        });
        *shown.borrow_mut() = filtered_rooms.clone();
        let rooms_len = filtered_rooms.len();
        let initial_loading = snapshot.version == 0;

        if initial_loading && rooms_len == 0 {
            return loading_state(c);
        }
        if rooms_len == 0 {
            return empty_state(c, &self.filter);
        }

        // The builder closure captures `filtered_rooms`, which either input can change.
        let list_key = (snapshot.version, *mailbox_tick.read());
        rect()
            .expanded()
            .on_wheel(move |e: Event<WheelEventData>| {
                if e.delta_y < 0.0 && !*chips_visible.peek() {
                    chips_visible.set(true);
                } else if e.delta_y > 0.0 && *chips_visible.peek() {
                    chips_visible.set(false);
                }
            })
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
                .height(Size::fill())
                .scroll_controller(scroll)
                .on_sized(move |e: Event<SizedEventData>| {
                    viewport_height.set_if_modified(e.area.height());
                })
                .into_element(),
            )
            .into_element()
    }
}

/// j/k, gg/G, J/K, Enter and the room actions, while the list has keyboard focus.
fn use_list_keys(
    shown: Rc<RefCell<Rc<Vec<RoomSummary>>>>,
    scroll: ScrollController,
    viewport_height: State<f32>,
) {
    use_key_commands(move |nav, command| {
        if *nav.area.peek() == Area::List {
            let rooms = shown.borrow().clone();
            list_command(command, &rooms, nav, scroll, *viewport_height.peek());
        }
    });
}

fn list_command(
    command: KeyCommand,
    rooms: &[RoomSummary],
    nav: KeyNav,
    mut scroll: ScrollController,
    viewport_height: f32,
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
        scroll_into_view(&mut scroll, index, viewport_height);
        return;
    }
    let Some(room) = current.map(|i| &rooms[i]) else {
        return;
    };
    let id = room.room_id.clone();
    match command {
        KeyCommand::Open => navigate_to_room(id),
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
fn scroll_into_view(scroll: &mut ScrollController, index: usize, viewport_height: f32) {
    let top = index as f32 * ROOM_ROW_HEIGHT;
    let bottom = top + ROOM_ROW_HEIGHT;
    let (_, y) = Into::<(i32, i32)>::into(*scroll);
    let view_top = -y as f32;
    if top < view_top {
        scroll.scroll_to_y(-(top as i32));
    } else if bottom > view_top + viewport_height {
        scroll.scroll_to_y(-((bottom - viewport_height) as i32));
    }
}

fn loading_state(c: AppColors) -> Element {
    rect()
        .expanded()
        .center()
        .vertical()
        .spacing(16.)
        .child(CircularLoader::new().size(40.))
        .child(
            label()
                .text("Loading conversations…")
                .font_size(14.)
                .color(c.on_surface_muted),
        )
        .into()
}

fn empty_state(c: AppColors, filter: &RoomFilter) -> Element {
    rect()
        .expanded()
        .center()
        .vertical()
        .spacing(12.)
        .child(
            SvgViewer::new(freya_icons::lucide::message_circle())
                .width(Size::px(48.))
                .height(Size::px(48.))
                .color(c.outline_variant_light),
        )
        .child(
            label()
                .text(filter.empty_title())
                .font_size(16.)
                .color(c.on_surface_muted),
        )
        .child(
            label()
                .text(filter.empty_subtitle())
                .font_size(13.)
                .color(c.outline_variant_light),
        )
        .into()
}
