use std::collections::HashMap;

use matrix_sdk::Room;
use matrix_sdk::ruma::events::macros::EventContent;
use matrix_sdk::ruma::events::tag::{TagInfo, TagName};
use serde::{Deserialize, Serialize};

const RECONTACT_TAG: &str = "u.cc.carnot.piaf.recontact";

/// Room-scoped account_data recording that a room was archived (swiped away
/// because it's "done") while its latest event was at `until_ts`. The room
/// stays hidden from the main list only while no newer event has arrived.
#[derive(Clone, Debug, Default, Deserialize, Serialize, PartialEq, EventContent)]
#[ruma_event(type = "cc.carnot.piaf.archived", kind = RoomAccountData)]
pub struct ArchivedEventContent {
    pub until_ts: u64,
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct RoomMailboxState {
    pub recontact: bool,
    pub archived_until_ts: Option<u64>,
}

/// True while the room should stay hidden from the main list: it was
/// archived and no event newer than the archive point has arrived since.
pub fn is_archived_hidden(latest_ts: Option<u64>, archived_until_ts: Option<u64>) -> bool {
    match (archived_until_ts, latest_ts) {
        (Some(until_ts), Some(latest)) => latest <= until_ts,
        (Some(_), None) => true,
        (None, _) => false,
    }
}

/// [`is_archived_hidden`] for a room, looked up in the mailbox state map.
pub fn is_room_archived(room: &Room, mailbox: &HashMap<String, RoomMailboxState>) -> bool {
    let archived_until_ts = mailbox
        .get(room.room_id().as_str())
        .and_then(|s| s.archived_until_ts);
    is_archived_hidden(
        crate::utils::matrix::latest_event_ts(room),
        archived_until_ts,
    )
}

async fn read_room_state(room: &Room) -> RoomMailboxState {
    let recontact = room
        .tags()
        .await
        .ok()
        .flatten()
        .is_some_and(|tags| tags.contains_key(&TagName::from(RECONTACT_TAG)));

    let archived_until_ts = room
        .account_data_static::<ArchivedEventContent>()
        .await
        .ok()
        .flatten()
        .and_then(|raw| raw.deserialize().ok())
        .map(|ev| ev.content.until_ts);

    RoomMailboxState {
        recontact,
        archived_until_ts,
    }
}

/// Loads mailbox state (recontact tag + archived account_data) for every
/// joined room and publishes it to `ROOM_MAILBOX_TX`.
pub async fn load_room_mailbox(client: &matrix_sdk::Client) {
    let mut map = HashMap::new();
    for room in client.joined_rooms() {
        let room_id = room.room_id().to_string();
        let state = read_room_state(&room).await;
        map.insert(room_id, state);
    }
    if let Some(tx) = crate::ROOM_MAILBOX_TX.get() {
        let _ = tx.send(map);
    }
}

/// Toggle the "recontact" tag on a room and publish the updated cache.
pub async fn toggle_recontact(room_id: &str) {
    let Some(room) = crate::utils::matrix::get_room(room_id) else {
        return;
    };

    let currently_on = crate::ROOM_MAILBOX_RX
        .get()
        .and_then(|rx| rx.borrow().get(room_id).map(|s| s.recontact))
        .unwrap_or(false);

    // Publish before the request, not after: the row is meant to leave the list
    // the instant it is swiped, and waiting on the homeserver makes the gesture
    // feel like it did nothing. Rolled back below if the request fails.
    set_recontact(room_id, !currently_on);

    let tag = TagName::from(RECONTACT_TAG);
    let ok = if currently_on {
        room.remove_tag(tag).await.is_ok()
    } else {
        room.set_tag(tag, TagInfo::new()).await.is_ok()
    };
    if !ok {
        set_recontact(room_id, currently_on);
    }
}

fn set_recontact(room_id: &str, recontact: bool) {
    if let Some(tx) = crate::ROOM_MAILBOX_TX.get() {
        tx.send_modify(|map| {
            map.entry(room_id.to_string()).or_default().recontact = recontact;
        });
    }
}

fn set_archived_until(room_id: &str, until_ts: Option<u64>) {
    if let Some(tx) = crate::ROOM_MAILBOX_TX.get() {
        tx.send_modify(|map| {
            map.entry(room_id.to_string())
                .or_default()
                .archived_until_ts = until_ts;
        });
    }
}

/// Archive a room: record its current latest-event timestamp so it stays
/// hidden from the main list until a newer message arrives.
pub async fn archive_room(room_id: &str) {
    let Some(room) = crate::utils::matrix::get_room(room_id) else {
        return;
    };

    let until_ts: u64 = room
        .latest_event()
        .timestamp()
        .map(|ts| ts.get().into())
        .unwrap_or(0);

    let previous = crate::ROOM_MAILBOX_RX
        .get()
        .and_then(|rx| rx.borrow().get(room_id).and_then(|s| s.archived_until_ts));

    // Optimistic, same as `toggle_recontact`.
    set_archived_until(room_id, Some(until_ts));

    if room
        .set_account_data(ArchivedEventContent { until_ts })
        .await
        .is_err()
    {
        set_archived_until(room_id, previous);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hidden_while_no_newer_event_arrived() {
        assert!(is_archived_hidden(Some(100), Some(100)));
        assert!(is_archived_hidden(Some(50), Some(100)));
    }

    #[test]
    fn visible_once_a_newer_event_arrives() {
        assert!(!is_archived_hidden(Some(150), Some(100)));
    }

    #[test]
    fn visible_when_never_archived() {
        assert!(!is_archived_hidden(Some(100), None));
    }

    #[test]
    fn hidden_when_archived_but_no_latest_event_known() {
        assert!(is_archived_hidden(None, Some(100)));
    }
}
