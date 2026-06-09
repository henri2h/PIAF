use matrix_sdk::Client;
use matrix_sdk::ruma::{
    UInt,
    api::client::{filter::RoomEventFilter, search::search_events::v3 as search_v3},
    events::{AnyMessageLikeEvent, AnyTimelineEvent, MessageLikeEvent, room::message::MessageType},
};

pub struct RoomResult {
    pub room_id: String,
    pub display_name: String,
}

pub struct UserResult {
    pub user_id: String,
    pub display_name: String,
    pub avatar_mxc: Option<String>,
}

#[derive(Clone)]
pub struct MessageResult {
    pub event_id: String,
    pub room_id: String,
    pub room_name: String,
    pub body: String,
    pub sender_display_name: String,
    pub event_ts_ms: u64,
    pub is_dm: bool,
}

pub fn search_rooms_local(client: &Client, query: &str) -> Vec<RoomResult> {
    let ql = query.to_lowercase();
    let mut all_rooms = client.joined_rooms();
    all_rooms.extend(client.invited_rooms());
    super::sort_rooms_by_recency(&mut all_rooms);
    all_rooms
        .into_iter()
        .filter_map(|r| {
            let name = r.cached_display_name().map(|n| n.to_string())?;
            if name.to_lowercase().contains(&ql) {
                Some(RoomResult { room_id: r.room_id().to_string(), display_name: name })
            } else {
                None
            }
        })
        .take(8)
        .collect()
}

pub async fn search_users_remote(client: Client, query: String) -> Vec<UserResult> {
    match client.search_users(&query, 5).await {
        Ok(r) => r
            .results
            .into_iter()
            .map(|u| UserResult {
                display_name: u
                    .display_name
                    .unwrap_or_else(|| u.user_id.localpart().to_string()),
                avatar_mxc: u.avatar_url.map(|a| a.to_string()),
                user_id: u.user_id.to_string(),
            })
            .collect(),
        Err(_) => vec![],
    }
}

/// Fetch one page of message search results.
///
/// Pass `next_batch = None` for the first page; pass the token returned by a
/// previous call to continue to the next page.
///
/// Returns `(results, next_batch_token)` where `next_batch_token` is `None`
/// when there are no further pages.
pub async fn search_messages_remote(
    client: Client,
    query: String,
    next_batch: Option<String>,
) -> (Vec<MessageResult>, Option<String>) {
    let mut filter = RoomEventFilter::default();
    filter.limit = Some(UInt::from(10u32));

    let mut criteria = search_v3::Criteria::new(query);
    criteria.filter = filter;
    criteria.include_state = Some(false);
    criteria.event_context.before_limit = UInt::from(0u32);
    criteria.event_context.after_limit = UInt::from(0u32);
    criteria.event_context.include_profile = true;

    let mut categories = search_v3::Categories::new();
    categories.room_events = Some(criteria);

    let mut request = search_v3::Request::new(categories);
    request.next_batch = next_batch;

    let Ok(response) = client.send(request).await else {
        return (vec![], None);
    };

    let next_token = response.search_categories.room_events.next_batch.clone();
    let mut results: Vec<MessageResult> = vec![];

    for result in response.search_categories.room_events.results {
        let Some(raw) = result.result else { continue };
        let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
            MessageLikeEvent::Original(msg),
        ))) = raw.deserialize()
        else {
            continue;
        };
        let body = match &msg.content.msgtype {
            MessageType::Text(t) => t.body.chars().take(100).collect::<String>(),
            _ => continue,
        };
        let room = client.get_room(&msg.room_id);
        let room_name = room
            .as_ref()
            .and_then(|r| r.cached_display_name())
            .map(|n| n.to_string())
            .unwrap_or_default();
        let is_dm = room.as_ref().map(|r| r.is_dm()).unwrap_or(false);
        let sender_display_name = result
            .context
            .profile_info
            .get(&msg.sender)
            .and_then(|p| p.displayname.clone())
            .unwrap_or_else(|| msg.sender.localpart().to_string());
        let event_ts_ms = u64::from(msg.origin_server_ts.0);
        let event_id = msg.event_id.to_string();

        results.push(MessageResult {
            event_id,
            room_id: msg.room_id.to_string(),
            room_name,
            body,
            sender_display_name,
            event_ts_ms,
            is_dm,
        });
    }

    (results, next_token)
}
