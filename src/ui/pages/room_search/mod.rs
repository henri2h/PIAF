use std::sync::Arc;

use freya::prelude::*;

use crate::ui::components::IconButton;

use matrix_sdk::ruma::{
    OwnedRoomId,
    api::client::{filter::RoomEventFilter, search::search_events::v3 as search_v3},
    events::{AnyMessageLikeEvent, AnyTimelineEvent, MessageLikeEvent},
};

use crate::ui::components::{TopAppBar, TopAppBarTitle, search_input};
use crate::utils::use_app_colors;
use crate::utils::{format_timestamp, id_color, matrix::CLIENT, room_preview::message_body};

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
                on_back: Some(Arc::new(crate::app::navigation::go_back_or_home)),
                actions: vec![],
            })
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .padding(Gaps::new(6., 12., 6., 12.))
                    .background(c.surface)
                    .content(Content::Flex)
                    .cross_align(Alignment::Center)
                    .spacing(6.)
                    .child(
                        rect().width(Size::flex(1.)).child(
                            search_input(query_input, "Search messages…", c)
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
                                        let items = search_room_messages(&room_id, &query).await;
                                        *results.write() = items;
                                        *loading.write() = false;
                                    });
                                }),
                        ),
                    )
                    .maybe_child(if !query_input.read().is_empty() {
                        Some(
                            IconButton::new(
                                freya_icons::lucide::x(),
                                c.on_surface_faint,
                                move |_| {
                                    let mut query_input = query_input;
                                    let mut results = results;
                                    let mut has_searched = has_searched;
                                    *query_input.write() = String::new();
                                    *results.write() = vec![];
                                    *has_searched.write() = false;
                                },
                            )
                            .size(32., 16.)
                            .into_element(),
                        )
                    } else {
                        None
                    }),
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
                            .map(|item| SearchResultRow { item }.into_element()),
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

    let query = query.to_owned();

    crate::utils::on_tokio(async move {
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
                    let Some(body) = message_body(&msg.content.msgtype) else {
                        continue;
                    };
                    let sender = msg.sender.to_string();
                    let color = id_color(&sender);
                    items.push(SearchResultItem {
                        sender_name: sender,
                        sender_color: color,
                        body,
                        timestamp: format_timestamp(msg.origin_server_ts),
                    });
                }
                items
            }
            Err(_) => vec![],
        };
        items
    })
    .await
    .unwrap_or_default()
}
