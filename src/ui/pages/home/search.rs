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

/// Which results a search shows (the search page's chips).
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum SearchFilter {
    All,
    Rooms,
    People,
    Messages,
}

impl SearchFilter {
    pub const ALL: [SearchFilter; 4] = [Self::All, Self::Rooms, Self::People, Self::Messages];

    pub fn label(&self) -> &'static str {
        match self {
            Self::All => "All",
            Self::Rooms => "Rooms",
            Self::People => "People",
            Self::Messages => "Messages",
        }
    }

    pub fn shows(&self, section: SearchFilter) -> bool {
        *self == Self::All || *self == section
    }
}

/// Byte range of `query` in `name`, ignoring case; `None` without a match.
pub fn find_match(name: &str, query: &str) -> Option<(usize, usize)> {
    let query: Vec<char> = query.trim().chars().flat_map(char::to_lowercase).collect();
    if query.is_empty() {
        return None;
    }
    for (start, _) in name.char_indices() {
        let mut wanted = query.iter();
        for (i, c) in name[start..].char_indices() {
            let mut matched = true;
            for lower in c.to_lowercase() {
                match wanted.next() {
                    Some(&w) if w == lower => {}
                    Some(_) => {
                        matched = false;
                        break;
                    }
                    None => break,
                }
            }
            if !matched {
                break;
            }
            if wanted.as_slice().is_empty() {
                return Some((start, start + i + c.len_utf8()));
            }
        }
    }
    None
}

/// Joined and invited rooms whose name contains `query`, most recent first.
pub fn search_rooms_local(client: &Client, query: &str, limit: usize) -> Vec<RoomResult> {
    let ql = query.to_lowercase();
    let mut all_rooms = client.joined_rooms();
    all_rooms.extend(client.invited_rooms());
    crate::utils::room_list::sort_rooms_by_recency(&mut all_rooms);
    all_rooms
        .into_iter()
        .filter_map(|r| {
            let name = r.cached_display_name().map(|n| n.to_string())?;
            if name.to_lowercase().contains(&ql) {
                Some(RoomResult {
                    room_id: r.room_id().to_string(),
                    display_name: name,
                })
            } else {
                None
            }
        })
        .take(limit)
        .collect()
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

#[cfg(test)]
mod tests {
    use super::find_match;

    #[test]
    fn match_ignores_case() {
        assert_eq!(find_match("Testers HQ", "hq"), Some((8, 10)));
        assert_eq!(find_match("Testers HQ", "TEST"), Some((0, 4)));
    }

    #[test]
    fn match_handles_multibyte_names() {
        let name = "Café Été";
        let (start, end) = find_match(name, "été").unwrap();
        assert_eq!(&name[start..end], "Été");
    }

    #[test]
    fn no_match() {
        assert_eq!(find_match("Bob", "alice"), None);
        assert_eq!(find_match("Bob", "  "), None);
    }
}
