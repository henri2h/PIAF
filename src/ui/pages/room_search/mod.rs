use std::sync::Arc;

use freya::prelude::*;
use freya_router::prelude::RouterContext;
use matrix_sdk::ruma::{
    OwnedRoomId,
    api::client::{filter::RoomEventFilter, search::search_events::v3 as search_v3},
    events::{AnyMessageLikeEvent, AnyTimelineEvent, MessageLikeEvent, room::message::MessageType},
};

use crate::ui::components::{TopAppBar, TopAppBarTitle};
use crate::utils::{format_timestamp, matrix::CLIENT, sender_color};
use crate::{Route, utils::use_app_colors};

mod search_result_row;
use search_result_row::{SearchResultItem, SearchResultRow};

#[derive(Clone, PartialEq)]
pub struct RoomSearch {
    pub room_id: String,
}

impl Component for RoomSearch {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let room_id = self.room_id.clone();
        let room_id_back = room_id.clone();

        let query_input: State<String> = use_state(String::new);
        let results: State<Vec<SearchResultItem>> = use_state(|| vec![]);
        let loading: State<bool> = use_state(|| false);
        let has_searched: State<bool> = use_state(|| false);

        let results_data = results.read().clone();
        let is_loading = *loading.read();
        let searched = *has_searched.read();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Search messages".to_string()),
                on_back: Some(Arc::new(move || {
                    let _ = RouterContext::get().push(Route::RoomPage {
                        room_id: room_id_back.clone(),
                    });
                })),
                actions: vec![],
            })
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .padding(Gaps::new(6., 12., 6., 12.))
                    .background(c.surface)
                    .child(
                        rect()
                            .horizontal()
                            .width(Size::fill())
                            .corner_radius(20.)
                            .background(c.surface_container)
                            .padding(Gaps::new(0., 12., 0., 12.))
                            .cross_align(Alignment::Center)
                            .spacing(6.)
                            .child(
                                svg(freya_icons::lucide::search())
                                    .color(c.on_surface_faint)
                                    .width(Size::px(16.))
                                    .height(Size::px(16.)),
                            )
                            .child(
                                Input::new(query_input)
                                    .flat()
                                    .placeholder("Search messages…")
                                    .width(Size::fill())
                                    .auto_focus(true)
                                    .on_submit(move |query: String| {
                                        if query.is_empty() {
                                            return;
                                        }
                                        let mut results = results;
                                        let mut loading = loading;
                                        let mut has_searched = has_searched;
                                        *loading.write() = true;
                                        *has_searched.write() = true;
                                        let room_id = room_id.clone();
                                        spawn(async move {
                                            let items =
                                                search_room_messages(&room_id, &query).await;
                                            *results.write() = items;
                                            *loading.write() = false;
                                        });
                                    }),
                            ),
                    ),
            )
            .child(if is_loading {
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .center()
                    .child(CircularLoader::new())
                    .into_element()
            } else if results_data.is_empty() {
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .center()
                    .child(
                        label()
                            .text(if searched {
                                "No results"
                            } else {
                                "Type to search, press Enter to confirm"
                            })
                            .color(c.on_surface_faint),
                    )
                    .into_element()
            } else {
                ScrollView::new()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .children(
                        results_data
                            .into_iter()
                            .map(|item| SearchResultRow { item }.into()),
                    )
                    .into_element()
            })
    }
}

async fn search_room_messages(room_id: &str, query: &str) -> Vec<SearchResultItem> {
    let Some(client) = CLIENT.get().cloned() else {
        return vec![];
    };
    let Ok(parsed_id) = OwnedRoomId::try_from(room_id) else {
        return vec![];
    };

    let (tx, rx) = futures::channel::oneshot::channel::<Vec<SearchResultItem>>();
    let query = query.to_owned();

    tokio::task::spawn(async move {
        let mut filter = RoomEventFilter::default();
        filter.rooms = Some(vec![parsed_id]);

        let mut criteria = search_v3::Criteria::new(query);
        criteria.filter = filter;

        let mut categories = search_v3::Categories::new();
        categories.room_events = Some(criteria);

        let items = match client.send(search_v3::Request::new(categories)).await {
            Ok(response) => {
                let mut items = Vec::new();
                for result in response.search_categories.room_events.results {
                    let Some(raw) = result.result else { continue };
                    let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                        MessageLikeEvent::Original(msg),
                    ))) = raw.deserialize()
                    else {
                        continue;
                    };
                    let body = match &msg.content.msgtype {
                        MessageType::Text(t) => t.body.clone(),
                        MessageType::Image(_) => "📷 Image".to_string(),
                        _ => continue,
                    };
                    let sender = msg.sender.to_string();
                    let color = sender_color(&sender);
                    let initial = sender
                        .chars()
                        .nth(1)
                        .unwrap_or('?')
                        .to_uppercase()
                        .next()
                        .unwrap_or('?');
                    items.push(SearchResultItem {
                        sender_name: sender,
                        sender_initial: initial,
                        sender_color: color,
                        body,
                        timestamp: format_timestamp(msg.origin_server_ts),
                    });
                }
                items
            }
            Err(_) => vec![],
        };
        let _ = tx.send(items);
    });

    rx.await.unwrap_or_default()
}
