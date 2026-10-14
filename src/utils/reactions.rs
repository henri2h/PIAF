//! Reactions feed: reactions others leave on our messages, newest first.

use std::sync::OnceLock;
use std::sync::atomic::{AtomicBool, Ordering};

use futures::StreamExt;
use matrix_sdk::room::MessagesOptions;
use matrix_sdk::ruma::api::client::filter::RoomEventFilter;

use matrix_sdk::ruma::events::{
    AnySyncMessageLikeEvent, AnySyncTimelineEvent, OriginalSyncMessageLikeEvent,
    SyncMessageLikeEvent, reaction::ReactionEventContent,
};
use matrix_sdk::{Client, Room};

use crate::utils::room_preview::message_body;

/// Ensures the reaction event handler is registered at most once across all
/// calls to `activate_client` (login + restore can both call it).
static REACTION_HANDLER_GUARD: OnceLock<()> = OnceLock::new();

/// Registers the reaction handler once per process (login and restore both call this).
pub fn register(client: &Client) {
    if REACTION_HANDLER_GUARD.set(()).is_err() {
        return;
    }
    client.add_event_handler(
        |ev: OriginalSyncMessageLikeEvent<ReactionEventContent>, room: Room, client: Client| async move {
            collect_reaction(ev, room, client).await;
        },
    );
}

/// Rooms scanned by [`backfill`], most recent first.
const BACKFILL_ROOMS: usize = 40;
/// History scanned per room: reactions only where the server can filter
/// (unencrypted rooms), all events otherwise.
const BACKFILL_REACTIONS: u32 = 50;
const BACKFILL_ENCRYPTED_EVENTS: u32 = 100;
const BACKFILL_CONCURRENCY: usize = 4;

static BACKFILLED: AtomicBool = AtomicBool::new(false);

/// Sync only delivers reactions that arrive while the app runs (and sliding
/// sync only the latest event per room), so fill the feed from the recent
/// history of the most recently active rooms. Runs once per session.
pub async fn backfill(client: Client) {
    let mut rooms = client.joined_rooms();
    // Before the first sync there are no rooms yet: leave it for the next open.
    if rooms.is_empty() || BACKFILLED.swap(true, Ordering::Relaxed) {
        return;
    }
    crate::utils::room_list::sort_rooms_by_recency(&mut rooms);
    rooms.truncate(BACKFILL_ROOMS);

    futures::stream::iter(rooms)
        .for_each_concurrent(BACKFILL_CONCURRENCY, |room| {
            let client = client.clone();
            async move { backfill_room(room, client).await }
        })
        .await;
}

async fn backfill_room(room: Room, client: Client) {
    let mut options = MessagesOptions::backward();
    if room.encryption_state().is_encrypted() {
        options.limit = BACKFILL_ENCRYPTED_EVENTS.into();
    } else {
        options.limit = BACKFILL_REACTIONS.into();
        let mut filter = RoomEventFilter::default();
        filter.types = Some(vec!["m.reaction".to_owned()]);
        options.filter = filter;
    }
    let Ok(messages) = room.messages(options).await else {
        return;
    };
    for event in messages.chunk {
        if let Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::Reaction(
            SyncMessageLikeEvent::Original(ev),
        ))) = event.raw().deserialize()
        {
            collect_reaction(ev, room.clone(), client.clone()).await;
        }
    }
}

async fn collect_reaction(
    ev: OriginalSyncMessageLikeEvent<ReactionEventContent>,
    room: Room,
    client: Client,
) {
    let Some(me) = client.user_id() else { return };
    if ev.sender == me {
        return;
    }

    let target_event_id = ev.content.relates_to.event_id.clone();
    let emoji = ev.content.relates_to.key.clone();
    let timestamp_ms: u64 = ev.origin_server_ts.0.into();

    let Ok(target_event) = room.event(&target_event_id, None).await else {
        return;
    };
    let Ok(deserialized) = target_event.kind.raw().deserialize() else {
        return;
    };

    if deserialized.sender() != me {
        return;
    }

    let message_preview = extract_message_preview(&deserialized);

    let room_name = room
        .display_name()
        .await
        .map(|n| n.to_string())
        .unwrap_or_default();

    let sender_display = room
        .get_member_no_sync(&ev.sender)
        .await
        .ok()
        .flatten()
        .and_then(|m| m.display_name().map(|s| s.to_string()))
        .unwrap_or_else(|| ev.sender.localpart().to_string());

    let reaction = crate::utils::ReceivedReaction {
        room_id: room.room_id().to_string(),
        room_name,
        target_event_id: target_event_id.to_string(),
        message_preview,
        emoji,
        sender_id: ev.sender.to_string(),
        sender_display,
        timestamp_ms,
    };

    crate::REACTIONS_TX
        .get()
        .expect("REACTIONS_TX not initialized")
        .send_modify(|v| {
            // Dedup: the list is sorted descending by timestamp; binary-search for the
            // insertion point so we avoid a full O(n log n) re-sort on every reaction.
            let ts = reaction.timestamp_ms;
            let already_exists = v.iter().any(|r| {
                r.sender_id == reaction.sender_id
                    && r.target_event_id == reaction.target_event_id
                    && r.emoji == reaction.emoji
            });
            if !already_exists {
                // partition_point on descending order: first index where ts[i] < ts.
                let pos = v.partition_point(|r| r.timestamp_ms > ts);
                v.insert(pos, reaction);
            }
        });
}

fn extract_message_preview(event: &AnySyncTimelineEvent) -> String {
    let body = match event {
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
            SyncMessageLikeEvent::Original(msg),
        )) => message_body(&msg.content.msgtype),
        _ => None,
    };
    body.map(|b| b.chars().take(60).collect())
        .unwrap_or_else(|| "Message".to_string())
}
