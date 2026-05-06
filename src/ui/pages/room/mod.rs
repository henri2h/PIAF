mod action_popup_overlay;
mod compose_bar;
mod detail_modal;
mod image_viewer_overlay;
mod message_action_popup;
mod message_row;
mod room_start_banner;
mod timeline;

use action_popup_overlay::action_popup_overlay;
use compose_bar::ComposeBar;
use image_viewer_overlay::image_viewer_overlay;
use message_row::MessageRow;

use std::collections::HashMap;
use std::sync::Arc;

const DEFAULT_MSG_HEIGHT: f32 = 60.0;

use eyeball_im::VectorDiff;
use freya::prelude::*;
use freya_router::prelude::RouterContext;
use futures::StreamExt;
use matrix_sdk::ruma::{OwnedEventId, RoomId};
use matrix_sdk_ui::timeline::{RoomExt, TimelineEventItemId};
use tokio::sync::mpsc::UnboundedSender;

use crate::utils::matrix::CLIENT;
use crate::{
    ui::components::{TopAppBar, TopAppBarAction, TopAppBarTitle},
    utils::use_app_colors,
};

// ---------------------------------------------------------------------------
// Shared types
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq)]
pub(super) struct ReactionSender {
    pub user_id: String,
    pub display: String,
    pub timestamp: String,
}

#[derive(Debug, Clone, PartialEq)]
pub(super) struct Reaction {
    pub key: String,
    pub count: usize,
    pub reacted_by_me: bool,
    pub senders: Vec<ReactionSender>,
}

#[derive(Debug, Clone, PartialEq)]
pub(super) enum MessageContent {
    Text(String),
    Image { key: String, bytes: Vec<u8>, caption: Option<String> },
    Notice(String),
    ReadMarker,
}

#[derive(Debug, Clone, PartialEq)]
pub(super) struct MessageItem {
    pub event_id: Option<String>,
    pub date_key: String,
    pub date_label: Option<String>,
    pub reply_to: Option<(String, String)>,
    pub sender: String,
    pub sender_name: String,
    pub sender_initial: char,
    pub sender_color: (u8, u8, u8),
    pub content: MessageContent,
    pub timestamp: String,
    pub is_me: bool,
    pub read_receipts: Vec<(String, String)>,
    /// (user_id, display_fallback, timestamp)
    pub seen_by: Vec<(String, String, String)>,
    pub fully_read: bool,
    pub reactions: Vec<Reaction>,
}

#[derive(Clone)]
pub(super) struct TimelineHandle(pub Arc<matrix_sdk_ui::timeline::Timeline>);

impl PartialEq for TimelineHandle {
    fn eq(&self, other: &Self) -> bool {
        Arc::ptr_eq(&self.0, &other.0)
    }
}

#[derive(Debug)]
pub(super) enum MsgAction {
    React { event_id: String, key: String },
    Delete { event_id: String },
}

// ---------------------------------------------------------------------------
// RoomPage
// ---------------------------------------------------------------------------

#[derive(PartialEq)]
pub struct RoomPage {
    pub room_id: String,
}

impl Component for RoomPage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let room_id = self.room_id.clone();

        let mut messages: State<Vec<MessageItem>> = use_state(|| vec![]);
        let mut room_name: State<String> = use_state(|| room_id.clone());
        let mut loading: State<bool> = use_state(|| true);
        let mut paginating: State<bool> = use_state(|| false);
        let mut at_start: State<bool> = use_state(|| false);
        let mut pinned_to_bottom: State<bool> = use_state(|| true);
        let mut timeline_handle: State<Option<TimelineHandle>> = use_state(|| None);
        let edit_info: State<Option<(String, String)>> = use_state(|| None);
        let reply_info: State<Option<(String, String, String)>> = use_state(|| None);
        let image_viewer: State<Option<(String, Vec<u8>)>> = use_state(|| None);
        let detail_modal: State<Option<MessageItem>> = use_state(|| None);
        let action_popup_state: State<Option<(Area, MessageItem)>> = use_state(|| None);
        let mut content_height: State<f32> = use_state(|| 0.0f32);
        let mut anchor_info: State<Option<(i32, f32)>> = use_state(|| None);
        let mut auto_fill: State<bool> = use_state(|| false);
        let mut viewport_height: State<f32> = use_state(|| 0.0f32);
        let mut heights: State<HashMap<String, f32>> = use_state(HashMap::new);
        let mut typing_users: State<Vec<String>> = use_state(|| vec![]);

        let mut scroll_controller = use_scroll_controller(|| ScrollConfig {
            default_vertical_position: ScrollPosition::End,
            ..Default::default()
        });

        let (paginate_tx, msg_action_tx): (
            Arc<UnboundedSender<()>>,
            Arc<UnboundedSender<MsgAction>>,
        ) = use_hook(|| {
            let room_id = room_id.clone();
            let mut scroll_controller = scroll_controller;
            let heights = heights;

            let (page_tx, mut page_rx) = tokio::sync::mpsc::unbounded_channel::<()>();
            let (action_tx, mut action_rx) = tokio::sync::mpsc::unbounded_channel::<MsgAction>();
            let (update_tx, mut update_rx) =
                tokio::sync::mpsc::unbounded_channel::<(Vec<MessageItem>, bool)>();
            let (typing_tx, mut typing_rx) = tokio::sync::mpsc::unbounded_channel::<Vec<String>>();
            let (reached_start_tx, mut reached_start_rx) =
                tokio::sync::mpsc::unbounded_channel::<()>();

            spawn(async move {
                let (init_tx, init_rx) = tokio::sync::oneshot::channel::<(
                    String,
                    Vec<MessageItem>,
                    Option<Arc<matrix_sdk_ui::timeline::Timeline>>,
                )>();

                if let Some(client) = CLIENT.get().cloned() {
                    let room_id2 = room_id.clone();
                    tokio::task::spawn(async move {
                        let Ok(parsed_id) = RoomId::parse(&room_id2) else {
                            return;
                        };
                        let Some(room) = client.get_room(&parsed_id) else {
                            return;
                        };
                        let name = room
                            .display_name()
                            .await
                            .map(|n| n.to_string())
                            .unwrap_or_else(|_| room_id2.clone());

                        let my_user_id = client.user_id().map(|id| id.to_string());

                        let Ok(timeline) = room.timeline_builder().build().await else {
                            let _ = init_tx.send((name, vec![], None));
                            return;
                        };
                        let timeline = Arc::new(timeline);
                        let (items, mut stream) = timeline.subscribe().await;
                        let (_typing_guard, mut typing_broadcast) =
                            room.subscribe_to_typing_notifications();

                        let my_id = my_user_id.as_deref();
                        let mut img_cache: HashMap<String, Vec<u8>> = HashMap::new();
                        let mut msgs = Vec::new();
                        for item in items.iter() {
                            if let Some(m) =
                                timeline::item_to_message(item, my_id, &client, &mut img_cache)
                                    .await
                            {
                                msgs.push(m);
                            }
                        }
                        timeline::assign_date_labels(&mut msgs);
                        timeline::assign_read_receipts(&mut msgs, my_id);
                        let _ = init_tx.send((name, msgs, Some(timeline.clone())));

                        use matrix_sdk::ruma::api::client::receipt::create_receipt::v3::ReceiptType;
                        let _ = timeline.mark_as_read(ReceiptType::Read).await;
                        let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));

                        loop {
                            tokio::select! {
                                biased;
                                page_opt = page_rx.recv() => {
                                    if page_opt.is_none() { break; }
                                    if timeline.paginate_backwards(20).await.unwrap_or(false) {
                                        let _ = reached_start_tx.send(());
                                    }
                                }
                                action_opt = action_rx.recv() => {
                                    let Some(action) = action_opt else { break; };
                                    match action {
                                        MsgAction::React { event_id, key } => {
                                            if let Ok(eid) = OwnedEventId::try_from(event_id.as_str()) {
                                                let item_id = TimelineEventItemId::EventId(eid);
                                                let _ = timeline.toggle_reaction(&item_id, &key).await;
                                            }
                                        }
                                        MsgAction::Delete { event_id } => {
                                            if let Ok(eid) = OwnedEventId::try_from(event_id.as_str()) {
                                                let _ = room.redact(&eid, None, None).await;
                                            }
                                        }
                                    }
                                }
                                typing_opt = typing_broadcast.recv() => {
                                    if let Ok(users) = typing_opt {
                                        let names: Vec<String> = users
                                            .into_iter()
                                            .map(|uid| uid.localpart().to_string())
                                            .collect();
                                        let _ = typing_tx.send(names);
                                    }
                                }
                                diffs_opt = stream.next() => {
                                    let Some(diffs) = diffs_opt else { break; };
                                    let has_new = diffs
                                        .iter()
                                        .any(|d| matches!(d, VectorDiff::PushBack { .. }));
                                    let items = timeline.items().await;
                                    let mut msgs = Vec::new();
                                    for item in items.iter() {
                                        if let Some(m) = timeline::item_to_message(
                                            item, my_id, &client, &mut img_cache,
                                        ).await {
                                            msgs.push(m);
                                        }
                                    }
                                    timeline::assign_date_labels(&mut msgs);
                                    timeline::assign_read_receipts(&mut msgs, my_id);
                                    let _ = update_tx.send((msgs, has_new));
                                }
                            }
                        }
                    });
                }

                if let Ok((name, msgs, tl)) = init_rx.await {
                    *room_name.write() = name;
                    *messages.write() = msgs;
                    *timeline_handle.write() = tl.map(TimelineHandle);
                }
                *loading.write() = false;
                *auto_fill.write() = true;

                loop {
                    tokio::select! {
                        _ = reached_start_rx.recv() => {
                            *at_start.write() = true;
                        }
                        update_opt = update_rx.recv() => {
                            let Some((msgs, has_new)) = update_opt else { break; };
                            let old_len = messages.read().len();
                            let new_len = msgs.len();
                            let prepend_count = new_len.saturating_sub(old_len);

                            if prepend_count > 0 && !has_new {
                                let estimated: f32 = {
                                    let h = heights.read();
                                    msgs[..prepend_count]
                                        .iter()
                                        .map(|m| {
                                            m.event_id
                                                .as_ref()
                                                .and_then(|id| h.get(id))
                                                .copied()
                                                .unwrap_or(DEFAULT_MSG_HEIGHT)
                                        })
                                        .sum()
                                };
                                let (_, y) = scroll_controller.into();
                                *messages.write() = msgs;
                                scroll_controller.scroll_to_y(y - estimated as i32);
                            } else {
                                *messages.write() = msgs;
                            }

                            *paginating.write() = false;
                            if new_len == old_len {
                                *auto_fill.write() = false;
                            }
                            if has_new && *pinned_to_bottom.read() {
                                scroll_controller
                                    .scroll_to(ScrollPosition::End, Direction::Vertical);
                            }
                        }
                        typing_opt = typing_rx.recv() => {
                            let Some(users) = typing_opt else { break; };
                            *typing_users.write() = users;
                        }
                    }
                }
            });

            (Arc::new(page_tx), Arc::new(action_tx))
        });

        let paginate_tx_wheel = paginate_tx.clone();
        let paginate_tx_btn = paginate_tx.clone();
        let paginate_tx_fill = paginate_tx.clone();
        let paginate_tx_inner = paginate_tx.clone();

        let (compose_key, initial_text) = match edit_info.read().as_ref() {
            Some((eid, body)) => (format!("edit-{eid}"), body.clone()),
            None => ("normal".to_string(), String::new()),
        };

        let msgs = messages.read().clone();
        let name = room_name.read().clone();
        let is_at_start = *at_start.read();
        let viewer_state = image_viewer.read().clone();
        let is_loading = *loading.read();
        let is_paginating = *paginating.read();
        let tl = timeline_handle.read().clone();
        let typing_label = {
            let users = typing_users.read();
            match users.len() {
                0 => None,
                1 => Some(format!("{} is typing…", users[0])),
                2 => Some(format!("{} and {} are typing…", users[0], users[1])),
                _ => Some("Several people are typing…".to_string()),
            }
        };

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .maybe_child(
                detail_modal
                    .read()
                    .clone()
                    .map(|msg| detail_modal::detail_modal_overlay(msg, room_id.clone(), detail_modal, c)),
            )
            .maybe_child(action_popup_state.read().clone().map(|(area, msg)| {
                action_popup_overlay(
                    area,
                    msg,
                    action_popup_state,
                    msg_action_tx.clone(),
                    reply_info,
                    edit_info,
                    detail_modal,
                    c,
                )
            }))
            .maybe_child(
                viewer_state.map(|(key, bytes)| image_viewer_overlay(key, bytes, image_viewer)),
            )
            .child({
                let room_id_search = room_id.clone();
                let room_id_settings = room_id.clone();
                TopAppBar {
                    title: TopAppBarTitle::Text(name.clone()),
                    on_back: if crate::WIDE_MODE.load(std::sync::atomic::Ordering::Relaxed) {
                        None
                    } else {
                        Some(Arc::new(|| {
                            let _ = RouterContext::get().push(crate::Route::HomePage);
                        }))
                    },
                    actions: vec![
                        TopAppBarAction::IconButton {
                            icon: freya_icons::lucide::search(),
                            on_press: Arc::new(move || {
                                let _ = RouterContext::get().push(crate::Route::RoomSearch {
                                    room_id: room_id_search.clone(),
                                });
                            }),
                        },
                        TopAppBarAction::IconButton {
                            icon: freya_icons::lucide::settings(),
                            on_press: Arc::new(move || {
                                let _ = RouterContext::get().push(crate::Route::RoomSettings {
                                    room_id: room_id_settings.clone(),
                                });
                            }),
                        },
                    ],
                }
            })
            .child(if is_loading {
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .center()
                    .child(CircularLoader::new())
                    .into_element()
            } else {
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .on_sized(move |e: Event<SizedEventData>| {
                        let vp_h = e.area.height();
                        let ch = *content_height.read();
                        let should_fill = *auto_fill.read();
                        let is_paging = *paginating.read();
                        *viewport_height.write() = vp_h;
                        if should_fill && !is_paging && vp_h > 0.0 && ch > 0.0 && ch < vp_h {
                            let (_, y) = Into::<(i32, i32)>::into(scroll_controller);
                            *anchor_info.write() = Some((y, ch));
                            *paginating.write() = true;
                            let _ = paginate_tx_fill.send(());
                        }
                    })
                    .child(
                        ScrollView::new_controlled(scroll_controller)
                            .width(Size::fill())
                            .height(Size::fill())
                            .child(
                                rect()
                                    .vertical()
                                    .width(Size::fill())
                                    .padding(Gaps::new(4., 0., 4., 0.))
                                    .on_wheel(move |e: Event<WheelEventData>| {
                                        let (_, y) = Into::<(i32, i32)>::into(scroll_controller);
                                        if y >= -400 && e.delta_y > 0. && !*paginating.read() {
                                            *paginating.write() = true;
                                            *pinned_to_bottom.write() = false;
                                            *anchor_info.write() =
                                                Some((y, *content_height.read()));
                                            let _ = paginate_tx_wheel.send(());
                                        }
                                    })
                                    .child(if is_at_start {
                                        room_start_banner::RoomStartBanner {
                                            room_id: room_id.clone(),
                                            room_name: name.clone(),
                                            c,
                                        }
                                        .into_element()
                                    } else {
                                        rect()
                                            .center()
                                            .width(Size::fill())
                                            .padding(Gaps::new_all(8.))
                                            .child(if is_paginating {
                                                CircularLoader::new().into_element()
                                            } else {
                                                Button::new()
                                                    .on_press(move |_| {
                                                        let (_, y) = Into::<(i32, i32)>::into(
                                                            scroll_controller,
                                                        );
                                                        *paginating.write() = true;
                                                        *pinned_to_bottom.write() = false;
                                                        *anchor_info.write() =
                                                            Some((y, *content_height.read()));
                                                        let _ = paginate_tx_btn.send(());
                                                    })
                                                    .child("Load older messages")
                                                    .into_element()
                                            })
                                            .into_element()
                                    })
                                    .on_sized(move |e: Event<SizedEventData>| {
                                        let new_h = e.inner_sizes.height;
                                        let maybe_anchor = *anchor_info.read();
                                        if let Some((old_y, old_h)) = maybe_anchor {
                                            let delta = new_h - old_h;
                                            if delta > 1.0 {
                                                scroll_controller.scroll_to_y(old_y - delta as i32);
                                                *anchor_info.write() = None;
                                            }
                                        }
                                        *content_height.write() = new_h;
                                        let vp_h = *viewport_height.read();
                                        let should_fill = *auto_fill.read();
                                        let is_paging = *paginating.read();
                                        if should_fill
                                            && !is_paging
                                            && vp_h > 0.0
                                            && new_h > 0.0
                                            && new_h < vp_h
                                        {
                                            let (_, y) =
                                                Into::<(i32, i32)>::into(scroll_controller);
                                            *anchor_info.write() = Some((y, new_h));
                                            *paginating.write() = true;
                                            let _ = paginate_tx_inner.send(());
                                        }
                                    })
                                    .children(msgs.into_iter().map(|msg| {
                                        let key = msg.event_id.clone().unwrap_or_else(|| {
                                            format!("{}:{}", msg.sender, msg.timestamp)
                                        });
                                        rect()
                                            .key(key.clone())
                                            .width(Size::fill())
                                            .on_sized(move |e: Event<SizedEventData>| {
                                                let h = e.area.height();
                                                let old = heights.read().get(&key).copied();
                                                if old != Some(h) {
                                                    heights.write().insert(key.clone(), h);
                                                }
                                            })
                                            .child(MessageRow {
                                                room_id: room_id.clone(),
                                                msg,
                                                action_tx: msg_action_tx.clone(),
                                                image_viewer,
                                                action_popup: action_popup_state,
                                                detail_modal,
                                            })
                                            .into()
                                    })),
                            ),
                    )
                    .into_element()
            })
            .child(
                rect()
                    .vertical()
                    .width(Size::fill())
                    .maybe_child(typing_label.map(|text| {
                        rect()
                            .width(Size::fill())
                            .padding(Gaps::new(2., 16., 2., 16.))
                            .child(
                                label()
                                    .text(text)
                                    .font_size(12.)
                                    .color(c.on_surface_variant),
                            )
                    }))
                    .child(
                        rect()
                            .key(compose_key)
                            .width(Size::fill())
                            .child(ComposeBar {
                                initial_text,
                                edit_info,
                                reply_info,
                                room_id: room_id.clone(),
                                timeline: tl,
                            }),
                    )
                    .into_element(),
            )
    }
}
