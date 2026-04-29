mod filter_chip;
mod room_list_item;

use std::sync::atomic::Ordering;

use filter_chip::{FilterChip, RoomFilter};
use freya::prelude::*;
use freya_material_design::prelude::Ripple;
use freya_query::prelude::*;
use freya_router::prelude::RouterContext;
use room_list_item::RoomListItem;
use std::time::Duration;

use crate::ui::components::Avatar;
use crate::utils::queries::FetchUserDisplayName;
use crate::utils::{use_app_colors, use_tokio_track_watcher};
use crate::{ACTIVE_ROOM_RX, Route, SYNC_RX, WIDE_MODE, utils::matrix::CLIENT};

// ---------------------------------------------------------------------------
// Shared context for the currently active room ID
// ---------------------------------------------------------------------------

/// Provided by HomePage; consumed by RoomListItem to highlight the active room.
#[derive(Clone, Copy)]
pub(super) struct ActiveRoomCtx(pub State<Option<String>>);

// ---------------------------------------------------------------------------
// HomePage
// ---------------------------------------------------------------------------

#[derive(PartialEq)]
pub struct HomePage {}

impl Component for HomePage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let mut chips_visible: State<bool> = use_state(|| false);
        let sync_tick: State<u64> = use_state(|| 0u64);
        if let Some(rx) = SYNC_RX.get() {
            use_tokio_track_watcher(rx, sync_tick);
        }

        // Active room: drive via context so RoomListItem re-renders in-place
        // without remounting VirtualScrollView (which would reset scroll position).
        let active_room: State<Option<String>> = use_state(|| {
            ACTIVE_ROOM_RX.get().and_then(|rx| rx.borrow().clone())
        });
        use_hook(|| {
            let mut active_room = active_room;
            if let Some(rx) = ACTIVE_ROOM_RX.get() {
                let (tx, mut chan) = futures::channel::mpsc::unbounded::<Option<String>>();
                let mut rx = rx.clone();
                tokio::task::spawn(async move {
                    while rx.changed().await.is_ok() {
                        let val = rx.borrow().clone();
                        if tx.unbounded_send(val).is_err() { break; }
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

        let mut search: State<String> = use_state(String::new);
        // Narrow mode: search toggle
        let mut search_open: State<bool> = use_state(|| false);
        let filter: State<RoomFilter> = use_state(|| RoomFilter::All);

        let name_query =
            use_query(Query::new((), FetchUserDisplayName).stale_time(Duration::from_secs(3600)));

        let name_reader = name_query.read();
        let initial = name_reader
            .state()
            .ok()
            .and_then(|n| n.chars().next())
            .map(|c| c.to_uppercase().to_string())
            .unwrap_or_else(|| "?".to_string());

        let mut rooms = CLIENT.get().map(|c| c.joined_rooms()).unwrap_or_default();
        rooms.sort_unstable_by(|a, b| {
            let a_stamp = a.recency_stamp().map(u64::from).unwrap_or(0);
            let b_stamp = b.recency_stamp().map(u64::from).unwrap_or(0);
            b_stamp.cmp(&a_stamp)
        });

        let search_text = search.read().to_lowercase();
        let active_filter = filter.read().clone();
        let filtered_rooms: Vec<_> = rooms
            .into_iter()
            .filter(|r| {
                let name_matches = if search_text.is_empty() {
                    true
                } else {
                    r.cached_display_name()
                        .map(|n| n.to_string().to_lowercase().contains(&search_text))
                        .unwrap_or(false)
                };
                name_matches && active_filter.matches(r)
            })
            .collect();
        let rooms_len = filtered_rooms.len();

        let initial_loading = CLIENT.get().is_none();
        let _ = *sync_tick.read();
        let is_wide = WIDE_MODE.load(Ordering::Relaxed);
        let is_search_open = *search_open.read();
        let show_chips = *chips_visible.read();

        // ── Search input builder ───────────────────────────────────────────────
        let mk_search = || {
            Input::new(search)
                .leading(
                    svg(freya_icons::lucide::search())
                        .color(c.on_surface_variant)
                        .width(Size::px(15.))
                        .height(Size::px(15.)),
                )
                .placeholder("Search conversations…")
                .width(Size::fill())
                .theme_colors(InputColorsThemePartial {
                    background: Some(Preference::Specific(Color::from(c.surface_container))),
                    hover_background: Some(Preference::Specific(Color::from(
                        c.surface_container,
                    ))),
                    border_fill: Some(Preference::Specific(Color::TRANSPARENT)),
                    focus_border_fill: Some(Preference::Specific(Color::from(c.primary))),
                    ..Default::default()
                })
                .theme_layout(InputLayoutThemePartial {
                    corner_radius: Some(Preference::Specific(CornerRadius::new_all(8.))),
                    inner_margin: Some(Preference::Specific(Gaps::new(10., 10., 10., 10.))),
                })
        };

        // ── App bar ────────────────────────────────────────────────────────────
        let app_bar = {
            let initial_bar = initial.clone();
            rect()
                .vertical()
                .width(Size::fill())
                .background(c.surface)
                .child(
                    rect()
                        .width(Size::fill())
                        .height(Size::px(crate::utils::const_values::STATUS_BAR_INSET)),
                )
                .child(
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .height(Size::px(64.))
                        .content(Content::Flex)
                        .cross_align(Alignment::Center)
                        .padding(Gaps::new(0., 8., 0., 8.))
                        // Avatar — taps to Settings
                        .child(
                            rect()
                                .width(Size::px(48.))
                                .height(Size::px(48.))
                                .corner_radius(24.)
                                .center()
                                .on_press(move |_| {
                                    let _ = RouterContext::get().push(Route::Settings);
                                })
                                .child(Avatar {
                                    size: 36.,
                                    bytes: None,
                                    fetch_key: Some("__self__".to_string()),
                                    initial: initial_bar,
                                    color: c.primary,
                                    image_key: "__self__".to_string(),
                                }),
                        )
                        // Wide: inline search input; narrow: "Chats" title
                        .child(if is_wide {
                            rect()
                                .width(Size::flex(1.0))
                                .padding(Gaps::new(0., 8., 0., 8.))
                                .child(mk_search())
                                .into_element()
                        } else {
                            label()
                                .text("Chats")
                                .font_size(22.)
                                .font_weight(FontWeight::MEDIUM)
                                .color(c.on_surface)
                                .width(Size::flex(1.0))
                                .padding(Gaps::new(0., 8., 0., 8.))
                                .into_element()
                        })
                        // Narrow: search toggle icon
                        .maybe_child(if !is_wide {
                            Some(
                                rect()
                                    .width(Size::px(48.))
                                    .height(Size::px(48.))
                                    .corner_radius(24.)
                                    .center()
                                    .on_press(move |_| {
                                        let new_val = !*search_open.read();
                                        if !new_val {
                                            *search.write() = String::new();
                                        }
                                        *search_open.write() = new_val;
                                    })
                                    .child(
                                        svg(if is_search_open {
                                            freya_icons::lucide::x()
                                        } else {
                                            freya_icons::lucide::search()
                                        })
                                        .color(c.on_surface_variant)
                                        .width(Size::px(22.))
                                        .height(Size::px(22.)),
                                    ),
                            )
                        } else {
                            None
                        })
                        // Pencil button (both modes)
                        .child(
                            rect()
                                .width(Size::px(48.))
                                .height(Size::px(48.))
                                .corner_radius(24.)
                                .center()
                                .on_press(|_| {
                                    let _ = RouterContext::get().push(crate::Route::NewChat);
                                })
                                .child(
                                    svg(freya_icons::lucide::pencil())
                                        .color(c.on_surface_variant)
                                        .width(Size::px(22.))
                                        .height(Size::px(22.)),
                                ),
                        ),
                )
        };

        // ── Filter chip bar ────────────────────────────────────────────────────
        let filter_bar = {
            let filters = [
                RoomFilter::All,
                RoomFilter::Groups,
                RoomFilter::Dms,
                RoomFilter::Unread,
            ];
            let mut row = rect()
                .horizontal()
                .width(Size::fill())
                .content(Content::Flex)
                .padding(Gaps::new(6., 16., 6., 16.))
                .spacing(6.)
                .background(c.surface);
            for f in &filters {
                let is_selected = *filter.read() == *f;
                row = row.child(FilterChip {
                    chip_label: f.label(),
                    selected: is_selected,
                    filter,
                    value: f.clone(),
                });
            }
            row
        };

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(app_bar)
            // Filter chips — hidden by default on narrow (shown on scroll-up), always visible on wide
            .child(if show_chips || is_wide {
                filter_bar.into_element()
            } else {
                rect().into_element()
            })
            // Narrow: inline search bar below app bar when toggled
            .maybe_child(if !is_wide && is_search_open {
                Some(
                    rect()
                        .width(Size::fill())
                        .padding(Gaps::new(6., 16., 6., 16.))
                        .background(c.surface)
                        .child(mk_search()),
                )
            } else {
                None
            })
            // Main content: loading / empty / room list
            .child(if initial_loading && rooms_len == 0 {
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
                    .into_element()
            } else if rooms_len == 0 {
                rect()
                    .expanded()
                    .center()
                    .vertical()
                    .spacing(12.)
                    .child(
                        svg(freya_icons::lucide::message_circle())
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
                    .into_element()
            } else {
                let list_key: u64 = filtered_rooms
                    .first()
                    .and_then(|r| r.recency_stamp().map(u64::from))
                    .unwrap_or(0)
                    .wrapping_add(rooms_len as u64);
                rect()
                    .expanded()
                    .on_wheel(move |e: Event<WheelEventData>| {
                        if e.delta_y < 0.0 {
                            *chips_visible.write() = true;
                        } else if e.delta_y > 0.0 {
                            *chips_visible.write() = false;
                        }
                    })
                    .child(
                        VirtualScrollView::new(move |i, _| {
                            let Some(room) = filtered_rooms.get(i) else {
                                return rect().into_element();
                            };
                            let room_id = room.room_id().to_string();
                            rect()
                                .key(room_id)
                                .width(Size::fill())
                                .child(RoomListItem { room: room.clone() })
                                .into()
                        })
                        .key(format!("vscroll-{list_key}"))
                        .length(rooms_len)
                        .item_size(80.)
                        .height(Size::fill())
                        .into_element(),
                    )
                    .into_element()
            })
            // New chat FAB — narrow mode only (wide has pencil in app bar)
            .child(if !is_wide {
                rect()
                    .position(Position::new_global().right(16.).bottom(16.))
                    .layer(100)
                    .width(Size::px(56.))
                    .height(Size::px(56.))
                    .corner_radius(16.)
                    .background(c.primary)
                    .shadow((0., 4., 12., 2., (0, 0, 0, 60)))
                    .overflow(Overflow::Clip)
                    .on_press(|_| {
                        let _ = RouterContext::get().push(crate::Route::NewChat);
                    })
                    .child(
                        Ripple::new()
                            .width(Size::fill())
                            .height(Size::fill())
                            .child(
                                rect()
                                    .width(Size::fill())
                                    .height(Size::fill())
                                    .center()
                                    .child(
                                        svg(freya_icons::lucide::pencil())
                                            .width(Size::px(22.))
                                            .height(Size::px(22.))
                                            .color(c.on_primary),
                                    ),
                            ),
                    )
                    .into_element()
            } else {
                rect().into_element()
            })
    }
}
