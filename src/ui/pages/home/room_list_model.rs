//! Room list filters (UI side). The summaries themselves live in `utils::room_list`.

use std::collections::HashMap;

use crate::utils::room_list::RoomSummary;
use crate::utils::room_mailbox::{RoomMailboxState, is_archived_hidden};

/// Which rooms the list shows, before the [`RoomFilter`] chips apply.
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum Mailbox {
    Inbox,
    Recontact,
    Archived,
}

impl Mailbox {
    pub const ALL: [Mailbox; 3] = [Self::Inbox, Self::Recontact, Self::Archived];

    pub fn label(&self) -> &'static str {
        match self {
            Self::Inbox => "Inbox",
            Self::Recontact => "Recontact",
            Self::Archived => "Archived",
        }
    }

    fn matches(&self, room: &RoomSummary, state: Option<&RoomMailboxState>) -> bool {
        let archived = is_archived_hidden(room.latest_ts, state.and_then(|s| s.archived_until_ts));
        match self {
            Self::Inbox => !archived,
            Self::Recontact => state.is_some_and(|s| s.recontact),
            Self::Archived => archived,
        }
    }
}

#[derive(Clone, PartialEq, Debug)]
pub enum RoomFilter {
    All,
    Unread,
    Favourites,
    Dms,
    Groups,
}

impl RoomFilter {
    pub const ALL: [RoomFilter; 5] = [
        Self::All,
        Self::Unread,
        Self::Favourites,
        Self::Dms,
        Self::Groups,
    ];

    pub fn label(&self) -> &'static str {
        match self {
            Self::All => "All",
            Self::Groups => "Groups",
            Self::Dms => "DMs",
            Self::Unread => "Unread",
            Self::Favourites => "Favourites",
        }
    }

    /// Empty-list message when nothing matches.
    pub fn empty_title(&self) -> &'static str {
        match self {
            Self::All => "No conversations yet",
            Self::Unread => "All caught up",
            Self::Favourites => "No favourites yet",
            Self::Dms => "No direct messages",
            Self::Groups => "No group chats",
        }
    }

    pub fn empty_subtitle(&self) -> &'static str {
        match self {
            Self::All => "Join a room or start a new chat",
            Self::Unread => "You've read everything",
            Self::Favourites if cfg!(target_os = "android") => "Long-press a room to add it",
            Self::Favourites => "Right-click a room to add it",
            Self::Dms | Self::Groups => "Try another filter",
        }
    }

    pub fn matches(&self, room: &RoomSummary) -> bool {
        match self {
            Self::All => true,
            Self::Groups => !room.is_dm,
            Self::Dms => room.is_dm,
            Self::Unread => room.is_unread(),
            Self::Favourites => room.is_favourite,
        }
    }
}

/// Rooms in `view` passing `filter`; order preserved.
pub fn visible_rooms(
    rooms: &[RoomSummary],
    view: Mailbox,
    filter: &RoomFilter,
    mailbox: &HashMap<String, RoomMailboxState>,
) -> Vec<RoomSummary> {
    rooms
        .iter()
        .filter(|r| filter.matches(r) && view.matches(r, mailbox.get(&r.room_id)))
        .cloned()
        .collect()
}

#[cfg(test)]
mod tests {
    use matrix_sdk::ruma::room_id;

    use super::*;
    use crate::utils::room_list::test_support::{invited, joined, marked_unread, server, tag};

    #[tokio::test]
    async fn unread_filter_includes_marked_and_invites() {
        let (server, client) = server().await;
        let marked = joined(&server, &client, room_id!("!m:x"), vec![marked_unread()]).await;
        let invite = invited(&server, &client, room_id!("!i:x")).await;
        let plain = joined(&server, &client, room_id!("!p:x"), vec![]).await;
        assert!(RoomFilter::Unread.matches(&marked));
        assert!(RoomFilter::Unread.matches(&invite));
        assert!(!RoomFilter::Unread.matches(&plain));
    }

    #[tokio::test]
    async fn favourites_filter() {
        let (server, client) = server().await;
        let fav = joined(
            &server,
            &client,
            room_id!("!fav:x"),
            vec![tag("m.favourite")],
        )
        .await;
        let normal = joined(&server, &client, room_id!("!normal:x"), vec![]).await;
        assert!(RoomFilter::Favourites.matches(&fav));
        assert!(!RoomFilter::Favourites.matches(&normal));
    }

    #[tokio::test]
    async fn invites_show_in_all() {
        let (server, client) = server().await;
        let invite = invited(&server, &client, room_id!("!i:x")).await;
        let visible = visible_rooms(&[invite], Mailbox::Inbox, &RoomFilter::All, &HashMap::new());
        assert_eq!(visible.len(), 1);
    }
}
