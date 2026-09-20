use freya::prelude::*;

use super::filter_chip::RoomFilter;
use super::room_list_item::RoomListItem;
use super::sort_rooms_by_recency;
use crate::utils::const_values::AppColors;
use crate::utils::matrix::CLIENT;
use crate::utils::use_app_colors;

/// Loading / empty states, or the virtualized, filtered, recency-sorted list
/// of joined + invited rooms.
///
/// `sync_tick` is owned by `HomePage` and bumped on every Matrix sync, so
/// passing it in (rather than subscribing here) makes the re-render trigger
/// explicit. `chips_visible` is also `HomePage`-owned, so scrolling here can
/// drive the filter bar's visibility above this component.
pub struct RoomList {
    pub filter: RoomFilter,
    pub chips_visible: State<bool>,
    pub sync_tick: u64,
}

impl PartialEq for RoomList {
    fn eq(&self, other: &Self) -> bool {
        self.filter == other.filter && self.sync_tick == other.sync_tick
    }
}

impl Component for RoomList {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut chips_visible = self.chips_visible;

        let mut rooms: Vec<matrix_sdk::Room> = CLIENT
            .get()
            .map(|c| {
                let mut r = c.joined_rooms();
                r.extend(c.invited_rooms());
                r
            })
            .unwrap_or_default();
        sort_rooms_by_recency(&mut rooms);

        let filtered_rooms: Vec<_> = rooms
            .into_iter()
            .filter(|r| self.filter.matches(r))
            .collect();
        let rooms_len = filtered_rooms.len();
        let initial_loading = CLIENT.get().is_none();

        eprintln!(
            "[piaf] RoomList::render sync_tick={} client_present={} rooms_len={} filter={:?}",
            self.sync_tick, !initial_loading, rooms_len, self.filter
        );

        if initial_loading && rooms_len == 0 {
            return loading_state(c);
        }
        if rooms_len == 0 {
            return empty_state(c);
        }

        let sync_tick = self.sync_tick;
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
                VirtualScrollView::new_with_data(sync_tick, move |item, _| {
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
