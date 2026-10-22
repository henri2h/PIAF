//! Joined spaces, from matrix-sdk-ui's `SpaceService` (built from the
//! `m.space.child` / `m.space.parent` state the sliding sync already loads).
//! Each top-level space lists the rooms it contains, its sub-spaces' included,
//! so the room list can be narrowed to it.

use std::collections::HashSet;
use std::sync::{Arc, LazyLock, Mutex};

use eyeball_im::Vector;
use futures::StreamExt;
use matrix_sdk::Client;
use matrix_sdk_ui::spaces::{SpaceFilter, SpaceService};
use tokio::sync::watch;

/// A joined top-level space.
#[derive(Clone, Debug, PartialEq)]
pub struct Space {
    pub room_id: String,
    pub name: String,
    /// Rooms in it, at any depth.
    pub rooms: Arc<HashSet<String>>,
    pub subspaces: Vec<SubSpace>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct SubSpace {
    pub room_id: String,
    pub name: String,
    pub rooms: Arc<HashSet<String>>,
}

impl Space {
    /// The rooms of `sub` if it is one of its sub-spaces, else all of them.
    pub fn scope(&self, sub: Option<&str>) -> Arc<HashSet<String>> {
        sub.and_then(|sub| self.subspaces.iter().find(|s| s.room_id == sub))
            .map_or_else(|| self.rooms.clone(), |s| s.rooms.clone())
    }
}

/// One of the service's filters: level 0 is a top-level space with its direct
/// children (sub-spaces included), level 1 a sub-space with all its descendants.
#[derive(Clone, Debug)]
pub struct Entry {
    pub room_id: String,
    pub name: String,
    pub level: u8,
    pub descendants: Vec<String>,
}

impl From<&SpaceFilter> for Entry {
    fn from(f: &SpaceFilter) -> Self {
        Self {
            room_id: f.space_room.room_id.to_string(),
            name: f.space_room.display_name.clone(),
            level: f.level,
            descendants: f.descendants.iter().map(|id| id.to_string()).collect(),
        }
    }
}

/// Spaces in the service's order. A sub-space can belong to several spaces
/// (it follows each of them in `entries`), so it is matched by membership.
pub fn build(entries: &[Entry]) -> Vec<Space> {
    entries
        .iter()
        .filter(|e| e.level == 0)
        .map(|top| {
            let children: HashSet<&str> = top.descendants.iter().map(String::as_str).collect();
            let mut seen = HashSet::new();
            let subspaces: Vec<SubSpace> = entries
                .iter()
                .filter(|e| e.level == 1 && children.contains(e.room_id.as_str()))
                .filter(|e| seen.insert(e.room_id.as_str()))
                .map(|e| SubSpace {
                    room_id: e.room_id.clone(),
                    name: e.name.clone(),
                    rooms: Arc::new(e.descendants.iter().cloned().collect()),
                })
                .collect();
            let mut rooms: HashSet<String> = top.descendants.iter().cloned().collect();
            for sub in &subspaces {
                rooms.extend(sub.rooms.iter().cloned());
            }
            Space {
                room_id: top.room_id.clone(),
                name: top.name.clone(),
                rooms: Arc::new(rooms),
                subspaces,
            }
        })
        .collect()
}

static SPACES: LazyLock<(watch::Sender<Vec<Space>>, watch::Receiver<Vec<Space>>)> =
    LazyLock::new(|| watch::channel(vec![]));

pub fn receiver() -> &'static watch::Receiver<Vec<Space>> {
    &SPACES.1
}

static TASK: Mutex<Option<tokio::task::JoinHandle<()>>> = Mutex::new(None);

/// Follows the joined spaces until [`stop`].
pub fn start(client: Client) {
    let task = tokio::spawn(async move {
        let service = SpaceService::new(client).await;
        let (mut filters, mut updates) = service.subscribe_to_space_filters().await;
        publish(&filters);
        while let Some(diffs) = updates.next().await {
            for diff in diffs {
                diff.apply(&mut filters);
            }
            publish(&filters);
        }
    });
    if let Some(old) = TASK.lock().unwrap().replace(task) {
        old.abort();
    }
}

pub fn stop() {
    if let Some(task) = TASK.lock().unwrap().take() {
        task.abort();
    }
    SPACES.0.send_replace(vec![]);
    SELECTION.0.send_replace(Selection::default());
}

#[cfg(test)]
pub fn set_for_test(spaces: Vec<Space>) {
    SPACES.0.send_replace(spaces);
}

fn publish(filters: &Vector<SpaceFilter>) {
    let entries: Vec<Entry> = filters.iter().map(Entry::from).collect();
    let spaces = build(&entries);
    tracing::debug!(
        rooms_per_space = ?spaces.iter().map(|s| s.rooms.len()).collect::<Vec<_>>(),
        "spaces updated"
    );
    SPACES.0.send_if_modified(|current| {
        let changed = *current != spaces;
        if changed {
            *current = spaces;
        }
        changed
    });
}

/// The space picked in the desktop rail (`None`: all chats) and one of its
/// sub-spaces. Global, so it outlives the home page.
#[derive(Clone, Debug, Default, PartialEq)]
pub struct Selection {
    pub space: Option<String>,
    pub sub: Option<String>,
}

static SELECTION: LazyLock<(watch::Sender<Selection>, watch::Receiver<Selection>)> =
    LazyLock::new(|| watch::channel(Selection::default()));

pub fn selection() -> &'static watch::Receiver<Selection> {
    &SELECTION.1
}

pub fn select(selection: Selection) {
    SELECTION.0.send_replace(selection);
}

/// The selected space, if it still exists.
pub fn selected<'a>(spaces: &'a [Space], selection: &Selection) -> Option<&'a Space> {
    let id = selection.space.as_deref()?;
    spaces.iter().find(|s| s.room_id == id)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn entry(id: &str, level: u8, descendants: &[&str]) -> Entry {
        Entry {
            room_id: id.into(),
            name: id.trim_start_matches('!').into(),
            level,
            descendants: descendants.iter().map(|d| d.to_string()).collect(),
        }
    }

    /// As the service lists them: each top-level space, then its sub-spaces.
    fn entries() -> Vec<Entry> {
        vec![
            entry("!rust", 0, &["!general", "!async", "!embedded"]),
            entry("!embedded", 1, &["!esp", "!stm", "!boards"]),
            entry("!matrix", 0, &["!synapse", "!embedded"]),
            entry("!embedded", 1, &["!esp", "!stm", "!boards"]),
        ]
    }

    #[test]
    fn spaces_keep_the_service_order() {
        let spaces = build(&entries());
        let ids: Vec<_> = spaces.iter().map(|s| s.room_id.as_str()).collect();
        assert_eq!(ids, ["!rust", "!matrix"]);
    }

    #[test]
    fn a_space_holds_its_sub_spaces_rooms() {
        let spaces = build(&entries());
        let rust = &spaces[0];
        assert_eq!(rust.subspaces.len(), 1);
        assert_eq!(rust.subspaces[0].room_id, "!embedded");
        for room in ["!general", "!async", "!esp", "!stm", "!boards"] {
            assert!(rust.rooms.contains(room), "{room}");
        }
        assert!(!rust.rooms.contains("!synapse"));
    }

    #[test]
    fn a_shared_sub_space_belongs_to_each_parent_once() {
        let spaces = build(&entries());
        assert_eq!(spaces[1].subspaces.len(), 1);
        assert!(spaces[1].rooms.contains("!esp"));
    }

    #[test]
    fn scope_narrows_to_a_sub_space() {
        let spaces = build(&entries());
        let rust = &spaces[0];
        assert_eq!(rust.scope(Some("!embedded")).len(), 3);
        assert!(!rust.scope(Some("!embedded")).contains("!general"));
        assert_eq!(rust.scope(Some("!unknown")), rust.rooms);
        assert_eq!(rust.scope(None), rust.rooms);
    }

    #[test]
    fn selection_of_a_left_space_is_none() {
        let spaces = build(&entries());
        let gone = Selection {
            space: Some("!left".into()),
            sub: None,
        };
        assert!(selected(&spaces, &gone).is_none());
        let rust = Selection {
            space: Some("!rust".into()),
            sub: None,
        };
        assert_eq!(selected(&spaces, &rust).unwrap().name, "rust");
    }
}
