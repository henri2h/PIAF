mod action_popup_overlay;
mod bookmark_picker_overlay;
mod compose_bar;
mod detail_modal;
mod message_action_popup;
mod message_row;
mod room_start_banner;
mod timeline;

use action_popup_overlay::action_popup_overlay;
use bookmark_picker_overlay::BookmarkPickerOverlay;
use compose_bar::ComposeBar;
use message_row::MessageRow;

use std::collections::HashMap;
use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};

const DEFAULT_MSG_HEIGHT: f32 = 60.0;

use freya::prelude::*;
use freya_router::prelude::RouterContext;
use futures::StreamExt;
use matrix_sdk::ruma::OwnedEventId;
use matrix_sdk::ruma::events::room::message::MessageType;
use matrix_sdk_ui::timeline::{
    RoomExt, TimelineDetails, TimelineEventFocusThreadMode, TimelineEventItemId, TimelineFocus,
    TimelineItem, TimelineItemContent, TimelineReadReceiptTracking,
};
use tokio::sync::mpsc::{UnboundedReceiver, UnboundedSender};

use crate::utils::format_timestamp;
use crate::utils::matrix::{get_room, my_user_id};
use crate::{
    ui::components::{
        MediaViewer, MediaViewerItem, TopAppBar, TopAppBarAction, TopAppBarTitle, UserPopupInfo,
        UserPopupOverlay, ViewerSource,
    },
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

#[derive(Debug)]
pub(super) enum MsgAction {
    React {
        event_id: String,
        key: String,
    },
    Delete {
        event_id: String,
    },
    Send {
        text: String,
    },
    Edit {
        event_id: String,
        text: String,
    },
    Reply {
        reply_event_id: String,
        text: String,
    },
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn spawn_timeline_task(
    room_id: String,
    initial_event_id: Option<String>,
    init_tx: futures::channel::oneshot::Sender<(String, bool, Vec<Arc<TimelineItem>>)>,
    mut page_rx: UnboundedReceiver<()>,
    mut action_rx: UnboundedReceiver<MsgAction>,
    update_tx: UnboundedSender<Vec<Arc<TimelineItem>>>,
    typing_tx: UnboundedSender<Vec<String>>,
    reached_start_tx: UnboundedSender<()>,
) {
    tokio::task::spawn(async move {
        let Some(room) = get_room(&room_id) else {
            return;
        };
        let name = room
            .display_name()
            .await
            .map(|n| n.to_string())
            .unwrap_or_else(|_| room_id.clone());
        let dm = room.is_dm();

        let focus_event_id: Option<OwnedEventId> = initial_event_id
            .as_deref()
            .and_then(|s| OwnedEventId::try_from(s).ok());

        let mut tl_builder = room
            .timeline_builder()
            .track_read_marker_and_receipts(TimelineReadReceiptTracking::MessageLikeEvents);
        if let Some(eid) = focus_event_id {
            tl_builder = tl_builder.with_focus(TimelineFocus::Event {
                target: eid,
                num_context_events: 50,
                thread_mode: TimelineEventFocusThreadMode::Automatic {
                    hide_threaded_events: false,
                },
            });
        }

        let Ok(timeline) = tl_builder.build().await else {
            let _ = init_tx.send((name, dm, vec![]));
            return;
        };
        let timeline = Arc::new(timeline);
        let (items, mut stream) = timeline.subscribe().await;
        let (_typing_guard, mut typing_broadcast) = room.subscribe_to_typing_notifications();

        let mut tl_items: Vec<Arc<TimelineItem>> = items.iter().cloned().collect();
        let _ = init_tx.send((name, dm, tl_items.clone()));

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
                                let _ = timeline.toggle_reaction(&TimelineEventItemId::EventId(eid), &key).await;
                            }
                        }
                        MsgAction::Delete { event_id } => {
                            if let Ok(eid) = OwnedEventId::try_from(event_id.as_str()) {
                                let _ = room.redact(&eid, None, None).await;
                            }
                        }
                        MsgAction::Send { text } => {
                            use matrix_sdk::ruma::events::AnyMessageLikeEventContent;
                            use matrix_sdk::ruma::events::room::message::RoomMessageEventContent;
                            let content = AnyMessageLikeEventContent::RoomMessage(RoomMessageEventContent::text_plain(text));
                            let _ = timeline.send(content).await;
                            let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
                        }
                        MsgAction::Edit { event_id, text } => {
                            use matrix_sdk::room::edit::EditedContent;
                            use matrix_sdk::ruma::events::room::message::RoomMessageEventContent;
                            if let Ok(eid) = OwnedEventId::try_from(event_id.as_str()) {
                                let content = EditedContent::RoomMessage(RoomMessageEventContent::text_plain(text).into());
                                let _ = timeline.edit(&TimelineEventItemId::EventId(eid), content).await;
                                let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
                            }
                        }
                        MsgAction::Reply { reply_event_id, text } => {
                            use matrix_sdk::ruma::events::room::message::RoomMessageEventContentWithoutRelation;
                            if let Ok(eid) = OwnedEventId::try_from(reply_event_id.as_str()) {
                                let content = RoomMessageEventContentWithoutRelation::text_plain(text);
                                let _ = timeline.send_reply(content, eid).await;
                                let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
                            }
                        }
                    }
                }
                typing_opt = typing_broadcast.recv() => {
                    if let Ok(users) = typing_opt {
                        let names: Vec<String> = users.into_iter().map(|uid| uid.localpart().to_string()).collect();
                        let _ = typing_tx.send(names);
                    }
                }
                diffs_opt = stream.next() => {
                    let Some(diffs) = diffs_opt else { break; };

                    for diff in diffs { timeline::apply_diff(&mut tl_items, diff); }
                    let _ = update_tx.send(tl_items.clone());
                }
            }
        }
    });
}

async fn run_smol_loop(
    mut reached_start_rx: UnboundedReceiver<()>,
    mut update_rx: UnboundedReceiver<Vec<Arc<TimelineItem>>>,
    mut typing_rx: UnboundedReceiver<Vec<String>>,
    mut at_start: State<bool>,
    mut paginating: State<bool>,
    mut auto_fill: State<bool>,
    mut messages: State<Vec<Arc<TimelineItem>>>,
    mut typing_users: State<Vec<String>>,
) {
    loop {
        tokio::select! {
            _ = reached_start_rx.recv() => {
                *at_start.write() = true;
                *paginating.write() = false;
                *auto_fill.write() = false;
            }
            update_opt = update_rx.recv() => {
                let Some(msgs) = update_opt else { break; };
                let old_len = messages.read().len();
                let new_len = msgs.len();

                // No scroll bookkeeping here: the view is anchored to the
                // newest message, so prepended history lands above without
                // moving anything on screen.
                *messages.write() = msgs;

                *paginating.write() = false;
                if new_len == old_len {
                    *auto_fill.write() = false;
                }
            }
            typing_opt = typing_rx.recv() => {
                let Some(users) = typing_opt else { break; };
                *typing_users.write() = users;
            }
        }
    }
}

fn try_auto_fill(
    vp_h: f32,
    content_h: f32,
    auto_fill: State<bool>,
    mut paginating: State<bool>,
    paginate_tx: &Arc<UnboundedSender<()>>,
) {
    let should_fill = *auto_fill.read();
    let is_paging = *paginating.read();
    if should_fill && !is_paging && vp_h > 0.0 && content_h > 0.0 && content_h < vp_h {
        *paginating.write() = true;
        let _ = paginate_tx.send(());
    }
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

        {
            let rid = room_id.clone();
            use_hook(move || {
                static MOUNTS: AtomicU64 = AtomicU64::new(0);
                let n = MOUNTS.fetch_add(1, Ordering::Relaxed) + 1;
                println!("[ROOMMOUNT] #{n} room={rid}");
            });
        }

        let mut messages: State<Vec<Arc<TimelineItem>>> = use_state(|| vec![]);
        let mut room_name: State<String> = use_state(|| room_id.clone());
        let mut is_dm: State<bool> = use_state(|| false);
        let mut loading: State<bool> = use_state(|| true);
        let mut paginating: State<bool> = use_state(|| false);
        let at_start: State<bool> = use_state(|| false);
        let edit_info: State<Option<(String, String)>> = use_state(|| None);
        let reply_info: State<Option<(String, String, String)>> = use_state(|| None);
        let image_viewer: State<Option<String>> = use_state(|| None);
        let detail_modal: State<Option<Arc<TimelineItem>>> = use_state(|| None);
        let action_popup_state: State<Option<Arc<TimelineItem>>> = use_state(|| None);
        let bookmark_picker: State<Option<crate::utils::bookmarks::BookmarkEntry>> =
            use_state(|| None);
        let user_popup: State<Option<UserPopupInfo>> = use_state(|| None);
        let mut content_height: State<f32> = use_state(|| 0.0f32);
        let mut auto_fill: State<bool> = use_state(|| false);
        let mut viewport_height: State<f32> = use_state(|| 0.0f32);
        let mut heights: State<HashMap<String, f32>> = use_state(HashMap::new);
        let typing_users: State<Vec<String>> = use_state(|| vec![]);
        // Holds the event ID to scroll to once the first layout completes.
        let mut pending_focus_event: State<Option<String>> = use_state(|| None);

        // Read any pending focus event for this room and clear the channel.
        // The channel is cleared regardless of whether the room_id matched — any room
        // opening supersedes a pending focus from an aborted navigation.
        let initial_event_id: Option<String> = crate::FOCUS_EVENT_RX.get().and_then(|rx| {
            rx.borrow().as_ref().and_then(|(rid, eid)| {
                if rid == &room_id {
                    Some(eid.clone())
                } else {
                    None
                }
            })
        });
        if crate::FOCUS_EVENT_RX
            .get()
            .map(|rx| rx.borrow().is_some())
            .unwrap_or(false)
        {
            if let Some(tx) = crate::FOCUS_EVENT_TX.get() {
                let _ = tx.send(None);
            }
        }

        let has_event_focus = initial_event_id.is_some();
        let mut scroll_controller = use_scroll_controller(|| ScrollConfig {
            default_vertical_position: if has_event_focus {
                ScrollPosition::Start
            } else {
                ScrollPosition::End
            },
            // The timeline measures its scroll position from the newest message
            // rather than the oldest, so backfilled history cannot drag the
            // conversation out from under the reader, and a room too short to
            // fill the screen rests on the composer instead of hanging from the
            // top. Everything this file used to do to fake that — re-snapping
            // after growth, pre-arming the End sentinel, holding position by
            // height deltas — is handled by the anchor now.
            vertical_anchor: ScrollAnchor::Bottom,
            ..Default::default()
        });

        let (paginate_tx, msg_action_tx): (
            Arc<UnboundedSender<()>>,
            Arc<UnboundedSender<MsgAction>>,
        ) = use_hook(|| {
            let room_id = room_id.clone();

            // Watch FOCUS_EVENT_RX for re-focus requests that arrive while this room
            // is already mounted (same-room search result navigation in wide mode).
            if let Some(rx) = crate::FOCUS_EVENT_RX.get() {
                let room_id_focus = room_id.clone();
                let mut rx_watch = rx.clone();
                let (refocus_tx, mut refocus_rx) = futures::channel::mpsc::unbounded::<String>();
                tokio::task::spawn(async move {
                    while rx_watch.changed().await.is_ok() {
                        if let Some((rid, eid)) = rx_watch.borrow().clone() {
                            if rid == room_id_focus {
                                let _ = refocus_tx.unbounded_send(eid);
                            }
                        }
                    }
                });
                spawn(async move {
                    while let Some(eid_str) = refocus_rx.next().await {
                        if let Ok(eid) = OwnedEventId::try_from(eid_str.as_str()) {
                            let offset: Option<i32> = {
                                let msgs = messages.read();
                                msgs.iter()
                                    .position(|item| {
                                        item.as_event().and_then(|ev| ev.event_id())
                                            == Some(eid.as_ref())
                                    })
                                    .map(|idx| {
                                        let h = heights.read();
                                        let px: f32 = msgs[..idx]
                                            .iter()
                                            .map(|mi| {
                                                mi.as_event()
                                                    .and_then(|ev| ev.event_id())
                                                    .map(|id| id.to_string())
                                                    .and_then(|id| h.get(&id))
                                                    .copied()
                                                    .unwrap_or(DEFAULT_MSG_HEIGHT)
                                            })
                                            .sum();
                                        px as i32
                                    })
                            };
                            if let Some(offset) = offset {
                                println!("[SCROLLSET] refocus -> y={offset}");
                                scroll_controller.scroll_to_y(offset);
                            }
                        }
                    }
                });
            }

            let (page_tx, page_rx) = tokio::sync::mpsc::unbounded_channel::<()>();
            let (action_tx, action_rx) = tokio::sync::mpsc::unbounded_channel::<MsgAction>();
            let (update_tx, update_rx) =
                tokio::sync::mpsc::unbounded_channel::<Vec<Arc<TimelineItem>>>();
            let (typing_tx, typing_rx) = tokio::sync::mpsc::unbounded_channel::<Vec<String>>();
            let (reached_start_tx, reached_start_rx) = tokio::sync::mpsc::unbounded_channel::<()>();

            spawn(async move {
                let (init_tx, init_rx) =
                    futures::channel::oneshot::channel::<(String, bool, Vec<Arc<TimelineItem>>)>();

                spawn_timeline_task(
                    room_id,
                    initial_event_id.clone(),
                    init_tx,
                    page_rx,
                    action_rx,
                    update_tx,
                    typing_tx,
                    reached_start_tx,
                );

                if let Ok((name, dm, msgs)) = init_rx.await {
                    *room_name.write() = name;
                    *is_dm.write() = dm;

                    // Defer scroll to after the first layout so actual row heights are used.
                    if let Some(ref eid_str) = initial_event_id {
                        *pending_focus_event.write() = Some(eid_str.clone());
                    }

                    *messages.write() = msgs;
                }
                *loading.write() = false;
                *auto_fill.write() = true;

                run_smol_loop(
                    reached_start_rx,
                    update_rx,
                    typing_rx,
                    at_start,
                    paginating,
                    auto_fill,
                    messages,
                    typing_users,
                )
                .await;
            });

            (Arc::new(page_tx), Arc::new(action_tx))
        });

        let paginate_tx_fill = paginate_tx.clone();
        let paginate_tx_inner = paginate_tx.clone();
        let paginate_tx_scroll = paginate_tx.clone();

        // Backward pagination hangs off the scroll position itself rather than
        // off input events, so wheel, touch drag, scrollbar and keyboard all
        // behave identically — `ScrollView` exposes no scroll callback to hook
        // instead. It used to be driven from `on_wheel` alone, which never
        // fires for touch: on Android, scrolling up could not load older
        // messages at all.
        //
        // Only the position is `read` (subscribing); everything else is
        // `peek`ed, so this runs when the view moves rather than whenever the
        // timeline changes size.
        use_side_effect(move || {
            let (_, y) = Into::<(i32, i32)>::into(scroll_controller);
            println!(
                "[SCROLLPOS] y={y} natural={:.0} vp={:.0}",
                *content_height.peek(),
                *viewport_height.peek(),
            );

            if y >= -400 && !*paginating.peek() && !*at_start.peek() {
                *paginating.write() = true;
                let _ = paginate_tx_scroll.send(());
            }
        });

        let (compose_key, initial_text) = match edit_info.read().as_ref() {
            Some((eid, body)) => (format!("edit-{eid}"), body.clone()),
            None => ("normal".to_string(), String::new()),
        };

        let msgs = messages.read().clone();
        let name = room_name.read().clone();
        let room_is_dm = *is_dm.read();
        let is_at_start = *at_start.read();
        let media_items: Vec<MediaViewerItem> = msgs
            .iter()
            .filter_map(|item| {
                let event = item.as_event()?;
                let event_id = event.event_id()?.to_string();
                let TimelineItemContent::MsgLike(msg_like) = event.content() else {
                    return None;
                };
                let msg = msg_like.as_message()?;
                let MessageType::Image(img) = msg.msgtype() else {
                    return None;
                };
                let sender = match event.sender_profile() {
                    TimelineDetails::Ready(p) => p
                        .display_name
                        .clone()
                        .unwrap_or_else(|| event.sender().to_string()),
                    _ => event.sender().to_string(),
                };
                let ts = format_timestamp(event.timestamp());
                let caption = {
                    let b = &img.body;
                    if b.starts_with("image")
                        || b.ends_with(".jpg")
                        || b.ends_with(".jpeg")
                        || b.ends_with(".png")
                        || b.ends_with(".gif")
                        || b.ends_with(".webp")
                    {
                        None
                    } else {
                        Some(b.clone()).filter(|s| !s.is_empty())
                    }
                };
                Some(MediaViewerItem {
                    key: event_id,
                    source: ViewerSource::Remote(img.source.clone()),
                    info: Some((sender, ts)),
                    caption,
                    blurhash: img.info.as_ref().and_then(|i| i.blurhash.clone()),
                    thumbnail_source: img.info.as_ref().and_then(|i| {
                        i.thumbnail_source
                            .as_ref()
                            .map(|s| ViewerSource::Remote(s.clone()))
                    }),
                })
            })
            .collect();

        let viewer_active = image_viewer.read().is_some();

        let is_loading = *loading.read();
        let is_paginating = *paginating.read();

        let typing_label = {
            let users = typing_users.read();
            match users.len() {
                0 => None,
                1 => Some(format!("{} is typing…", users[0])),
                2 => Some(format!("{} and {} are typing…", users[0], users[1])),
                _ => Some("Several people are typing…".to_string()),
            }
        };

        // Always return the same outer structure so Freya's reconciler stays stable.
        // When the viewer is active it occupies the whole inner area; otherwise the
        // normal layout (app bar + timeline + compose bar) is shown.
        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(if viewer_active {
                let paginate_tx_viewer = paginate_tx.clone();
                MediaViewer {
                    items: media_items,
                    selected_key: image_viewer,
                    on_load_more: Some(std::rc::Rc::new(move || {
                        let _ = paginate_tx_viewer.send(());
                    })),
                }
                .into_element()
            } else {
                rect()
                    .expanded()
                    .vertical()
                    .content(Content::Flex)
                    .child(detail_modal::DetailModalOverlay {
                        modal: detail_modal,
                        room_id: room_id.clone(),
                    })
                    .child(UserPopupOverlay { open: user_popup })
                    .child(action_popup_overlay(
                        action_popup_state,
                        room_id.clone(),
                        room_name.read().clone(),
                        my_user_id(),
                        msg_action_tx.clone(),
                        reply_info,
                        edit_info,
                        detail_modal,
                        bookmark_picker,
                        c,
                    ))
                    .child(BookmarkPickerOverlay {
                        pending: bookmark_picker,
                    })
                    .child({
                        let room_id_search = room_id.clone();
                        let room_id_settings = room_id.clone();
                        TopAppBar {
                            title: TopAppBarTitle::Room {
                                initial: name
                                    .chars()
                                    .next()
                                    .unwrap_or('?')
                                    .to_uppercase()
                                    .to_string(),
                                color: crate::utils::use_app_colors().primary,
                                room_id: room_id.clone(),
                                name: name.clone(),
                            },
                            on_back: if crate::WIDE_MODE.load(std::sync::atomic::Ordering::Relaxed)
                            {
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
                                        let _ =
                                            RouterContext::get().push(crate::Route::RoomSearch {
                                                room_id: room_id_search.clone(),
                                            });
                                    }),
                                },
                                TopAppBarAction::IconButton {
                                    icon: freya_icons::lucide::settings(),
                                    on_press: Arc::new(move || {
                                        let _ =
                                            RouterContext::get().push(crate::Route::RoomSettings {
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
                                if (*viewport_height.peek() - vp_h).abs() > 0.5 {
                                    println!(
                                        "[VIEWPORT] {:.0} -> {vp_h:.0} (natural={ch:.0})",
                                        *viewport_height.peek()
                                    );
                                }
                                *viewport_height.write() = vp_h;
                                try_auto_fill(
                                    vp_h,
                                    ch,
                                    auto_fill,
                                    paginating,
                                    &paginate_tx_fill,
                                );
                            })
                            .child(
                                ScrollView::new_controlled(scroll_controller)
                                    .width(Size::fill())
                                    .height(Size::fill())
                                    .child(
                                        rect()
                                            .vertical()
                                            .width(Size::fill())
                                            .child(
                                                rect()
                                            .vertical()
                                            .width(Size::fill())
                                            .padding(Gaps::new(4., 0., 4., 0.))
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
                                                        rect().into_element()
                                                    })
                                                    .into_element()
                                            })
                                            .on_sized(move |e: Event<SizedEventData>| {
                                                // Once item heights are populated after the
                                                // first layout, perform the deferred scroll.
                                                // Read then immediately drop the Ref before any
                                                // write — keeping it alive in an `if let`
                                                // condition would hold the borrow for the whole
                                                // block and cause a RefCell panic on .write().
                                                let pending_eid =
                                                    pending_focus_event.read().clone();
                                                if let Some(eid_str) = pending_eid {
                                                    *pending_focus_event.write() = None;
                                                    if let Ok(eid) =
                                                        OwnedEventId::try_from(eid_str.as_str())
                                                    {
                                                        let msgs = messages.read();
                                                        if let Some(idx) =
                                                            msgs.iter().position(|item| {
                                                                item.as_event()
                                                                    .and_then(|ev| ev.event_id())
                                                                    == Some(eid.as_ref())
                                                            })
                                                        {
                                                            let offset: f32 = {
                                                                let h = heights.read();
                                                                msgs[..idx]
                                                                    .iter()
                                                                    .map(|mi| {
                                                                        mi.as_event()
                                                                            .and_then(|ev| {
                                                                                ev.event_id()
                                                                            })
                                                                            .map(|id| {
                                                                                id.to_string()
                                                                            })
                                                                            .and_then(|id| {
                                                                                h.get(&id)
                                                                            })
                                                                            .copied()
                                                                            .unwrap_or(
                                                                                DEFAULT_MSG_HEIGHT,
                                                                            )
                                                                    })
                                                                    .sum()
                                                            };
                                                            println!(
                                                                "[SCROLLSET] pending-focus -> y={}",
                                                                offset as i32
                                                            );
                                                            scroll_controller
                                                                .scroll_to_y(offset as i32);
                                                        }
                                                    }
                                                }

                                                let new_h = e.inner_sizes.height;
                                                // Any change, not just growth: a prepend can also
                                                // shrink the timeline (the message that was first
                                                // loses its date separator), which leaves a stored
                                                // pixel offset pointing past the new bottom.
                                                let changed =
                                                    (new_h - *content_height.read()).abs() > 0.5;

                                                {
                                                    let prev_h = *content_height.read();
                                                    let vp_h = *viewport_height.read();
                                                    let (_, y) =
                                                        Into::<(i32, i32)>::into(scroll_controller);
                                                    if (new_h - prev_h).abs() > 0.5 {
                                                        println!(
                                                            "[SHIFT] natural {prev_h:.0}->{new_h:.0} d={:+.0} box={:.0} vp={vp_h:.0} y={y}",
                                                            new_h - prev_h,
                                                            e.area.height(),
                                                        );
                                                    }
                                                }

                                                // Guarded so an unconditional write does not
                                                // schedule a render for every layout pass.
                                                if changed {
                                                    *content_height.write() = new_h;
                                                }
                                                let vp_h = *viewport_height.read();

                                                try_auto_fill(
                                                    vp_h,
                                                    new_h,
                                                    auto_fill,
                                                    paginating,
                                                    &paginate_tx_inner,
                                                );
                                            })
                                            .children({
                                                let date_labels: Vec<Option<String>> = (0..msgs
                                                    .len())
                                                    .map(|i| timeline::date_label_for(&msgs, i))
                                                    .collect();
                                                let my_uid = my_user_id();
                                                let room_id_rows = room_id.clone();
                                                let msg_action_tx_rows = msg_action_tx.clone();
                                                msgs.into_iter()
                                                    .zip(date_labels.into_iter())
                                                    .map(move |(item, date_label)| {
                                                        // Virtual items (date dividers, read
                                                        // markers) have no event id. Keying them
                                                        // by position meant every prepend shifted
                                                        // the keys, so rows were recycled into the
                                                        // wrong elements and the measured heights
                                                        // were attributed to the wrong messages.
                                                        // `unique_id` is stable across prepends.
                                                        let key = item
                                                            .as_event()
                                                            .and_then(|e| e.event_id())
                                                            .map(|id| id.to_string())
                                                            .unwrap_or_else(|| {
                                                                format!(
                                                                    "virtual-{}",
                                                                    item.unique_id().0
                                                                )
                                                            });
                                                        let my_uid = my_uid.clone();
                                                        rect()
                                                            .key(key.clone())
                                                            .width(Size::fill())
                                                            .on_sized(
                                                                move |e: Event<SizedEventData>| {
                                                                    let h = e.area.height();
                                                                    let old = heights
                                                                        .read()
                                                                        .get(&key)
                                                                        .copied();
                                                                    if old != Some(h) {
                                                                        if let Some(old_h) = old {
                                                                            println!(
                                                                                "[ROWGROW] {key} {old_h:.0}->{h:.0} d={:+.0}",
                                                                                h - old_h
                                                                            );
                                                                        }
                                                                        heights
                                                                            .write()
                                                                            .insert(key.clone(), h);
                                                                    }
                                                                },
                                                            )
                                                            .child(MessageRow {
                                                                room_id: room_id_rows.clone(),
                                                                item,
                                                                date_label,
                                                                my_user_id: my_uid,
                                                                action_tx: msg_action_tx_rows
                                                                    .clone(),
                                                                image_viewer,
                                                                action_popup: action_popup_state,
                                                                detail_modal,
                                                                is_dm: room_is_dm,
                                                                user_popup,
                                                            })
                                                            .into_element()
                                                    })
                                            }),
                                            ),
                                    ),
                            )
                            .into_element()
                    })
                    .child(
                        rect()
                            .vertical()
                            .width(Size::fill())
                            .maybe_child(if viewer_active { None } else { typing_label }.map(
                                |text| {
                                    rect()
                                        .width(Size::fill())
                                        .padding(Gaps::new(2., 16., 2., 16.))
                                        .child(
                                            label()
                                                .text(text)
                                                .font_size(12.)
                                                .color(c.on_surface_variant),
                                        )
                                },
                            ))
                            .maybe_child(if viewer_active {
                                None
                            } else {
                                Some(rect().key(compose_key).width(Size::fill()).child(
                                    ComposeBar {
                                        initial_text,
                                        edit_info,
                                        reply_info,
                                        room_id: room_id.clone(),
                                        action_tx: msg_action_tx.clone(),
                                    },
                                ))
                            })
                            .into_element(),
                    )
                    .into_element()
            })
    }
}
