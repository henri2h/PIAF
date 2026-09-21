use matrix_sdk::Client;
use matrix_sdk::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

use crate::utils::matrix::CLIENT;

/// Custom global account_data event holding all of the user's bookmark lists.
/// Synced across devices like any other account_data (e.g. `m.direct`).
#[derive(Clone, Debug, Default, Deserialize, Serialize, PartialEq, EventContent)]
#[ruma_event(type = "cc.carnot.piaf.bookmarks", kind = GlobalAccountData)]
pub struct BookmarksEventContent {
    pub lists: Vec<BookmarkList>,
}

#[derive(Clone, Debug, Default, Deserialize, Serialize, PartialEq)]
pub struct BookmarkList {
    pub id: String,
    pub name: String,
    pub entries: Vec<BookmarkEntry>,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
pub struct BookmarkEntry {
    pub room_id: String,
    pub event_id: String,
    pub room_name: String,
    pub sender_display: String,
    pub message_preview: String,
    pub added_ts_ms: u64,
}

fn now_ms() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as u64
}

fn new_list_id() -> String {
    format!("{}-{}", now_ms(), rand::random::<u32>())
}

pub async fn load_bookmarks(client: &Client) -> BookmarksEventContent {
    let Ok(Some(raw)) = client
        .account()
        .account_data::<BookmarksEventContent>()
        .await
    else {
        return BookmarksEventContent::default();
    };
    raw.deserialize().unwrap_or_default()
}

pub async fn save_bookmarks(
    client: &Client,
    content: &BookmarksEventContent,
) -> matrix_sdk::Result<()> {
    client.account().set_account_data(content.clone()).await?;
    Ok(())
}

pub fn create_list(content: &mut BookmarksEventContent, name: String) -> String {
    let id = new_list_id();
    content.lists.push(BookmarkList {
        id: id.clone(),
        name,
        entries: Vec::new(),
    });
    id
}

pub fn rename_list(content: &mut BookmarksEventContent, list_id: &str, new_name: String) {
    if let Some(list) = content.lists.iter_mut().find(|l| l.id == list_id) {
        list.name = new_name;
    }
}

pub fn delete_list(content: &mut BookmarksEventContent, list_id: &str) {
    content.lists.retain(|l| l.id != list_id);
}

pub fn add_entry(content: &mut BookmarksEventContent, list_id: &str, entry: BookmarkEntry) {
    if let Some(list) = content.lists.iter_mut().find(|l| l.id == list_id) {
        let already_exists = list
            .entries
            .iter()
            .any(|e| e.room_id == entry.room_id && e.event_id == entry.event_id);
        if !already_exists {
            list.entries.push(entry);
        }
    }
}

pub fn remove_entry(
    content: &mut BookmarksEventContent,
    list_id: &str,
    room_id: &str,
    event_id: &str,
) {
    if let Some(list) = content.lists.iter_mut().find(|l| l.id == list_id) {
        list.entries
            .retain(|e| !(e.room_id == room_id && e.event_id == event_id));
    }
}

/// Single write path for all bookmark mutations: applies `f` to the current
/// state, persists it to account_data, and publishes the result to
/// `BOOKMARKS_TX` so every subscribed component re-renders.
pub async fn mutate_bookmarks(f: impl FnOnce(&mut BookmarksEventContent)) {
    let Some(client) = CLIENT.get().cloned() else {
        return;
    };
    let mut content = crate::BOOKMARKS_RX
        .get()
        .map(|rx| rx.borrow().clone())
        .unwrap_or_default();
    f(&mut content);
    if save_bookmarks(&client, &content).await.is_ok() {
        if let Some(tx) = crate::BOOKMARKS_TX.get() {
            let _ = tx.send(content);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn create_list_then_add_and_remove_entry() {
        let mut content = BookmarksEventContent::default();
        let list_id = create_list(&mut content, "Investigate".to_string());
        assert_eq!(content.lists.len(), 1);

        let entry = BookmarkEntry {
            room_id: "!room:example.org".to_string(),
            event_id: "$event1".to_string(),
            room_name: "Room".to_string(),
            sender_display: "Alice".to_string(),
            message_preview: "hello".to_string(),
            added_ts_ms: 1,
        };
        add_entry(&mut content, &list_id, entry.clone());
        assert_eq!(content.lists[0].entries.len(), 1);

        // Adding the same entry again is a no-op (dedup).
        add_entry(&mut content, &list_id, entry.clone());
        assert_eq!(content.lists[0].entries.len(), 1);

        remove_entry(&mut content, &list_id, &entry.room_id, &entry.event_id);
        assert!(content.lists[0].entries.is_empty());
    }

    #[test]
    fn rename_and_delete_list() {
        let mut content = BookmarksEventContent::default();
        let list_id = create_list(&mut content, "Old name".to_string());
        rename_list(&mut content, &list_id, "New name".to_string());
        assert_eq!(content.lists[0].name, "New name");

        delete_list(&mut content, &list_id);
        assert!(content.lists.is_empty());
    }
}
