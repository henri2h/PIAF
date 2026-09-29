//! Reactions feed: reactions others leave on our messages, newest first.

use std::sync::OnceLock;

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
