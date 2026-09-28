//! Which rooms the home list shows, and in what order.

use std::collections::HashMap;

use matrix_sdk::notification_settings::RoomNotificationMode;
use matrix_sdk::{Room, RoomState};

use crate::utils::matrix::{CLIENT, latest_event_ts};
use crate::utils::room_mailbox::{RoomMailboxState, is_archived_hidden};

/// Per-room data the list needs, read once per sync. `room` is carried for the
/// row's lazy preview and is ignored by `PartialEq`, which drives row memoization.
#[derive(Clone)]
pub struct RoomSummary {
    pub room: Room,
    pub room_id: String,
    pub name: String,
    pub latest_ts: Option<u64>,
    pub unread_messages: u64,
    pub notifications: u64,
    pub is_dm: bool,
    pub is_muted: bool,
    /// Pending invite: not joined yet.
    pub is_invite: bool,
    /// No latest event cached yet; the row requests one.
    pub needs_preview: bool,
    sort_key: u64,
}

impl PartialEq for RoomSummary {
    fn eq(&self, other: &Self) -> bool {
        self.room_id == other.room_id
            && self.name == other.name
            && self.latest_ts == other.latest_ts
            && self.unread_messages == other.unread_messages
            && self.notifications == other.notifications
            && self.is_dm == other.is_dm
            && self.is_muted == other.is_muted
            && self.is_invite == other.is_invite
            && self.needs_preview == other.needs_preview
    }
}

impl RoomSummary {
    pub fn new(room: Room) -> Self {
        let latest = room.latest_event();
        let latest_ts = latest.timestamp().map(|ts| ts.get().into());
        Self {
            room_id: room.room_id().to_string(),
            name: room
                .cached_display_name()
                .map(|n| n.to_string())
                .unwrap_or_else(|| "Unknown".to_string()),
            latest_ts,
            unread_messages: room.num_unread_messages(),
            notifications: room.num_unread_notifications(),
            is_dm: room.is_dm(),
            is_muted: room.cached_user_defined_notification_mode()
                == Some(RoomNotificationMode::Mute),
            is_invite: room.state() == RoomState::Invited,
            needs_preview: latest.is_none(),
            sort_key: sort_key(latest_ts, room.recency_stamp().map(u64::from)),
            room,
        }
    }

    /// Unread messages, or an invite waiting for an answer.
    pub fn is_unread(&self) -> bool {
        self.is_invite || self.unread_messages > 0 || self.notifications > 0
    }
}

#[derive(Clone, PartialEq, Debug)]
pub enum RoomFilter {
    All,
    Groups,
    Dms,
    Unread,
}

impl RoomFilter {
    pub const ALL: [RoomFilter; 4] = [Self::All, Self::Groups, Self::Dms, Self::Unread];

    pub fn label(&self) -> &'static str {
        match self {
            Self::All => "All",
            Self::Groups => "Groups",
            Self::Dms => "DMs",
            Self::Unread => "Unread",
        }
    }

    pub fn matches(&self, room: &RoomSummary) -> bool {
        match self {
            Self::All => true,
            Self::Groups => !room.is_dm,
            Self::Dms => room.is_dm,
            Self::Unread => room.is_unread(),
        }
    }
}

/// Latest-event timestamp (client-side), falling back to the server recency stamp.
fn sort_key(latest_ts: Option<u64>, recency_stamp: Option<u64>) -> u64 {
    latest_ts.or(recency_stamp).unwrap_or(0)
}

/// Sorts newest first. Keys are computed once per room: `latest_event()` is not cheap.
pub fn sort_rooms_by_recency(rooms: &mut Vec<Room>) {
    let mut keyed: Vec<(u64, Room)> = rooms
        .drain(..)
        .map(|r| {
            let key = sort_key(latest_event_ts(&r), r.recency_stamp().map(u64::from));
            (key, r)
        })
        .collect();
    keyed.sort_unstable_by(|a, b| b.0.cmp(&a.0));
    rooms.extend(keyed.into_iter().map(|(_, r)| r));
}

/// Invites first (they need an answer), then joined rooms; each newest first.
pub fn all_room_summaries() -> Vec<RoomSummary> {
    let Some(client) = CLIENT.get() else {
        return vec![];
    };
    let mut rooms: Vec<RoomSummary> = client
        .joined_rooms()
        .into_iter()
        .chain(client.invited_rooms())
        .map(RoomSummary::new)
        .collect();
    sort_summaries(&mut rooms);
    rooms
}

fn sort_summaries(rooms: &mut [RoomSummary]) {
    rooms.sort_unstable_by(|a, b| {
        b.is_invite
            .cmp(&a.is_invite)
            .then(b.sort_key.cmp(&a.sort_key))
    });
}

/// Rooms passing `filter` that aren't archived; order preserved.
pub fn visible_rooms(
    rooms: &[RoomSummary],
    filter: &RoomFilter,
    mailbox: &HashMap<String, RoomMailboxState>,
) -> Vec<RoomSummary> {
    rooms
        .iter()
        .filter(|r| {
            let archived_until_ts = mailbox.get(&r.room_id).and_then(|s| s.archived_until_ts);
            filter.matches(r) && !is_archived_hidden(r.latest_ts, archived_until_ts)
        })
        .cloned()
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    use matrix_sdk::ruma::room_id;
    use matrix_sdk::test_utils::mocks::MatrixMockServer;
    use matrix_sdk_test::{InvitedRoomBuilder, JoinedRoomBuilder};

    /// One joined and one invited room, from a mocked sync.
    async fn joined_and_invited() -> (RoomSummary, RoomSummary) {
        let server = MatrixMockServer::new().await;
        let client = server.client_builder().build().await;
        let joined = server
            .sync_room(
                &client,
                JoinedRoomBuilder::new(room_id!("!joined:example.org")),
            )
            .await;
        let invited = server
            .sync_room(
                &client,
                InvitedRoomBuilder::new(room_id!("!invited:example.org")),
            )
            .await;
        (RoomSummary::new(joined), RoomSummary::new(invited))
    }

    #[tokio::test]
    async fn invite_is_flagged_and_unread() {
        let (joined, invited) = joined_and_invited().await;
        assert!(invited.is_invite);
        assert!(!joined.is_invite);
        assert!(RoomFilter::Unread.matches(&invited));
    }

    #[tokio::test]
    async fn invites_sort_first() {
        let (mut joined, invited) = joined_and_invited().await;
        joined.sort_key = u64::MAX;
        let mut rooms = vec![joined, invited];
        sort_summaries(&mut rooms);
        assert!(rooms[0].is_invite);
    }

    #[tokio::test]
    async fn invites_show_in_all() {
        let (_, invited) = joined_and_invited().await;
        let mailbox = HashMap::new();
        let visible = visible_rooms(&[invited], &RoomFilter::All, &mailbox);
        assert_eq!(visible.len(), 1);
    }

    #[test]
    fn sort_key_prefers_latest_event() {
        assert_eq!(sort_key(Some(10), Some(99)), 10);
    }

    #[test]
    fn sort_key_falls_back_to_recency_then_zero() {
        assert_eq!(sort_key(None, Some(99)), 99);
        assert_eq!(sort_key(None, None), 0);
    }
}
