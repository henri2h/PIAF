//! The room list: per-room summaries built off the UI thread and published
//! only when something visible changed. `RoomSummary`'s `PartialEq` is the
//! single definition of "visible": it drives both publishing and row memoization.

use std::collections::HashMap;
use std::sync::{Arc, LazyLock, Mutex};

use matrix_sdk::latest_events::LatestEventValue;
use matrix_sdk::notification_settings::RoomNotificationMode;
use matrix_sdk::{Client, Room, RoomState};
use tokio::sync::watch;

use crate::logging::PERF;
use crate::utils::matrix::{CLIENT, latest_event_ts};

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
    pub mentions: u64,
    /// Manually marked unread (`m.marked_unread`).
    pub marked_unread: bool,
    pub is_dm: bool,
    pub is_muted: bool,
    pub is_favourite: bool,
    pub is_low_priority: bool,
    /// Pending invite: not joined yet.
    pub is_invite: bool,
    /// Our latest message failed to send.
    pub send_failed: bool,
    /// First line of the composer draft.
    pub draft: Option<String>,
    /// No latest event cached yet; the row requests one.
    pub needs_preview: bool,
    sort_key: SortKey,
}

impl PartialEq for RoomSummary {
    fn eq(&self, other: &Self) -> bool {
        self.room_id == other.room_id
            && self.name == other.name
            && self.latest_ts == other.latest_ts
            && self.unread_messages == other.unread_messages
            && self.notifications == other.notifications
            && self.mentions == other.mentions
            && self.marked_unread == other.marked_unread
            && self.is_dm == other.is_dm
            && self.is_muted == other.is_muted
            && self.is_favourite == other.is_favourite
            && self.is_low_priority == other.is_low_priority
            && self.is_invite == other.is_invite
            && self.send_failed == other.send_failed
            && self.draft == other.draft
            && self.needs_preview == other.needs_preview
    }
}

impl RoomSummary {
    pub fn new(room: Room) -> Self {
        let latest = room.latest_event();
        let latest_ts = latest.timestamp().map(|ts| ts.get().into());
        let is_invite = room.state() == RoomState::Invited;
        Self {
            room_id: room.room_id().to_string(),
            name: room
                .cached_display_name()
                .map(|n| n.to_string())
                .unwrap_or_else(|| "Unknown".to_string()),
            latest_ts,
            unread_messages: room.num_unread_messages(),
            notifications: room.num_unread_notifications(),
            mentions: room.num_unread_mentions(),
            marked_unread: room.is_marked_unread(),
            // `is_dm` is unreliable for invites; use the resolved invite flag.
            is_dm: is_invite
                .then(|| invite_is_direct(room.room_id()))
                .flatten()
                .unwrap_or_else(|| room.is_dm()),
            is_muted: room.cached_user_defined_notification_mode()
                == Some(RoomNotificationMode::Mute),
            is_favourite: room.is_favourite(),
            is_low_priority: room.is_low_priority(),
            is_invite,
            send_failed: matches!(latest, LatestEventValue::LocalCannotBeSent(_)),
            draft: crate::utils::drafts::preview(room.room_id().as_str()),
            needs_preview: latest.is_none(),
            sort_key: sort_key(latest_ts, room.recency_stamp().map(u64::from)),
            room,
        }
    }

    /// Unread messages, marked unread, or an invite waiting for an answer.
    pub fn is_unread(&self) -> bool {
        self.is_invite || self.marked_unread || self.unread_messages > 0 || self.notifications > 0
    }

    /// List section: invites, favourites, rooms, low priority.
    fn rank(&self) -> u8 {
        match () {
            _ if self.is_invite => 0,
            _ if self.is_favourite => 1,
            _ if self.is_low_priority => 3,
            _ => 2,
        }
    }
}

/// Sorts descending. The server's recency stamp is primary: it's current for
/// every room, while latest-event timestamps are only kept fresh for rooms
/// shown on screen (see `sync::track_latest_event`). The two are different
/// scales, so rooms without a stamp sort after, by timestamp.
type SortKey = (bool, u64);

fn sort_key(latest_ts: Option<u64>, recency_stamp: Option<u64>) -> SortKey {
    match recency_stamp {
        Some(stamp) => (true, stamp),
        None => (false, latest_ts.unwrap_or(0)),
    }
}

/// Sorts newest first. Keys are computed once per room: `latest_event()` is not cheap.
pub fn sort_rooms_by_recency(rooms: &mut Vec<Room>) {
    let mut keyed: Vec<(SortKey, Room)> = rooms
        .drain(..)
        .map(|r| {
            let key = sort_key(latest_event_ts(&r), r.recency_stamp().map(u64::from));
            (key, r)
        })
        .collect();
    keyed.sort_unstable_by(|a, b| b.0.cmp(&a.0));
    rooms.extend(keyed.into_iter().map(|(_, r)| r));
}

/// Sections (invites, favourites, rooms, low priority), each newest first.
/// Pending local changes are applied on top of the room state.
fn build() -> Vec<RoomSummary> {
    let Some(client) = CLIENT.get() else {
        return vec![];
    };
    let pending = PENDING.lock().unwrap().clone();
    let mut rooms: Vec<RoomSummary> = client
        .joined_rooms()
        .into_iter()
        .chain(client.invited_rooms())
        .map(RoomSummary::new)
        .filter_map(|mut s| {
            if let Some(p) = pending.get(&s.room_id) {
                if p.left {
                    return None;
                }
                p.apply(&mut s);
            }
            Some(s)
        })
        .collect();
    sort_summaries(&mut rooms);
    rooms
}

/// Local changes shown before the server confirms them, so actions feel
/// instant instead of waiting for the sync round trip (see `room_actions`).
#[derive(Clone, Copy, Default, Debug, PartialEq)]
pub struct Pending {
    pub favourite: Option<bool>,
    pub low_priority: Option<bool>,
    pub marked_unread: Option<bool>,
    pub muted: Option<bool>,
    /// Marked read: show no unread counts.
    pub read: bool,
    /// Left or declined: hide the room.
    pub left: bool,
}

impl Pending {
    fn apply(&self, s: &mut RoomSummary) {
        if let Some(on) = self.favourite {
            s.is_favourite = on;
            // The server drops the other tag too (see `Room::set_is_favourite`).
            if on {
                s.is_low_priority = false;
            }
        }
        if let Some(on) = self.low_priority {
            s.is_low_priority = on;
            if on {
                s.is_favourite = false;
            }
        }
        if self.read {
            s.unread_messages = 0;
            s.notifications = 0;
            s.mentions = 0;
            s.marked_unread = false;
        }
        if let Some(on) = self.marked_unread {
            s.marked_unread = on;
        }
        if let Some(on) = self.muted {
            s.is_muted = on;
        }
    }
}

static PENDING: LazyLock<Mutex<HashMap<String, Pending>>> = LazyLock::new(Default::default);

/// Changes a room's pending overrides and republishes the list.
pub fn update_pending(room_id: &str, change: impl FnOnce(&mut Pending)) {
    {
        let mut pending = PENDING.lock().unwrap();
        let entry = pending.entry(room_id.to_string()).or_default();
        change(entry);
        if *entry == Pending::default() {
            pending.remove(room_id);
        }
    }
    refresh("pending");
}

fn sort_summaries(rooms: &mut [RoomSummary]) {
    rooms.sort_unstable_by(|a, b| a.rank().cmp(&b.rank()).then(b.sort_key.cmp(&a.sort_key)));
}

/// A published room list; `version` changes whenever `rooms` does and is 0
/// until the first build (the UI shows a spinner until then).
#[derive(Clone, Default)]
pub struct RoomListSnapshot {
    pub version: u64,
    pub rooms: Arc<Vec<RoomSummary>>,
}

static ROOM_LIST: LazyLock<(
    watch::Sender<RoomListSnapshot>,
    watch::Receiver<RoomListSnapshot>,
)> = LazyLock::new(|| watch::channel(RoomListSnapshot::default()));

pub fn receiver() -> &'static watch::Receiver<RoomListSnapshot> {
    &ROOM_LIST.1
}

/// Requests a rebuild. Never builds on the caller's thread: a single task
/// collects requests for `COALESCE` and rebuilds once. Building costs ~1.5µs
/// per room (several ms on large accounts), and room info updates arrive one
/// per room, so a burst of hundreds becomes one rebuild.
pub fn refresh(source: &'static str) {
    let _ = REFRESHER.send(source);
}

const COALESCE: std::time::Duration = std::time::Duration::from_millis(16);

static REFRESHER: LazyLock<tokio::sync::mpsc::UnboundedSender<&'static str>> =
    LazyLock::new(|| {
        let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel();
        tokio::spawn(async move {
            while let Some(source) = rx.recv().await {
                tokio::time::sleep(COALESCE).await;
                let mut requests = 1;
                while rx.try_recv().is_ok() {
                    requests += 1;
                }
                rebuild(source, requests);
            }
        });
        tx
    });

/// Builds the list and publishes it if anything visible changed.
fn rebuild(source: &'static str, requests: usize) {
    let start = std::time::Instant::now();
    let rooms = build();
    let count = rooms.len();
    let invites = rooms.iter().filter(|r| r.is_invite).count();
    // Rows near the top are what's on screen: previews still missing there.
    let top_missing_preview = rooms.iter().take(20).filter(|r| r.needs_preview).count();
    let changed = ROOM_LIST.0.send_if_modified(|current| {
        // Always publish the first build, even if empty.
        if current.version > 0 && *current.rooms == rooms {
            return false;
        }
        current.version += 1;
        current.rooms = Arc::new(rooms);
        true
    });
    if changed {
        // Other listeners (invite screen, session banner) key off sync ticks.
        let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
    }
    tracing::debug!(
        target: PERF,
        source,
        requests,
        changed,
        rooms = count,
        invites,
        top_missing_preview,
        "room list refresh {}µs",
        start.elapsed().as_micros()
    );
}

/// `is_direct` of our invite per invited room; `Room::is_dm` is unreliable
/// before joining and the real flag needs an async store read.
static INVITE_IS_DIRECT: LazyLock<Mutex<HashMap<String, bool>>> = LazyLock::new(Default::default);

pub fn invite_is_direct(room_id: &matrix_sdk::ruma::RoomId) -> Option<bool> {
    INVITE_IS_DIRECT
        .lock()
        .unwrap()
        .get(room_id.as_str())
        .copied()
}

/// Resolves `is_direct` for invites not seen yet; refreshes the list if any were new.
pub async fn resolve_invite_dm_flags(client: &Client) {
    let mut resolved = Vec::new();
    for room in client.invited_rooms() {
        if invite_is_direct(room.room_id()).is_none() {
            let is_direct = room.is_direct().await.unwrap_or(false);
            resolved.push((room.room_id().to_string(), is_direct));
        }
    }
    if resolved.is_empty() {
        return;
    }
    INVITE_IS_DIRECT.lock().unwrap().extend(resolved);
    refresh("invite_dm");
}

#[cfg(test)]
pub(crate) mod test_support {
    use matrix_sdk::ruma::RoomId;
    use matrix_sdk::ruma::serde::Raw;
    use matrix_sdk::test_utils::mocks::MatrixMockServer;
    use matrix_sdk_test::{InvitedRoomBuilder, JoinedRoomBuilder};

    use super::RoomSummary;

    pub async fn server() -> (MatrixMockServer, matrix_sdk::Client) {
        let server = MatrixMockServer::new().await;
        let client = server.client_builder().build().await;
        (server, client)
    }

    /// A joined room carrying the given room account data events.
    pub async fn joined(
        server: &MatrixMockServer,
        client: &matrix_sdk::Client,
        id: &RoomId,
        account_data: Vec<serde_json::Value>,
    ) -> RoomSummary {
        let mut builder = JoinedRoomBuilder::new(id);
        for event in account_data {
            builder = builder.add_account_data(Raw::from_json_string(event.to_string()).unwrap());
        }
        RoomSummary::new(server.sync_room(client, builder).await)
    }

    pub async fn invited(
        server: &MatrixMockServer,
        client: &matrix_sdk::Client,
        id: &RoomId,
    ) -> RoomSummary {
        RoomSummary::new(server.sync_room(client, InvitedRoomBuilder::new(id)).await)
    }

    pub fn tag(name: &str) -> serde_json::Value {
        serde_json::json!({ "type": "m.tag", "content": { "tags": { name: {} } } })
    }

    pub fn marked_unread() -> serde_json::Value {
        serde_json::json!({ "type": "m.marked_unread", "content": { "unread": true } })
    }
}

#[cfg(test)]
mod tests {
    use matrix_sdk::ruma::room_id;

    use super::test_support::{invited, joined, marked_unread, server, tag};
    use super::*;

    #[tokio::test]
    async fn sections_order_invites_favourites_rooms_low_priority() {
        let (server, client) = server().await;
        let low = joined(
            &server,
            &client,
            room_id!("!low:x"),
            vec![tag("m.lowpriority")],
        )
        .await;
        let normal = joined(&server, &client, room_id!("!normal:x"), vec![]).await;
        let fav = joined(
            &server,
            &client,
            room_id!("!fav:x"),
            vec![tag("m.favourite")],
        )
        .await;
        let invite = invited(&server, &client, room_id!("!inv:x")).await;
        assert!(fav.is_favourite && low.is_low_priority);

        let mut rooms = vec![low, normal, fav, invite];
        for r in &mut rooms {
            r.sort_key = (false, 0);
        }
        sort_summaries(&mut rooms);
        let order: Vec<&str> = rooms.iter().map(|r| r.room_id.as_str()).collect();
        assert_eq!(order, ["!inv:x", "!fav:x", "!normal:x", "!low:x"]);
    }

    #[tokio::test]
    async fn invites_sort_first_even_when_older() {
        let (server, client) = server().await;
        let mut room = joined(&server, &client, room_id!("!joined:x"), vec![]).await;
        room.sort_key = (true, u64::MAX);
        let mut rooms = vec![room, invited(&server, &client, room_id!("!inv:x")).await];
        sort_summaries(&mut rooms);
        assert!(rooms[0].is_invite);
    }

    #[tokio::test]
    async fn flags_from_room_state() {
        let (server, client) = server().await;
        let marked = joined(&server, &client, room_id!("!m:x"), vec![marked_unread()]).await;
        let invite = invited(&server, &client, room_id!("!i:x")).await;
        let plain = joined(&server, &client, room_id!("!p:x"), vec![]).await;
        assert!(marked.marked_unread && marked.is_unread());
        assert!(invite.is_invite && invite.is_unread());
        assert!(!plain.is_unread());
    }

    /// The room list refreshes on room updates or notable room info updates; an
    /// account-data echo (tag, unread marker) must trigger at least one of them.
    #[tokio::test]
    async fn account_data_echo_triggers_a_refresh_signal() {
        let (server, client) = server().await;
        joined(&server, &client, room_id!("!r:x"), vec![]).await;

        for echo in [tag("m.favourite"), marked_unread()] {
            let mut room_updates = client.subscribe_to_all_room_updates();
            let mut info_updates = client.room_info_notable_update_receiver();
            let after = joined(&server, &client, room_id!("!r:x"), vec![echo.clone()]).await;
            assert!(after.is_favourite || after.marked_unread);
            let got_room_update = room_updates.try_recv().is_ok();
            let got_info_update = info_updates.try_recv().is_ok();
            assert!(
                got_room_update || got_info_update,
                "no refresh signal for {echo}: room_update={got_room_update} info_update={got_info_update}"
            );
        }
    }

    #[tokio::test]
    async fn pending_overrides_apply_like_the_server_would() {
        let (server, client) = server().await;
        let low = joined(
            &server,
            &client,
            room_id!("!r:x"),
            vec![tag("m.lowpriority")],
        )
        .await;

        let mut s = low.clone();
        Pending {
            favourite: Some(true),
            ..Default::default()
        }
        .apply(&mut s);
        assert!(
            s.is_favourite && !s.is_low_priority,
            "favourite drops low priority"
        );

        let mut s = joined(&server, &client, room_id!("!m:x"), vec![marked_unread()]).await;
        Pending {
            read: true,
            ..Default::default()
        }
        .apply(&mut s);
        assert!(!s.is_unread(), "mark read clears the unread state");

        let mut s = low.clone();
        Pending::default().apply(&mut s);
        assert!(s == low, "no override, no change");
    }

    #[tokio::test]
    async fn tag_change_is_a_visible_change() {
        let (server, client) = server().await;
        let before = joined(&server, &client, room_id!("!r:x"), vec![]).await;
        let after = joined(&server, &client, room_id!("!r:x"), vec![tag("m.favourite")]).await;
        assert!(before != after);
    }

    #[tokio::test]
    async fn dm_invite_is_resolved_from_is_direct() {
        use matrix_sdk::ruma::{room_id, serde::Raw};
        use matrix_sdk::test_utils::mocks::MatrixMockServer;
        use matrix_sdk_test::InvitedRoomBuilder;

        let server = MatrixMockServer::new().await;
        let client = server.client_builder().build().await;
        let member = |is_direct: bool| {
            Raw::from_json_string(
                serde_json::json!({
                    "type": "m.room.member",
                    "state_key": "@example:localhost",
                    "sender": "@alice:example.org",
                    "content": { "membership": "invite", "is_direct": is_direct },
                })
                .to_string(),
            )
            .unwrap()
        };
        server
            .sync_room(
                &client,
                InvitedRoomBuilder::new(room_id!("!dm:x")).add_state_event(member(true)),
            )
            .await;
        server
            .sync_room(
                &client,
                InvitedRoomBuilder::new(room_id!("!group:x")).add_state_event(member(false)),
            )
            .await;

        resolve_invite_dm_flags(&client).await;
        assert_eq!(invite_is_direct(room_id!("!dm:x")), Some(true));
        assert_eq!(invite_is_direct(room_id!("!group:x")), Some(false));
    }

    #[test]
    fn sort_key_prefers_recency_stamp() {
        assert_eq!(sort_key(Some(10), Some(99)), (true, 99));
    }

    #[test]
    fn sort_key_falls_back_to_timestamp_after_stamped_rooms() {
        assert_eq!(sort_key(Some(10), None), (false, 10));
        assert_eq!(sort_key(None, None), (false, 0));
        assert!(sort_key(None, Some(1)) > sort_key(Some(u64::MAX), None));
    }
}
