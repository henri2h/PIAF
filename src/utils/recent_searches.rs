//! Queries the user searched for (keyboard search key or an opened result),
//! newest first, mirrored to `recent_searches.json`.

use std::sync::Mutex;

use matrix_sdk::ruma::exports::serde_json;

const MAX: usize = 8;

/// `None` until read from disk.
static RECENT: Mutex<Option<Vec<String>>> = Mutex::new(None);

fn file() -> Option<std::path::PathBuf> {
    crate::utils::matrix::DATA_DIR
        .get()
        .and_then(|d| d.parent())
        .map(|p| p.join("recent_searches.json"))
}

fn with<T>(f: impl FnOnce(&mut Vec<String>) -> T) -> T {
    let mut recent = RECENT.lock().unwrap();
    let list = recent.get_or_insert_with(|| {
        file()
            .and_then(|path| std::fs::read_to_string(path).ok())
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default()
    });
    f(list)
}

fn save(list: &[String]) {
    let (Some(path), Ok(json)) = (file(), serde_json::to_string(list)) else {
        return;
    };
    tokio::spawn(async move {
        let _ = tokio::fs::write(path, json).await;
    });
}

pub fn list() -> Vec<String> {
    with(|list| list.clone())
}

/// Puts `query` first (once, ignoring case), keeping the newest [`MAX`].
pub fn add(query: &str) {
    let query = query.trim();
    if query.is_empty() {
        return;
    }
    with(|list| {
        push_front(list, query);
        save(list);
    });
}

pub fn remove(query: &str) {
    with(|list| {
        list.retain(|q| q != query);
        save(list);
    });
}

pub fn clear() {
    with(|list| {
        list.clear();
        save(list);
    });
}

fn push_front(list: &mut Vec<String>, query: &str) {
    list.retain(|q| !q.eq_ignore_ascii_case(query));
    list.insert(0, query.to_string());
    list.truncate(MAX);
}

#[cfg(test)]
mod tests {
    use super::{MAX, push_front};

    #[test]
    fn newest_first_without_duplicates() {
        let mut list = vec![];
        push_front(&mut list, "alice");
        push_front(&mut list, "bob");
        push_front(&mut list, "Alice");
        assert_eq!(list, vec!["Alice", "bob"]);
    }

    #[test]
    fn keeps_the_newest() {
        let mut list = vec![];
        for i in 0..MAX + 3 {
            push_front(&mut list, &i.to_string());
        }
        assert_eq!(list.len(), MAX);
        assert_eq!(list[0], (MAX + 2).to_string());
    }
}
