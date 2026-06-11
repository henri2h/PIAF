mod filter_chip;
pub mod room_list_item;
pub mod search;
mod search_tile;

use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;

use filter_chip::{FilterChip, RoomFilter};
use freya::prelude::*;
use freya_query::prelude::*;
use freya_router::prelude::RouterContext;
use room_list_item::RoomListItem;
use search::{MessageResult, search_messages_remote, search_rooms_local, search_users_remote};
use search_tile::{MessageSearchTile, RoomSearchTile, UserSearchTile};

use crate::ui::components::Avatar;
use crate::utils::queries::FetchUserDisplayName;
use crate::utils::{matrix::CLIENT, use_app_colors, use_tokio_track_watcher};
use crate::{ACTIVE_ROOM_RX, ACTIVE_ROOM_TX, Route, WIDE_MODE};

// ---------------------------------------------------------------------------
// Shared helpers used by submodules
// ---------------------------------------------------------------------------

/// Navigate to a room: in wide mode sends to ACTIVE_ROOM_TX, always pushes the route.
pub(crate) fn navigate_to_room(room_id: String) {
    if WIDE_MODE.load(Ordering::Relaxed) {
        if let Some(tx) = ACTIVE_ROOM_TX.get() {
            let _ = tx.send(Some(room_id.clone()));
        }
    }
    let _ = RouterContext::get().push(Route::RoomPage { room_id });
}

/// Sort a room slice in-place by descending recency stamp.
fn sort_rooms_by_recency(rooms: &mut Vec<matrix_sdk::Room>) {
    rooms.sort_unstable_by(|a, b| {
        b.recency_stamp()
            .map(u64::from)
            .unwrap_or(0)
            .cmp(&a.recency_stamp().map(u64::from).unwrap_or(0))
    });
}

// ---------------------------------------------------------------------------
// Shared context for the currently active room ID
// ---------------------------------------------------------------------------

/// Provided by HomePage; consumed by RoomListItem to highlight the active room.
#[derive(Clone, Copy)]
pub struct ActiveRoomCtx(pub State<Option<String>>);

// ---------------------------------------------------------------------------
// HomePage
// ---------------------------------------------------------------------------

#[derive(PartialEq)]
pub struct HomePage {}

impl Component for HomePage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let mut chips_visible: State<bool> = use_state(|| false);

        // Active room: drive via context so RoomListItem re-renders in-place
        // without remounting VirtualScrollView (which would reset scroll position).
        let active_room: State<Option<String>> =
            use_state(|| ACTIVE_ROOM_RX.get().and_then(|rx| rx.borrow().clone()));
        use_hook(|| {
            let mut active_room = active_room;
            if let Some(rx) = ACTIVE_ROOM_RX.get() {
                let (tx, mut chan) = futures::channel::mpsc::unbounded::<Option<String>>();
                let mut rx = rx.clone();
                tokio::task::spawn(async move {
                    while rx.changed().await.is_ok() {
                        let val = rx.borrow().clone();
                        if tx.unbounded_send(val).is_err() {
                            break;
                        }
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

        // Re-render the room list on every sync tick so ordering stays current.
        let mut _sync_tick: State<u64> = use_state(|| 0u64);
        use_tokio_track_watcher(
            crate::SYNC_RX.get().expect("SYNC_RX not initialized"),
            _sync_tick,
        );
        println!("[TIMING] HomePage re-render (sync_tick={})", *_sync_tick.read());

        let mut search: State<String> = use_state(String::new);
        // Narrow mode: search toggle
        let mut search_open: State<bool> = use_state(|| false);
        let filter: State<RoomFilter> = use_state(|| RoomFilter::All);

        let name_query =
            use_query(Query::new((), FetchUserDisplayName).stale_time(Duration::from_secs(3600)));

        // Progressive search state — each section updates independently.
        // Non-reactive AtomicU64 avoids the reactive re-trigger loop (see fix in this file).
        let search_ver: Arc<AtomicU64> = use_hook(|| Arc::new(AtomicU64::new(0)));
        let mut room_results: State<Vec<(String, String)>> = use_state(Vec::new);
        let mut user_results: State<Vec<(String, String, Option<String>)>> = use_state(Vec::new);
        let mut msg_results: State<Vec<MessageResult>> = use_state(Vec::new);
        let mut searching: State<bool> = use_state(|| false);
        let mut users_searching: State<bool> = use_state(|| false);
        let mut msgs_searching: State<bool> = use_state(|| false);
        // Pagination state for message search
        let mut msg_next_batch: State<Option<String>> = use_state(|| None);
        let mut msgs_loading_more: State<bool> = use_state(|| false);

        let search_text = search.read().to_lowercase();
        use_side_effect_with_deps(&search_text, {
            let search_ver = search_ver.clone();
            move |query: &String| {
                let query = query.clone();
                // Always bump version first so in-flight stale tasks are invalidated.
                let ver = search_ver.fetch_add(1, Ordering::Relaxed) + 1;
                let sv = search_ver.clone();
                if query.trim().is_empty() {
                    *room_results.write() = vec![];
                    *user_results.write() = vec![];
                    *msg_results.write() = vec![];
                    *searching.write() = false;
                    *users_searching.write() = false;
                    *msgs_searching.write() = false;
                    *msg_next_batch.write() = None;
                    *msgs_loading_more.write() = false;
                    return;
                }
                *searching.write() = true;
                let (delay_tx, delay_rx) = futures::channel::oneshot::channel::<()>();
                tokio::task::spawn(async move {
                    tokio::time::sleep(Duration::from_millis(400)).await;
                    let _ = delay_tx.send(());
                });
                spawn(async move {
                    let _ = delay_rx.await;
                    if sv.load(Ordering::Relaxed) != ver {
                        return;
                    }
                    *searching.write() = false;
                    // Reset pagination from any previous search.
                    *msg_next_batch.write() = None;
                    *msgs_loading_more.write() = false;

                    let Some(client) = CLIENT.get().cloned() else {
                        return;
                    };

                    // 1. Rooms — client-side, instant.
                    *room_results.write() = search_rooms_local(&client, &query)
                        .into_iter()
                        .map(|r| (r.room_id, r.display_name))
                        .collect();

                    // 2. Users — server-side, runs concurrently.
                    *users_searching.write() = true;
                    let sv_u = sv.clone();
                    let q_u = query.clone();
                    let client_u = client.clone();
                    let (tx_u, rx_u) = futures::channel::oneshot::channel();
                    tokio::task::spawn(async move {
                        let _ = tx_u.send(search_users_remote(client_u, q_u).await);
                    });
                    spawn(async move {
                        let results = rx_u.await.unwrap_or_default();
                        if sv_u.load(Ordering::Relaxed) == ver {
                            *user_results.write() = results
                                .into_iter()
                                .map(|u| (u.user_id, u.display_name, u.avatar_mxc))
                                .collect();
                            *users_searching.write() = false;
                        }
                    });

                    // 3. Messages — server-side, runs concurrently.
                    *msgs_searching.write() = true;
                    let sv_m = sv.clone();
                    let (tx_m, rx_m) = futures::channel::oneshot::channel();
                    tokio::task::spawn(async move {
                        let _ = tx_m.send(search_messages_remote(client, query, None).await);
                    });
                    spawn(async move {
                        let (results, next_batch) = rx_m.await.unwrap_or_default();
                        if sv_m.load(Ordering::Relaxed) == ver {
                            *msg_results.write() = results;
                            *msg_next_batch.write() = next_batch;
                            *msgs_searching.write() = false;
                        }
                    });
                });
            }
        });

        // ── Room list data (only used when search is inactive) ────────────────
        let name_reader = name_query.read();
        let initial = name_reader
            .state()
            .ok()
            .and_then(|n| n.chars().next())
            .map(|c| c.to_uppercase().to_string())
            .unwrap_or_else(|| "?".to_string());

        let mut rooms: Vec<matrix_sdk::Room> = CLIENT
            .get()
            .map(|c| {
                let mut r = c.joined_rooms();
                r.extend(c.invited_rooms());
                r
            })
            .unwrap_or_default();
        sort_rooms_by_recency(&mut rooms);

        let active_filter = filter.read().clone();
        let filtered_rooms: Vec<_> = rooms
            .into_iter()
            .filter(|r| active_filter.matches(r))
            .collect();
        let rooms_len = filtered_rooms.len();

        let initial_loading = CLIENT.get().is_none();
        let is_wide = WIDE_MODE.load(Ordering::Relaxed);
        let is_search_open = *search_open.read();
        let show_chips = *chips_visible.read();
        let is_searching = *searching.read();
        let is_users_searching = *users_searching.read();
        let is_msgs_searching = *msgs_searching.read();
        let is_msgs_loading_more = *msgs_loading_more.read();
        let msg_next_snap: Option<String> = msg_next_batch.read().clone();
        let search_active = !search_text.trim().is_empty();

        // Build the "Load more" footer element for the messages section.
        let load_more_msgs: Option<Element> = if is_msgs_loading_more {
            Some(section_loader(c))
        } else if let Some(next_token) = msg_next_snap {
            let sv = search_ver.clone();
            let ver = sv.load(Ordering::Relaxed);
            let query_for_more = search_text.clone();
            let client_lm = CLIENT.get().cloned();
            Some(
                rect()
                    .width(Size::fill())
                    .height(Size::px(44.))
                    .center()
                    .on_press(move |_| {
                        let Some(client) = client_lm.clone() else {
                            return;
                        };
                        *msgs_loading_more.write() = true;
                        let sv2 = sv.clone();
                        let q = query_for_more.clone();
                        let token = next_token.clone();
                        let (tx, rx) = futures::channel::oneshot::channel();
                        tokio::task::spawn(async move {
                            let _ = tx.send(search_messages_remote(client, q, Some(token)).await);
                        });
                        spawn(async move {
                            let (results, new_next) = rx.await.unwrap_or_default();
                            if sv2.load(Ordering::Relaxed) == ver {
                                msg_results.write().extend(results);
                                *msg_next_batch.write() = new_next;
                                *msgs_loading_more.write() = false;
                            }
                        });
                    })
                    .child(label().text("Load more").font_size(14.).color(c.primary))
                    .into_element(),
            )
        } else {
            None
        };

        // ── Search input builder ───────────────────────────────────────────────
        let mk_search = || {
            Input::new(search)
                .leading(
                    svg(freya_icons::lucide::search())
                        .color(c.on_surface_variant)
                        .width(Size::px(15.))
                        .height(Size::px(15.)),
                )
                .placeholder("Search conversations, people…")
                .width(Size::fill())
                .theme_colors(InputColorsThemePartial {
                    background: Some(Preference::Specific(Color::from(c.surface_container))),
                    focus_background: Some(Preference::Specific(Color::from(c.surface_container))),
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
                        // Reactions button (both modes)
                        .child(
                            rect()
                                .width(Size::px(48.))
                                .height(Size::px(48.))
                                .corner_radius(24.)
                                .center()
                                .on_press(|_| {
                                    let _ = RouterContext::get().push(crate::Route::ReactionsPage);
                                })
                                .child(
                                    svg(freya_icons::lucide::heart())
                                        .color(c.on_surface_variant)
                                        .width(Size::px(22.))
                                        .height(Size::px(22.)),
                                ),
                        )
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

        // ── Filter chip bar (hidden while search active) ───────────────────────
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
            // Filter chips — hidden when search is active, or on narrow until scrolled
            .child(if !search_active && (show_chips || is_wide) {
                filter_bar.into_element()
            } else {
                rect().into_element()
            })
            // Main content: search results or room list
            .child(if search_active {
                if is_searching {
                    rect()
                        .expanded()
                        .center()
                        .child(CircularLoader::new().size(36.))
                        .into_element()
                } else {
                    let rooms_snap = room_results.read().clone();
                    let users_snap = user_results.read().clone();
                    let msgs_snap = msg_results.read().clone();
                    build_search_results(
                        rooms_snap,
                        users_snap,
                        msgs_snap,
                        is_users_searching,
                        is_msgs_searching,
                        load_more_msgs,
                        c,
                    )
                }
            } else if initial_loading && rooms_len == 0 {
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
                            if room.latest_event().is_none() {
                                if let Some(rq) = crate::REQUESTER.get() {
                                    rq.fetch_room_previews(vec![room.room_id().to_owned()]);
                                }
                            }
                            rect()
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
    }
}

// ---------------------------------------------------------------------------
// Search results rendering (pure function — no hooks; tiles are components)
// ---------------------------------------------------------------------------

fn build_search_results(
    rooms: Vec<(String, String)>,
    users: Vec<(String, String, Option<String>)>,
    messages: Vec<MessageResult>,
    users_loading: bool,
    msgs_loading: bool,
    load_more_msgs: Option<Element>,
    c: crate::utils::const_values::AppColors,
) -> Element {
    let mut list = ScrollView::new()
        .width(Size::fill())
        .height(Size::flex(1.0));

    // ── Rooms section ──────────────────────────────────────────────────────
    list = list.child(section_header("Rooms", c));
    if rooms.is_empty() {
        list = list.child(empty_row("No rooms found", c));
    } else {
        for (room_id, display_name) in rooms {
            list = list.child(RoomSearchTile {
                room_id,
                display_name,
            });
        }
    }

    // ── People section ─────────────────────────────────────────────────────
    list = list.child(section_header("People", c));
    if users_loading {
        list = list.child(section_loader(c));
    } else if users.is_empty() {
        list = list.child(empty_row("No users found", c));
    } else {
        for (user_id, display_name, avatar_mxc) in users {
            list = list.child(UserSearchTile {
                user_id,
                display_name,
                avatar_mxc,
            });
        }
    }

    // ── Messages section ───────────────────────────────────────────────────
    list = list.child(section_header("Messages", c));
    if msgs_loading {
        list = list.child(section_loader(c));
    } else if messages.is_empty() {
        list = list.child(empty_row("No messages found", c));
    } else {
        for m in messages {
            list = list.child(MessageSearchTile {
                event_id: m.event_id,
                room_id: m.room_id,
                room_name: m.room_name,
                body: m.body,
                sender_display_name: m.sender_display_name,
                event_ts_ms: m.event_ts_ms,
                is_dm: m.is_dm,
            });
        }
        if let Some(footer) = load_more_msgs {
            list = list.child(footer);
        }
    }

    list.into_element()
}

fn section_header(title: &'static str, c: crate::utils::const_values::AppColors) -> Element {
    rect()
        .width(Size::fill())
        .padding(Gaps::new(12., 16., 4., 16.))
        .child(label().text(title).font_size(12.).color(c.on_surface_muted))
        .into()
}

fn section_loader(_c: crate::utils::const_values::AppColors) -> Element {
    rect()
        .width(Size::fill())
        .padding(Gaps::new(12., 16., 12., 16.))
        .center()
        .child(CircularLoader::new().size(24.))
        .into()
}

fn empty_row(text: &'static str, c: crate::utils::const_values::AppColors) -> Element {
    rect()
        .width(Size::fill())
        .padding(Gaps::new(6., 16., 6., 16.))
        .child(label().text(text).font_size(13.).color(c.on_surface_faint))
        .into()
}
