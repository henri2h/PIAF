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

/// Conversations counted by the Chats tab badge: unread, not muted, in the inbox.
pub fn unread_conversations(
    rooms: &[RoomSummary],
    mailbox: &HashMap<String, RoomMailboxState>,
) -> usize {
    rooms
        .iter()
        .filter(|r| r.is_unread() && !r.is_muted)
        .filter(|r| Mailbox::Inbox.matches(r, mailbox.get(&r.room_id)))
        .count()
}

/// Room list section headed by a [`ListRow::Header`]. Invites have the
/// [`ListRow::Invites`] row instead.
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum Section {
    Favourites,
    Conversations,
    LowPriority,
}

impl Section {
    fn of(room: &RoomSummary) -> Option<Self> {
        match () {
            _ if room.is_invite => None,
            _ if room.is_favourite => Some(Self::Favourites),
            _ if room.is_low_priority => Some(Self::LowPriority),
            _ => Some(Self::Conversations),
        }
    }

    pub fn label(&self) -> &'static str {
        match self {
            Self::Favourites => "Favourites",
            Self::Conversations => "Conversations",
            Self::LowPriority => "Low priority",
        }
    }
}

/// One row of the room list.
#[derive(Clone, PartialEq, Debug)]
pub enum ListRow {
    /// Two or more invites, folded into one row; `expanded` lists them below it.
    Invites {
        count: usize,
        expanded: bool,
    },
    Header(Section),
    /// Index into the rooms given to [`list_rows`].
    Room(usize),
}

/// Rows for `rooms` (sorted by section): invites fold into one row from two
/// on, and section headers show only when the other rooms span several sections.
pub fn list_rows(rooms: &[RoomSummary], invites_expanded: bool) -> Vec<ListRow> {
    let mut rows = Vec::with_capacity(rooms.len() + 4);
    let invites: Vec<usize> = (0..rooms.len()).filter(|&i| rooms[i].is_invite).collect();
    if invites.len() >= 2 {
        rows.push(ListRow::Invites {
            count: invites.len(),
            expanded: invites_expanded,
        });
    }
    if invites.len() < 2 || invites_expanded {
        rows.extend(invites.iter().map(|&i| ListRow::Room(i)));
    }

    let mut sections = rooms.iter().filter_map(Section::of);
    let first = sections.next();
    let headers = sections.any(|s| Some(s) != first);
    let mut current = None;
    for (i, room) in rooms.iter().enumerate() {
        let Some(section) = Section::of(room) else {
            continue;
        };
        if headers && current != Some(section) {
            rows.push(ListRow::Header(section));
            current = Some(section);
        }
        rows.push(ListRow::Room(i));
    }
    rows
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

    async fn rooms(invites: usize, tags: &[&str]) -> Vec<RoomSummary> {
        let (server, client) = server().await;
        let mut rooms = vec![];
        for i in 0..invites {
            let id = matrix_sdk::ruma::RoomId::parse(format!("!i{i}:x")).unwrap();
            rooms.push(invited(&server, &client, &id).await);
        }
        for (i, t) in tags.iter().enumerate() {
            let id = matrix_sdk::ruma::RoomId::parse(format!("!r{i}:x")).unwrap();
            let data = if t.is_empty() { vec![] } else { vec![tag(t)] };
            rooms.push(joined(&server, &client, &id, data).await);
        }
        rooms
    }

    #[tokio::test]
    async fn one_invite_stays_a_room_row() {
        let rooms = rooms(1, &["", ""]).await;
        assert_eq!(
            list_rows(&rooms, false),
            vec![ListRow::Room(0), ListRow::Room(1), ListRow::Room(2)]
        );
    }

    #[tokio::test]
    async fn invites_fold_and_expand() {
        let rooms = rooms(2, &[""]).await;
        let folded = ListRow::Invites {
            count: 2,
            expanded: false,
        };
        assert_eq!(list_rows(&rooms, false), vec![folded, ListRow::Room(2)]);
        let expanded = ListRow::Invites {
            count: 2,
            expanded: true,
        };
        assert_eq!(
            list_rows(&rooms, true),
            vec![
                expanded,
                ListRow::Room(0),
                ListRow::Room(1),
                ListRow::Room(2)
            ]
        );
    }

    #[tokio::test]
    async fn headers_only_across_sections() {
        let plain = rooms(0, &["", ""]).await;
        assert_eq!(
            list_rows(&plain, false),
            vec![ListRow::Room(0), ListRow::Room(1)]
        );

        let mixed = rooms(0, &["m.favourite", "", "m.lowpriority"]).await;
        assert_eq!(
            list_rows(&mixed, false),
            vec![
                ListRow::Header(Section::Favourites),
                ListRow::Room(0),
                ListRow::Header(Section::Conversations),
                ListRow::Room(1),
                ListRow::Header(Section::LowPriority),
                ListRow::Room(2),
            ]
        );
    }

    #[tokio::test]
    async fn unread_count_skips_read_and_archived() {
        let (server, client) = server().await;
        let marked = joined(&server, &client, room_id!("!m:x"), vec![marked_unread()]).await;
        let invite = invited(&server, &client, room_id!("!i:x")).await;
        let plain = joined(&server, &client, room_id!("!p:x"), vec![]).await;
        let rooms = [marked, invite, plain];
        assert_eq!(unread_conversations(&rooms, &HashMap::new()), 2);
        let archived = HashMap::from([(
            "!m:x".to_string(),
            RoomMailboxState {
                archived_until_ts: Some(u64::MAX),
                ..Default::default()
            },
        )]);
        assert_eq!(unread_conversations(&rooms, &archived), 1);
    }
}
