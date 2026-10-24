//! Tokio side of a room's timeline: builds it, applies diffs, runs actions.

use std::collections::HashSet;
use std::sync::Arc;

use eyeball_im::VectorDiff;
use futures::StreamExt;
use matrix_sdk::ruma::api::client::receipt::create_receipt::v3::ReceiptType;
use matrix_sdk::ruma::{OwnedEventId, OwnedUserId};
use matrix_sdk_ui::timeline::{
    RoomExt, Timeline, TimelineDetails, TimelineEventFocusThreadMode, TimelineEventItemId,
    TimelineFocus, TimelineItem, TimelineReadReceiptTracking,
};
use tokio::sync::mpsc::{UnboundedReceiver, UnboundedSender, unbounded_channel};

use super::outgoing::Draft;
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
        draft: Draft,
    },
    Edit {
        event_id: String,
        draft: Draft,
    },
    Reply {
        reply_event_id: String,
        draft: Draft,
    },
    /// The room is on screen at its latest message.
    MarkRead,
    /// The composer has text (or not any more).
    Typing(bool),
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

    /// Sends a read receipt for the latest message (if not already ours).
    pub fn mark_read(&self) {
        let _ = self.action_tx.send(MsgAction::MarkRead);
    }
}

/// Receivers the UI listens on.
pub(super) struct TimelineEvents {
    pub init: futures::channel::oneshot::Receiver<TimelineInit>,
    pub updates: UnboundedReceiver<Vec<Arc<TimelineItem>>>,
    /// Display names of the members typing.
    pub typing: UnboundedReceiver<Vec<String>>,
    /// One message per page request: `true` once the start of the room is reached.
    pub page_done: UnboundedReceiver<bool>,
    /// An action that failed, said for the user ("Couldn't delete the message").
    pub errors: UnboundedReceiver<&'static str>,
}

/// The task's ends of the channels.
struct TaskIo {
    init: futures::channel::oneshot::Sender<TimelineInit>,
    pages: UnboundedReceiver<()>,
    actions: UnboundedReceiver<MsgAction>,
    updates: UnboundedSender<Vec<Arc<TimelineItem>>>,
    typing: UnboundedSender<Vec<String>>,
    page_done: UnboundedSender<bool>,
    errors: UnboundedSender<&'static str>,
}

pub(super) fn spawn_timeline(
    room_id: String,
    focus_event_id: Option<String>,
) -> (TimelineHandle, TimelineEvents) {
    let (page_tx, pages) = unbounded_channel();
    let (action_tx, actions) = unbounded_channel();
    let (update_tx, updates) = unbounded_channel();
    let (typing_tx, typing) = unbounded_channel();
    let (page_done_tx, page_done) = unbounded_channel();
    let (error_tx, errors) = unbounded_channel();
    let (init_tx, init) = futures::channel::oneshot::channel();

    let io = TaskIo {
        init: init_tx,
        pages,
        actions,
        updates: update_tx,
        typing: typing_tx,
        page_done: page_done_tx,
        errors: error_tx,
    };
    tokio::task::spawn(run(room_id, focus_event_id, io));

    let handle = TimelineHandle {
        page_tx: Arc::new(page_tx),
        action_tx: Arc::new(action_tx),
    };
    let events = TimelineEvents {
        init,
        updates,
        typing,
        page_done,
        errors,
    };
    (handle, events)
}

async fn run(room_id: String, focus_event_id: Option<String>, mut io: TaskIo) {
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
        let _ = io.init.send((name, dm, vec![]));
        return;
    };
    let timeline = Arc::new(timeline);
    let (items, mut stream) = timeline.subscribe().await;
    let (_typing_guard, mut typing_broadcast) = room.subscribe_to_typing_notifications();

    let mut tl_items: Vec<Arc<TimelineItem>> = items.iter().cloned().collect();
    let mut replies = ReplyDetails::default();
    replies.fetch_missing(&timeline, &tl_items);
    let _ = io.init.send((name, dm, tl_items.clone()));

    loop {
        tokio::select! {
            biased;
            page = io.pages.recv() => {
                if page.is_none() { break; }
                // Always answer: a page can add no visible items (no diff), and
                // the UI would otherwise wait with its spinner forever.
                let hit_start = timeline.paginate_backwards(PAGE_SIZE).await.unwrap_or(false);
                let _ = io.page_done.send(hit_start);
            }
            action = io.actions.recv() => {
                let Some(action) = action else { break; };
                if let Err(message) = run_action(&timeline, &room, action).await {
                    let _ = io.errors.send(message);
                }
            }
            typing = typing_broadcast.recv() => {
                if let Ok(users) = typing {
                    let _ = io.typing.send(member_names(&room, users).await);
                }
            }
            diffs = stream.next() => {
                let Some(diffs) = diffs else { break; };
                tracing::debug!(target: crate::logging::PERF, diffs = diffs.len(), items = tl_items.len(), "timeline update");
                for diff in diffs { apply_diff(&mut tl_items, diff); }
                replies.fetch_missing(&timeline, &tl_items);
                let _ = io.updates.send(tl_items.clone());
            }
        }
    }
    // Leaving the room page stops "typing…" for the others.
    let _ = room.typing_notice(false).await;
}

/// Display names of `users` in `room`, else their localpart.
async fn member_names(room: &matrix_sdk::Room, users: Vec<OwnedUserId>) -> Vec<String> {
    let mut names = Vec::with_capacity(users.len());
    for uid in users {
        let member = room.get_member_no_sync(&uid).await.ok().flatten();
        names.push(
            member
                .and_then(|m| m.display_name().map(str::to_string))
                .unwrap_or_else(|| uid.localpart().to_string()),
        );
    }
    names
}

/// Replies whose quoted message isn't in the timeline: their details are
/// fetched once (the SDK only marks them `Unavailable`).
#[derive(Default)]
struct ReplyDetails {
    requested: HashSet<OwnedEventId>,
}

impl ReplyDetails {
    fn fetch_missing(&mut self, timeline: &Arc<Timeline>, items: &[Arc<TimelineItem>]) {
        for item in items {
            let Some(event) = item.as_event() else {
                continue;
            };
            let Some(msg) = event.content().as_msglike() else {
                continue;
            };
            let Some(reply) = &msg.in_reply_to else {
                continue;
            };
            let Some(event_id) = event.event_id() else {
                continue;
            };
            if !matches!(reply.event, TimelineDetails::Unavailable)
                || !self.requested.insert(event_id.to_owned())
            {
                continue;
            }
            let (timeline, event_id) = (timeline.clone(), event_id.to_owned());
            tokio::spawn(async move {
                if let Err(e) = timeline.fetch_details_for_event(&event_id).await {
                    tracing::debug!("reply details for {event_id}: {e}");
                }
            });
        }
    }
}

/// Runs `action`; `Err` is the message to show when it failed.
async fn run_action(
    timeline: &Timeline,
    room: &matrix_sdk::Room,
    action: MsgAction,
) -> Result<(), &'static str> {
    let event_id = |s: &str| OwnedEventId::try_from(s).ok();
    match action {
        MsgAction::React { event_id: eid, key } => {
            let eid = event_id(&eid).ok_or("Couldn't react to the message")?;
            timeline
                .toggle_reaction(&TimelineEventItemId::EventId(eid), &key)
                .await
                .map_err(|_| "Couldn't react to the message")?;
        }
        MsgAction::Delete { event_id: eid } => {
            let eid = event_id(&eid).ok_or("Couldn't delete the message")?;
            room.redact(&eid, None, None)
                .await
                .map_err(|_| "Couldn't delete the message")?;
        }
        MsgAction::Send { draft } => {
            let _ = room.typing_notice(false).await;
            timeline
                .send(draft.content().with_relation(None).into())
                .await
                .map_err(|_| "Couldn't send the message")?;
            notify_sync();
        }
        MsgAction::Edit {
            event_id: eid,
            draft,
        } => {
            use matrix_sdk::room::edit::EditedContent;
            let eid = event_id(&eid).ok_or("Couldn't edit the message")?;
            timeline
                .edit(
                    &TimelineEventItemId::EventId(eid),
                    EditedContent::RoomMessage(draft.content()),
                )
                .await
                .map_err(|_| "Couldn't edit the message")?;
            notify_sync();
        }
        MsgAction::Reply {
            reply_event_id,
            draft,
        } => {
            let _ = room.typing_notice(false).await;
            let eid = event_id(&reply_event_id).ok_or("Couldn't send the reply")?;
            timeline
                .send_reply(draft.content(), eid)
                .await
                .map_err(|_| "Couldn't send the reply")?;
            notify_sync();
        }
        MsgAction::MarkRead => {
            // A no-op when our receipt is already on the latest event.
            if timeline
                .mark_as_read(ReceiptType::Read)
                .await
                .unwrap_or(false)
            {
                notify_sync();
            }
        }
        MsgAction::Typing(typing) => {
            let _ = room.typing_notice(typing).await;
        }
    }
    Ok(())
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
