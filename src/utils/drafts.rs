//! Per-room composer drafts: kept in memory for synchronous reads (room list,
//! composer mount) and mirrored to `drafts.json`.

use std::collections::HashMap;
use std::sync::{LazyLock, Mutex};

use matrix_sdk::ruma::exports::serde_json;

static DRAFTS: LazyLock<Mutex<HashMap<String, String>>> = LazyLock::new(Default::default);
/// Serializes file writes; each write saves the current map, so the last one wins.
static WRITE_LOCK: tokio::sync::Mutex<()> = tokio::sync::Mutex::const_new(());

const PREVIEW_CHARS: usize = 80;

fn file() -> Option<std::path::PathBuf> {
    crate::utils::matrix::DATA_DIR
        .get()
        .and_then(|d| d.parent())
        .map(|p| p.join("drafts.json"))
}

/// Loads drafts from disk. Call once the data dir is known.
pub async fn load() {
    let map: HashMap<String, String> = match file() {
        Some(path) => tokio::fs::read_to_string(path)
            .await
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default(),
        None => HashMap::new(),
    };
    *DRAFTS.lock().unwrap() = map;
}

pub fn get(room_id: &str) -> Option<String> {
    DRAFTS.lock().unwrap().get(room_id).cloned()
}

/// First line of the draft, shortened, for the room list.
pub fn preview(room_id: &str) -> Option<String> {
    get(room_id).map(|d| preview_of(&d))
}

fn preview_of(draft: &str) -> String {
    let line = draft.trim().lines().next().unwrap_or("");
    let mut short: String = line.chars().take(PREVIEW_CHARS).collect();
    if line.chars().count() > PREVIEW_CHARS {
        short.push('…');
    }
    short
}

/// Stores (or, if blank, removes) a draft; wakes the room list if its preview changed.
pub fn set(room_id: &str, text: &str) {
    let changed = {
        let mut map = DRAFTS.lock().unwrap();
        let before = map.get(room_id).map(|d| preview_of(d));
        if text.trim().is_empty() {
            map.remove(room_id);
        } else {
            map.insert(room_id.to_string(), text.to_string());
        }
        before != map.get(room_id).map(|d| preview_of(d))
    };
    if changed {
        crate::utils::room_list::refresh("draft");
    }
    tokio::spawn(persist());
}

pub fn clear(room_id: &str) {
    set(room_id, "");
}

async fn persist() {
    let Some(path) = file() else { return };
    let _guard = WRITE_LOCK.lock().await;
    let json = serde_json::to_string(&*DRAFTS.lock().unwrap());
    if let Ok(json) = json {
        let _ = tokio::fs::write(path, json).await;
    }
}

#[cfg(test)]
mod tests {
    use super::preview_of;

    #[test]
    fn preview_is_first_line_trimmed() {
        assert_eq!(preview_of("  hello\nworld"), "hello");
    }

    #[test]
    fn preview_is_shortened() {
        let long = "x".repeat(100);
        let p = preview_of(&long);
        assert_eq!(p.chars().count(), 81);
        assert!(p.ends_with('…'));
    }
}
