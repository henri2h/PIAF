use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;

use freya::prelude::*;

use super::search::{
    MessageResult, search_messages_remote, search_rooms_local, search_users_remote,
};
use super::search_tile::{MessageSearchTile, RoomSearchTile, UserSearchTile};
use crate::utils::const_values::AppColors;
use crate::utils::matrix::CLIENT;
use crate::utils::use_app_colors;

/// Progressive search results across rooms, people, and messages.
///
/// Each section loads independently: rooms resolve instantly (client-side
/// filter), people and messages hit the server concurrently. Input is
/// debounced by 400ms; a version counter discards results from stale
/// in-flight queries when the text changes again before they land.
pub struct SearchResults {
    pub search: State<String>,
}

impl PartialEq for SearchResults {
    fn eq(&self, _: &Self) -> bool {
        false
    }
}

impl Component for SearchResults {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let search = self.search;
        let query_text = search.read().to_lowercase();

        // Non-reactive counter: bumping it inside a `use_side_effect_with_deps`
        // closure must not itself be a reactive dependency, or it would
        // re-trigger the effect it's guarding.
        let search_ver: Arc<AtomicU64> = use_hook(|| Arc::new(AtomicU64::new(0)));
        let mut room_results: State<Vec<(String, String)>> = use_state(Vec::new);
        let mut user_results: State<Vec<(String, String, Option<String>)>> = use_state(Vec::new);
        let mut msg_results: State<Vec<MessageResult>> = use_state(Vec::new);
        let mut searching: State<bool> = use_state(|| false);
        let mut users_searching: State<bool> = use_state(|| false);
        let mut msgs_searching: State<bool> = use_state(|| false);
        let mut msg_next_batch: State<Option<String>> = use_state(|| None);
        let mut msgs_loading_more: State<bool> = use_state(|| false);

        use_side_effect_with_deps(&query_text, {
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

        if *searching.read() {
            return rect()
                .expanded()
                .center()
                .child(CircularLoader::new().size(36.))
                .into_element();
        }

        let load_more = load_more_footer(
            c,
            &search_ver,
            &query_text,
            msg_next_batch,
            msgs_loading_more,
            msg_results,
        );

        build_search_results(
            room_results.read().clone(),
            user_results.read().clone(),
            msg_results.read().clone(),
            *users_searching.read(),
            *msgs_searching.read(),
            load_more,
            c,
        )
    }
}

/// Builds the "Load more" footer for the messages section, or `None` when
/// there's nothing more to fetch.
fn load_more_footer(
    c: AppColors,
    search_ver: &Arc<AtomicU64>,
    query_text: &str,
    mut msg_next_batch: State<Option<String>>,
    mut msgs_loading_more: State<bool>,
    mut msg_results: State<Vec<MessageResult>>,
) -> Option<Element> {
    if *msgs_loading_more.read() {
        return Some(section_loader(c));
    }
    let next_token = msg_next_batch.read().clone()?;
    let sv = search_ver.clone();
    let ver = sv.load(Ordering::Relaxed);
    let query_for_more = query_text.to_string();
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
}

fn build_search_results(
    rooms: Vec<(String, String)>,
    users: Vec<(String, String, Option<String>)>,
    messages: Vec<MessageResult>,
    users_loading: bool,
    msgs_loading: bool,
    load_more_msgs: Option<Element>,
    c: AppColors,
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

fn section_header(title: &'static str, c: AppColors) -> Element {
    rect()
        .width(Size::fill())
        .padding(Gaps::new(12., 16., 4., 16.))
        .child(label().text(title).font_size(12.).color(c.on_surface_muted))
        .into()
}

fn section_loader(_c: AppColors) -> Element {
    rect()
        .width(Size::fill())
        .padding(Gaps::new(12., 16., 12., 16.))
        .center()
        .child(CircularLoader::new().size(24.))
        .into()
}

fn empty_row(text: &'static str, c: AppColors) -> Element {
    rect()
        .width(Size::fill())
        .padding(Gaps::new(6., 16., 6., 16.))
        .child(label().text(text).font_size(13.).color(c.on_surface_faint))
        .into()
}
