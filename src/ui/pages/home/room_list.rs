use freya::prelude::*;

use super::room_list_item::{ROOM_ROW_HEIGHT, RoomListItem};
use super::room_list_model::{RoomFilter, RoomSummary, all_room_summaries, visible_rooms};
use crate::ROOM_MAILBOX_RX;
use crate::logging::{PERF, RenderTimer};
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
        let _timer = RenderTimer::new("RoomList");
        let c = use_app_colors();
        let mut chips_visible = self.chips_visible;

        // Refetch + sort only on sync; mailbox changes only affect filtering.
        let fetch_sort_start = std::time::Instant::now();
        let rooms: std::rc::Rc<Vec<RoomSummary>> = crate::utils::use_keyed_cache(
            self.sync_tick,
            || std::rc::Rc::new(all_room_summaries()),
        );
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

        tracing::debug!(
            target: PERF,
            sync_tick = self.sync_tick,
            mailbox_tick = self.mailbox_tick,
            rooms = rooms.len(),
            visible = rooms_len,
            "RoomList fetch+sort {}µs, filter {}µs",
            fetch_sort_elapsed.as_micros(),
            filter_elapsed.as_micros(),
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
                    RoomListItem {
                        summary: summary.clone(),
                    }
                    .into_element()
                })
                .length(rooms_len)
                .item_size(ROOM_ROW_HEIGHT)
                .height(Size::fill())
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
