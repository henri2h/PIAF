use freya::prelude::*;

use super::room_list_item::RoomListItem;
use super::room_list_model::{RoomFilter, all_rooms_sorted, visible_rooms};
use crate::ROOM_MAILBOX_RX;
use crate::utils::const_values::AppColors;
use crate::utils::matrix::CLIENT;
use crate::utils::use_app_colors;

/// Filtered, recency-sorted room list with loading / empty states.
/// `sync_tick` and `mailbox_tick` are owned by `HomePage` and drive re-renders.
pub struct RoomList {
    pub filter: RoomFilter,
    pub chips_visible: State<bool>,
    pub sync_tick: u64,
    pub mailbox_tick: u64,
}

impl PartialEq for RoomList {
    fn eq(&self, other: &Self) -> bool {
        self.filter == other.filter
            && self.sync_tick == other.sync_tick
            && self.mailbox_tick == other.mailbox_tick
    }
}

impl Component for RoomList {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut chips_visible = self.chips_visible;
        let scroll_controller = use_scroll_controller(ScrollConfig::default);

        // Refetch + sort only on sync; mailbox changes only affect filtering.
        let fetch_sort_start = std::time::Instant::now();
        let rooms: std::rc::Rc<Vec<matrix_sdk::Room>> =
            crate::utils::use_keyed_cache(self.sync_tick, || std::rc::Rc::new(all_rooms_sorted()));
        let fetch_sort_elapsed = fetch_sort_start.elapsed();

        let mailbox = ROOM_MAILBOX_RX
            .get()
            .expect("not initialized")
            .borrow()
            .clone();

        let filter_start = std::time::Instant::now();
        let filtered_rooms = visible_rooms(&rooms, &self.filter, &mailbox);
        let filter_elapsed = filter_start.elapsed();

        let rooms_len = filtered_rooms.len();
        let initial_loading = CLIENT.get().is_none();

        println!(
            "[piaf] RoomList::render sync_tick={} mailbox_tick={} client_present={} rooms_len={} filter={:?} chips_visible={}",
            self.sync_tick,
            self.mailbox_tick,
            !initial_loading,
            rooms_len,
            self.filter,
            *chips_visible.peek(),
        );
        println!(
            "[TIMING] RoomList rebuild total={}µs (fetch+sort={}µs filter={}µs) rooms={}",
            (fetch_sort_elapsed + filter_elapsed).as_micros(),
            fetch_sort_elapsed.as_micros(),
            filter_elapsed.as_micros(),
            rooms_len,
        );

        if initial_loading && rooms_len == 0 {
            return loading_state(c);
        }
        if rooms_len == 0 {
            return empty_state(c);
        }

        // Both ticks: the builder closure captures `filtered_rooms`, which either can change.
        let list_key = (self.sync_tick, self.mailbox_tick);
        rect()
            .expanded()
            .on_wheel(move |e: Event<WheelEventData>| {
                if e.delta_y < 0.0 && !*chips_visible.peek() {
                    println!("[ROOMLIST] chips -> visible (delta_y={:.1})", e.delta_y);
                    chips_visible.set(true);
                } else if e.delta_y > 0.0 && *chips_visible.peek() {
                    println!("[ROOMLIST] chips -> hidden (delta_y={:.1})", e.delta_y);
                    chips_visible.set(false);
                }
            })
            .child(
                VirtualScrollView::new_with_data(list_key, move |item, _| {
                    let Some(room) = filtered_rooms.get(item.index) else {
                        return rect().into_element();
                    };
                    rect()
                        .width(Size::fill())
                        .child(RoomListItem { room: room.clone() })
                        .into()
                })
                .length(rooms_len)
                .item_size(80.)
                .height(Size::fill())
                .scroll_controller(scroll_controller)
                .on_sized(move |e: Event<SizedEventData>| {
                    let (_, y) = Into::<(i32, i32)>::into(scroll_controller);
                    println!(
                        "[ROOMLIST] sized viewport={:.1} content={:.1} y={} rooms={}",
                        e.area.height(),
                        e.inner_sizes.height,
                        y,
                        rooms_len,
                    );
                })
                .into_element(),
            )
            .into_element()
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

fn empty_state(c: AppColors) -> Element {
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
                .text("No conversations yet")
                .font_size(16.)
                .color(c.on_surface_muted),
        )
        .child(
            label()
                .text("Join a room or start a new chat")
                .font_size(13.)
                .color(c.outline_variant_light),
        )
        .into()
}
