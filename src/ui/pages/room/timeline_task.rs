//! Tokio side of a room's timeline: builds it, applies diffs, runs actions.

use std::sync::Arc;

use eyeball_im::VectorDiff;
use futures::StreamExt;
use matrix_sdk::ruma::OwnedEventId;
use matrix_sdk::ruma::api::client::receipt::create_receipt::v3::ReceiptType;
use matrix_sdk::ruma::events::AnyMessageLikeEventContent;
use matrix_sdk::ruma::events::room::message::{
    RoomMessageEventContent, RoomMessageEventContentWithoutRelation,
};
use matrix_sdk_ui::timeline::{
    RoomExt, Timeline, TimelineEventFocusThreadMode, TimelineEventItemId, TimelineFocus,
    TimelineItem, TimelineReadReceiptTracking,
};
use tokio::sync::mpsc::{UnboundedReceiver, UnboundedSender, unbounded_channel};

use crate::utils::matrix::get_room;

const PAGE_SIZE: u16 = 20;
const FOCUS_CONTEXT_EVENTS: u16 = 50;

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

/// First snapshot: `(room name, is_dm, items)`.
pub(super) type TimelineInit = (String, bool, Vec<Arc<TimelineItem>>);

/// UI-side handle to a running timeline task. Dropping all clones stops it.
#[derive(Clone)]
pub(super) struct TimelineHandle {
    page_tx: Arc<UnboundedSender<()>>,
    action_tx: Arc<UnboundedSender<MsgAction>>,
}

impl PartialEq for TimelineHandle {
    fn eq(&self, other: &Self) -> bool {
        Arc::ptr_eq(&self.page_tx, &other.page_tx)
    }
}

impl TimelineHandle {
    /// Loads one more page of history.
    pub fn paginate(&self) {
        let _ = self.page_tx.send(());
    }

    pub fn actions(&self) -> Arc<UnboundedSender<MsgAction>> {
        self.action_tx.clone()
    }
}

/// Receivers the UI listens on.
pub(super) struct TimelineEvents {
    pub init: futures::channel::oneshot::Receiver<TimelineInit>,
    pub updates: UnboundedReceiver<Vec<Arc<TimelineItem>>>,
    pub typing: UnboundedReceiver<Vec<String>>,
    pub reached_start: UnboundedReceiver<()>,
}

pub(super) fn spawn_timeline(
    room_id: String,
    focus_event_id: Option<String>,
) -> (TimelineHandle, TimelineEvents) {
    let (page_tx, page_rx) = unbounded_channel();
    let (action_tx, action_rx) = unbounded_channel();
    let (update_tx, updates) = unbounded_channel();
    let (typing_tx, typing) = unbounded_channel();
    let (reached_start_tx, reached_start) = unbounded_channel();
    let (init_tx, init) = futures::channel::oneshot::channel();

    tokio::task::spawn(run(
        room_id,
        focus_event_id,
        init_tx,
        page_rx,
        action_rx,
        update_tx,
        typing_tx,
        reached_start_tx,
    ));

    let handle = TimelineHandle {
        page_tx: Arc::new(page_tx),
        action_tx: Arc::new(action_tx),
    };
    let events = TimelineEvents {
        init,
        updates,
        typing,
        reached_start,
    };
    (handle, events)
}

#[allow(clippy::too_many_arguments)]
async fn run(
    room_id: String,
    focus_event_id: Option<String>,
    init_tx: futures::channel::oneshot::Sender<TimelineInit>,
    mut page_rx: UnboundedReceiver<()>,
    mut action_rx: UnboundedReceiver<MsgAction>,
    update_tx: UnboundedSender<Vec<Arc<TimelineItem>>>,
    typing_tx: UnboundedSender<Vec<String>>,
    reached_start_tx: UnboundedSender<()>,
) {
    let Some(room) = get_room(&room_id) else {
        return;
    };
    let name = room
        .display_name()
        .await
        .map(|n| n.to_string())
        .unwrap_or_else(|_| room_id.clone());
    let dm = room.is_dm();

    let mut builder = room
        .timeline_builder()
        .track_read_marker_and_receipts(TimelineReadReceiptTracking::MessageLikeEvents);
    if let Some(eid) = focus_event_id.and_then(|s| OwnedEventId::try_from(s).ok()) {
        builder = builder.with_focus(TimelineFocus::Event {
            target: eid,
            num_context_events: FOCUS_CONTEXT_EVENTS,
            thread_mode: TimelineEventFocusThreadMode::Automatic {
                hide_threaded_events: false,
            },
        });
    }

    let Ok(timeline) = builder.build().await else {
        let _ = init_tx.send((name, dm, vec![]));
        return;
    };
    let (items, mut stream) = timeline.subscribe().await;
    let (_typing_guard, mut typing_broadcast) = room.subscribe_to_typing_notifications();

    let mut tl_items: Vec<Arc<TimelineItem>> = items.iter().cloned().collect();
    let _ = init_tx.send((name, dm, tl_items.clone()));

    let _ = timeline.mark_as_read(ReceiptType::Read).await;
    notify_sync();

    loop {
        tokio::select! {
            biased;
            page = page_rx.recv() => {
                if page.is_none() { break; }
                if timeline.paginate_backwards(PAGE_SIZE).await.unwrap_or(false) {
                    let _ = reached_start_tx.send(());
                }
            }
            action = action_rx.recv() => {
                let Some(action) = action else { break; };
                run_action(&timeline, &room, action).await;
            }
            typing = typing_broadcast.recv() => {
                if let Ok(users) = typing {
                    let names = users.into_iter().map(|uid| uid.localpart().to_string()).collect();
                    let _ = typing_tx.send(names);
                }
            }
            diffs = stream.next() => {
                let Some(diffs) = diffs else { break; };
                tracing::debug!(target: crate::logging::PERF, diffs = diffs.len(), items = tl_items.len(), "timeline update");
                for diff in diffs { apply_diff(&mut tl_items, diff); }
                let _ = update_tx.send(tl_items.clone());
            }
        }
    }
}

async fn run_action(timeline: &Timeline, room: &matrix_sdk::Room, action: MsgAction) {
    let event_id = |s: &str| OwnedEventId::try_from(s).ok();
    match action {
        MsgAction::React { event_id: eid, key } => {
            if let Some(eid) = event_id(&eid) {
                let _ = timeline
                    .toggle_reaction(&TimelineEventItemId::EventId(eid), &key)
                    .await;
            }
        }
        MsgAction::Delete { event_id: eid } => {
            if let Some(eid) = event_id(&eid) {
                let _ = room.redact(&eid, None, None).await;
            }
        }
        MsgAction::Send { text } => {
            let content =
                AnyMessageLikeEventContent::RoomMessage(RoomMessageEventContent::text_plain(text));
            let _ = timeline.send(content).await;
            notify_sync();
        }
        MsgAction::Edit {
            event_id: eid,
            text,
        } => {
            use matrix_sdk::room::edit::EditedContent;
            if let Some(eid) = event_id(&eid) {
                let content =
                    EditedContent::RoomMessage(RoomMessageEventContent::text_plain(text).into());
                let _ = timeline
                    .edit(&TimelineEventItemId::EventId(eid), content)
                    .await;
                notify_sync();
            }
        }
        MsgAction::Reply {
            reply_event_id,
            text,
        } => {
            if let Some(eid) = event_id(&reply_event_id) {
                let content = RoomMessageEventContentWithoutRelation::text_plain(text);
                let _ = timeline.send_reply(content, eid).await;
                notify_sync();
            }
        }
    }
}

fn notify_sync() {
    let _ = crate::SYNC_TX.get().expect("not initialized").send(());
}

pub(super) fn apply_diff(items: &mut Vec<Arc<TimelineItem>>, diff: VectorDiff<Arc<TimelineItem>>) {
    match diff {
        VectorDiff::Append { values } => items.extend(values),
        VectorDiff::Clear => items.clear(),
        VectorDiff::PushFront { value } => items.insert(0, value),
        VectorDiff::PushBack { value } => items.push(value),
        VectorDiff::PopFront => {
            if !items.is_empty() {
                items.remove(0);
            }
        }
        VectorDiff::PopBack => {
            items.pop();
        }
        VectorDiff::Insert { index, value } => items.insert(index, value),
        VectorDiff::Set { index, value } => {
            if index < items.len() {
                items[index] = value;
            }
        }
        VectorDiff::Remove { index } => {
            if index < items.len() {
                items.remove(index);
            }
        }
        VectorDiff::Truncate { length } => items.truncate(length),
        VectorDiff::Reset { values } => {
            items.clear();
            items.extend(values);
        }
    }
}
