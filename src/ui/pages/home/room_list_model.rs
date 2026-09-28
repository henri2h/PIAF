//! Which rooms the home list shows, and in what order.

use std::collections::HashMap;

use matrix_sdk::Room;

use crate::utils::matrix::{CLIENT, latest_event_ts};
use crate::utils::room_mailbox::{RoomMailboxState, is_room_archived};

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

    pub fn matches(&self, room: &Room) -> bool {
        match self {
            Self::All => true,
            Self::Groups => !room.is_dm(),
            Self::Dms => room.is_dm(),
            Self::Unread => is_unread(room),
        }
    }
}

pub fn is_unread(room: &Room) -> bool {
    room.num_unread_messages() > 0 || room.num_unread_notifications() > 0
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

/// Joined + invited rooms, newest first.
pub fn all_rooms_sorted() -> Vec<Room> {
    let Some(client) = CLIENT.get() else {
        return vec![];
    };
    let mut rooms = client.joined_rooms();
    rooms.extend(client.invited_rooms());
    sort_rooms_by_recency(&mut rooms);
    rooms
}

/// Rooms passing `filter` that aren't archived; order preserved.
pub fn visible_rooms(
    rooms: &[Room],
    filter: &RoomFilter,
    mailbox: &HashMap<String, RoomMailboxState>,
) -> Vec<Room> {
    rooms
        .iter()
        .filter(|r| filter.matches(r) && !is_room_archived(r, mailbox))
        .cloned()
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

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
