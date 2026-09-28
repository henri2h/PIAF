use freya::prelude::*;

use super::filter_chip::RoomFilter;
use super::room_list_item::RoomListItem;
use super::sort_rooms_by_recency;
use crate::ROOM_MAILBOX_RX;
use crate::utils::const_values::AppColors;
use crate::utils::matrix::CLIENT;
use crate::utils::room_mailbox::is_archived_hidden;
use crate::utils::use_app_colors;

/// Loading / empty states, or the virtualized, filtered, recency-sorted list
/// of joined + invited rooms.
///
/// `sync_tick` is owned by `HomePage` and bumped on every Matrix sync, so
/// passing it in (rather than subscribing here) makes the re-render trigger
/// explicit. `chips_visible` is also `HomePage`-owned, so scrolling here can
/// drive the filter bar's visibility above this component. `mailbox_tick`
/// bumps on every recontact/archive change so archived rooms drop out (or
/// reappear) without waiting for the next sync tick.
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
        // Diagnostics only: gives the scroll offset a name so [ROOMLIST] lines
        // can be correlated with viewport changes.
        let scroll_controller = use_scroll_controller(ScrollConfig::default);

        // Fetching + sorting the full room list only actually needs to happen
        // when `sync_tick` moves; a mailbox_tick-only render (recontact/archive
        // toggle) never changes membership or order, just the filter below, so
        // it reuses the cached, already-sorted list instead of redoing both.
        let fetch_sort_start = std::time::Instant::now();
        let rooms: std::rc::Rc<Vec<matrix_sdk::Room>> =
            crate::utils::use_keyed_cache(self.sync_tick, || {
                let mut rooms: Vec<matrix_sdk::Room> = CLIENT
                    .get()
                    .map(|c| {
                        let mut r = c.joined_rooms();
                        r.extend(c.invited_rooms());
                        r
                    })
                    .unwrap_or_default();
                sort_rooms_by_recency(&mut rooms);
                std::rc::Rc::new(rooms)
            });
        let fetch_sort_elapsed = fetch_sort_start.elapsed();

        let mailbox = ROOM_MAILBOX_RX
            .get()
            .map(|rx| rx.borrow().clone())
            .unwrap_or_default();

        // Only the rooms that survive filtering get cloned out of the cached
        // `Rc<Vec<Room>>` — a cache hit above is now O(1), and this clones at
        // most the visible-list size instead of the full room count.
        let filter_start = std::time::Instant::now();
        let filtered_rooms: Vec<_> = rooms
            .iter()
            .filter(|r| self.filter.matches(r))
            .filter(|r| {
                let archived_until_ts = mailbox
                    .get(r.room_id().as_str())
                    .and_then(|s| s.archived_until_ts);
                let latest_ts = r.latest_event().timestamp().map(|ts| ts.get().into());
                !is_archived_hidden(latest_ts, archived_until_ts)
            })
            .cloned()
            .collect();
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

        // Keyed on both ticks, not just `sync_tick`: the builder closure below
        // captures `filtered_rooms`, which `mailbox_tick` changes too. Keying
        // on `sync_tick` alone left the scroll view holding the old closure
        // while `length` had already moved, so indices pointed into a stale
        // list and an archived row stayed on screen.
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
