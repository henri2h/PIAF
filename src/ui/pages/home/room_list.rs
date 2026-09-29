use freya::prelude::*;

use super::room_list_item::{ROOM_ROW_HEIGHT, RoomListItem};
use super::room_list_model::{RoomFilter, visible_rooms};
use crate::ROOM_MAILBOX_RX;
use crate::logging::RenderTimer;
use crate::utils::const_values::AppColors;
use crate::utils::room_list;
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

        let snapshot = snapshot.read().clone();
        let filtered_rooms = {
            let mailbox = ROOM_MAILBOX_RX.get().expect("not initialized").borrow();
            visible_rooms(&snapshot.rooms, &self.filter, &mailbox)
        };
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
