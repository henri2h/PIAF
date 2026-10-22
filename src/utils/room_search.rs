//! Searching one room's messages. The server can't read end-to-end encrypted
//! messages, so encrypted rooms are searched locally through the event cache
//! (decrypted events), loading older history a few pages at a time; others
//! use the server's `/search`, falling back to the local search.

use std::collections::HashMap;

use matrix_sdk::Room;
use matrix_sdk::ruma::api::client::{
    filter::RoomEventFilter, search::search_events::v3 as search_v3,
};
use matrix_sdk::ruma::events::{
    AnyMessageLikeEvent, AnySyncMessageLikeEvent, AnySyncTimelineEvent, AnyTimelineEvent,
    MessageLikeEvent, SyncMessageLikeEvent,
};
use matrix_sdk::ruma::serde::Raw;
use matrix_sdk::ruma::{MilliSecondsSinceUnixEpoch, OwnedEventId, OwnedUserId, UserId};

use crate::utils::room_preview::message_body;

/// Enough hits to stop loading older history.
const ENOUGH: usize = 30;
/// Older history loaded at most, in pages of [`PAGE`] events.
const MAX_PAGES: usize = 5;
const PAGE: u16 = 100;

#[derive(Clone, Debug, PartialEq)]
pub struct Hit {
    pub event_id: OwnedEventId,
    pub sender: OwnedUserId,
    /// Resolved display name (the user ID until then).
    pub sender_name: String,
    pub body: String,
    pub ts: MilliSecondsSinceUnixEpoch,
}

/// `body` without a reply's quoted fallback (`> <@user> text` lines, then a
/// blank line), which repeats the replied message.
pub fn strip_reply_fallback(body: &str) -> &str {
    if !body.starts_with("> ") {
        return body;
    }
    let mut rest = body;
    while let Some(line) = rest.lines().next() {
        if !line.starts_with('>') {
            break;
        }
        rest = rest[line.len()..].trim_start_matches(['\r', '\n']);
    }
    rest
}

/// Whether `body` contains `query`, ignoring case.
pub fn matches(body: &str, query: &str) -> bool {
    let query = query.trim().to_lowercase();
    !query.is_empty() && body.to_lowercase().contains(&query)
}

/// A message event matching `query`, as a hit.
pub fn hit_from_raw(raw: &Raw<AnySyncTimelineEvent>, query: &str) -> Option<Hit> {
    let AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
        SyncMessageLikeEvent::Original(msg),
    )) = raw.deserialize().ok()?
    else {
        return None;
    };
    let body = strip_reply_fallback(&message_body(&msg.content.msgtype)?).to_string();
    matches(&body, query).then(|| Hit {
        event_id: msg.event_id,
        sender: msg.sender.clone(),
        sender_name: msg.sender.to_string(),
        body,
        ts: msg.origin_server_ts,
    })
}

/// Messages of `room_id` matching `query`, newest first.
pub async fn search(room_id: &str, query: &str) -> Vec<Hit> {
    let Some(room) = crate::utils::matrix::get_room(room_id) else {
        return vec![];
    };
    let mut hits = if room.encryption_state().is_encrypted() {
        search_local(&room, query).await
    } else {
        match search_server(&room, query).await {
            Some(hits) => hits,
            None => search_local(&room, query).await,
        }
    };
    hits.sort_by(|a, b| b.ts.cmp(&a.ts));
    hits.dedup_by(|a, b| a.event_id == b.event_id);
    resolve_names(&room, &mut hits).await;
    hits
}

async fn search_local(room: &Room, query: &str) -> Vec<Hit> {
    let Ok((cache, _handles)) = room.event_cache().await else {
        return vec![];
    };
    let scan = |events: Vec<matrix_sdk::deserialized_responses::TimelineEvent>| {
        events
            .iter()
            .filter_map(|e| hit_from_raw(e.raw(), query))
            .collect::<Vec<_>>()
    };
    let mut hits = scan(cache.events().await.unwrap_or_default());
    for _ in 0..MAX_PAGES {
        if hits.len() >= ENOUGH {
            break;
        }
        let Ok(outcome) = cache.pagination().run_backwards_once(PAGE).await else {
            break;
        };
        hits = scan(cache.events().await.unwrap_or_default());
        if outcome.reached_start {
            break;
        }
    }
    hits
}

/// `None` when the server search failed.
async fn search_server(room: &Room, query: &str) -> Option<Vec<Hit>> {
    let mut filter = RoomEventFilter::default();
    filter.rooms = Some(vec![room.room_id().to_owned()]);
    let mut criteria = search_v3::Criteria::new(query.to_owned());
    criteria.filter = filter;
    let mut categories = search_v3::Categories::new();
    categories.room_events = Some(criteria);
    let response = room
        .client()
        .send(search_v3::Request::new(categories))
        .await
        .ok()?;
    Some(
        response
            .search_categories
            .room_events
            .results
            .into_iter()
            .filter_map(|result| {
                let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                    MessageLikeEvent::Original(msg),
                ))) = result.result?.deserialize()
                else {
                    return None;
                };
                let body = strip_reply_fallback(&message_body(&msg.content.msgtype)?).to_string();
                // The server also matched the reply quote: only the message counts.
                matches(&body, query).then(|| Hit {
                    event_id: msg.event_id,
                    sender_name: msg.sender.to_string(),
                    sender: msg.sender,
                    body,
                    ts: msg.origin_server_ts,
                })
            })
            .collect(),
    )
}

async fn resolve_names(room: &Room, hits: &mut [Hit]) {
    let mut names: HashMap<OwnedUserId, String> = HashMap::new();
    for hit in hits.iter_mut() {
        if !names.contains_key(&hit.sender) {
            let name = member_name(room, &hit.sender).await;
            names.insert(hit.sender.clone(), name);
        }
        hit.sender_name = names[&hit.sender].clone();
    }
}

async fn member_name(room: &Room, user_id: &UserId) -> String {
    room.get_member_no_sync(user_id)
        .await
        .ok()
        .flatten()
        .map(|m| m.name().to_string())
        .unwrap_or_else(|| user_id.to_string())
}

#[cfg(test)]
mod tests {
    use matrix_sdk::ruma::exports::serde_json::json;

    use super::*;

    fn raw(value: matrix_sdk::ruma::exports::serde_json::Value) -> Raw<AnySyncTimelineEvent> {
        Raw::from_json_string(value.to_string()).unwrap()
    }

    fn message(body: &str) -> Raw<AnySyncTimelineEvent> {
        raw(json!({
            "type": "m.room.message",
            "event_id": "$e1",
            "sender": "@alice:example.org",
            "origin_server_ts": 1000,
            "content": { "msgtype": "m.text", "body": body }
        }))
    }

    #[test]
    fn finds_text_messages_ignoring_case() {
        let hit = hit_from_raw(&message("Dinner at Marco's?"), "marco").unwrap();
        assert_eq!(hit.body, "Dinner at Marco's?");
        assert_eq!(hit.sender.as_str(), "@alice:example.org");
        assert!(hit_from_raw(&message("hello"), "marco").is_none());
        assert!(
            hit_from_raw(&message("hello"), "  ").is_none(),
            "blank query"
        );
    }

    #[test]
    fn reply_quotes_are_neither_matched_nor_shown() {
        let body = "> <@user-test-1:carnot.cc> Fine and you ?\n\nnice :)";
        assert_eq!(strip_reply_fallback(body), "nice :)");
        assert!(hit_from_raw(&message(body), "test").is_none());
        assert_eq!(
            hit_from_raw(&message(body), "nice").unwrap().body,
            "nice :)"
        );
        assert_eq!(strip_reply_fallback("plain > text"), "plain > text");
    }

    #[test]
    fn skips_other_events() {
        let reaction = raw(json!({
            "type": "m.reaction",
            "event_id": "$r",
            "sender": "@alice:example.org",
            "origin_server_ts": 1,
            "content": { "m.relates_to": { "rel_type": "m.annotation", "event_id": "$e1", "key": "marco" } }
        }));
        assert!(hit_from_raw(&reaction, "marco").is_none());
    }
}
