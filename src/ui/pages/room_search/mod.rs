use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;

use freya::prelude::*;

use crate::ui::components::{SearchField, empty_state, loading_state, search_app_bar};
use crate::utils::room_search::{self, Hit};
use crate::utils::{on_tokio, use_app_colors};

mod search_result_row;
use search_result_row::SearchResultRow;

/// Pause after the last keystroke before searching.
const DEBOUNCE: Duration = Duration::from_millis(400);

/// Searching one room's messages, as you type (encrypted rooms are searched
/// on the device: see `utils::room_search`).
#[derive(Clone, PartialEq)]
pub struct RoomSearch {
    pub room_id: String,
}

impl Component for RoomSearch {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let query: State<String> = use_state(String::new);
        let results: State<Vec<Hit>> = use_state(Vec::new);
        let loading = use_state(|| false);
        // The query the results are for (`None`: nothing searched yet).
        let searched: State<Option<String>> = use_state(|| None);
        let dismiss = use_state(|| false);
        // Bumped per query: a slower, older search never overwrites a newer one.
        let version: Arc<AtomicU64> = use_hook(|| Arc::new(AtomicU64::new(0)));

        let room_id = self.room_id.clone();
        let run = {
            let version = version.clone();
            move |text: String, delay: bool| {
                let (mut results, mut searched, mut loading) = (results, searched, loading);
                let ver = version.fetch_add(1, Ordering::Relaxed) + 1;
                let text = text.trim().to_string();
                if text.is_empty() {
                    results.set(vec![]);
                    searched.set(None);
                    loading.set(false);
                    return;
                }
                loading.set(true);
                let (room_id, version) = (room_id.clone(), version.clone());
                spawn(async move {
                    if delay {
                        timer(DEBOUNCE).await;
                    }
                    if version.load(Ordering::Relaxed) != ver {
                        return;
                    }
                    let q = text.clone();
                    let hits = on_tokio(async move { room_search::search(&room_id, &q).await })
                        .await
                        .unwrap_or_default();
                    if version.load(Ordering::Relaxed) == ver {
                        results.set(hits);
                        searched.set(Some(text));
                        loading.set(false);
                    }
                });
            }
        };
        {
            let run = run.clone();
            use_side_effect_with_deps(&query.read().clone(), move |text: &String| {
                run(text.clone(), true)
            });
        }

        let hits = results.read().clone();
        let searched_for = searched.read().clone();
        let content = if *loading.read() && hits.is_empty() {
            loading_state(Some("Searching…"), c).into_element()
        } else if let Some(text) = searched_for.filter(|_| !hits.is_empty()) {
            let room_id = self.room_id.clone();
            ScrollView::new()
                .width(Size::fill())
                .height(Size::flex(1.))
                .children(hits.into_iter().map(|hit| {
                    rect()
                        .key(hit.event_id.as_str())
                        .width(Size::fill())
                        .child(SearchResultRow {
                            room_id: room_id.clone(),
                            hit,
                            query: text.clone(),
                        })
                        .into_element()
                }))
                .into_element()
        } else if searched.read().is_some() {
            empty_state(
                freya_icons::lucide::search_x(),
                "No messages found",
                Some("Try other words"),
                c,
            )
            .into_element()
        } else {
            empty_state(
                freya_icons::lucide::message_square_text(),
                "Search this conversation",
                Some("Encrypted messages are searched on this device"),
                c,
            )
            .into_element()
        };

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(search_app_bar(
                SearchField {
                    value: query,
                    placeholder: "Search messages",
                    on_submit: EventHandler::new(move |text: String| run(text, false)),
                    dismiss,
                    auto_focus: true,
                    font_size: 18.,
                },
                c,
            ))
            .child(content)
    }
}
