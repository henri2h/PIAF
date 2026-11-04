use std::collections::HashMap;
use std::sync::Arc;

use freya::prelude::*;
use futures::{FutureExt, StreamExt};
use matrix_sdk_ui::timeline::{RoomExt, Timeline, TimelineItem, TimelineUniqueId};
use tokio::sync::mpsc::{UnboundedReceiver, UnboundedSender, unbounded_channel};

use crate::utils::timeline_media::{self, MediaEntry, MediaKind, SharedEntries};

/// Events requested per backward pagination.
const PAGE_EVENTS: u16 = 40;
/// Pages fetched per request while no new entry of the requested kind turns
/// up, before giving up and leaving it to the "Load older" button.
const MAX_EMPTY_PAGES: u32 = 10;

#[derive(Clone, Copy, PartialEq)]
pub(super) enum HistoryState {
    /// More history may hold entries: keep loading as the user scrolls.
    More,
    /// A request found nothing of its kind in `MAX_EMPTY_PAGES` pages.
    Paused,
    /// Reached the start of the room.
    Start,
}

/// Media, files and links of a room, newest first, kept live.
#[derive(Clone, Copy, PartialEq)]
pub(super) struct RoomMedia {
    pub entries: State<SharedEntries>,
    pub loading: State<bool>,
    pub paginating: State<bool>,
    /// Per kind (indexed by `kind_index`): a tab keeps loading while its own
    /// kind turns up, whatever the other tabs find.
    history: State<[HistoryState; 3]>,
    pub failed: State<bool>,
    requests: State<Option<UnboundedSender<MediaKind>>>,
}

fn kind_index(kind: MediaKind) -> usize {
    match kind {
        MediaKind::Image => 0,
        MediaKind::File => 1,
        MediaKind::Link => 2,
    }
}

/// Entries per kind.
type Counts = [usize; 3];

impl RoomMedia {
    /// History state for `kind` (subscribes).
    pub fn history(&self, kind: MediaKind) -> HistoryState {
        self.history.read()[kind_index(kind)]
    }

    /// Loads older history until an entry of `kind` turns up; no-op while a
    /// request is running or once at the start.
    pub fn load_more(&self, kind: MediaKind) {
        if *self.paginating.peek() || self.history.peek()[kind_index(kind)] == HistoryState::Start {
            return;
        }
        let Some(tx) = self.requests.peek().clone() else {
            return;
        };
        let mut paginating = self.paginating;
        if tx.send(kind).is_ok() {
            paginating.set(true);
        }
    }
}

enum Update {
    Entries(Vec<Arc<MediaEntry>>),
    Paged {
        kind: MediaKind,
        at_start: bool,
        found_new: bool,
    },
    Failed,
}

pub(super) fn use_room_media(room_id: &str) -> RoomMedia {
    let media = RoomMedia {
        entries: use_state(SharedEntries::default),
        loading: use_state(|| true),
        paginating: use_state(|| false),
        history: use_state(|| [HistoryState::More; 3]),
        failed: use_state(|| false),
        requests: use_state(|| None),
    };

    use_hook(|| {
        let (request_tx, request_rx) = unbounded_channel::<MediaKind>();
        let (update_tx, mut update_rx) = futures::channel::mpsc::unbounded::<Update>();
        let mut requests = media.requests;
        requests.set(Some(request_tx));

        let room_id = room_id.to_string();
        tokio::spawn(async move {
            if run(&room_id, request_rx, &update_tx).await.is_none() {
                let _ = update_tx.unbounded_send(Update::Failed);
            }
        });

        let RoomMedia {
            mut entries,
            mut loading,
            mut paginating,
            mut history,
            mut failed,
            mut requests,
        } = media;
        spawn(async move {
            while let Some(update) = update_rx.next().await {
                match update {
                    Update::Entries(new) => {
                        // Timeline diffs are mostly receipts and reactions: skip no-ops
                        // (cached entries keep their identity, so this is pointer compares).
                        let new: SharedEntries = new.into_iter().collect();
                        if *entries.peek() != new {
                            entries.set(new);
                        }
                        loading.set(false);
                    }
                    Update::Paged {
                        kind,
                        at_start,
                        found_new,
                    } => {
                        paginating.set(false);
                        let mut states = *history.peek();
                        if at_start {
                            // The start of the room is the start for every kind.
                            states = [HistoryState::Start; 3];
                        } else {
                            states[kind_index(kind)] = if found_new {
                                HistoryState::More
                            } else {
                                HistoryState::Paused
                            };
                        }
                        history.set(states);
                    }
                    Update::Failed => break,
                }
            }
            // The task ended (failure or room gone): stop every spinner.
            failed.set(*loading.peek());
            loading.set(false);
            paginating.set(false);
            history.set([HistoryState::Start; 3]);
            requests.set(None);
        });
    });

    media
}

/// Background side: builds a timeline, publishes entries on every change and
/// paginates on request. `None` when the room or timeline is unavailable.
async fn run(
    room_id: &str,
    mut requests: UnboundedReceiver<MediaKind>,
    updates: &futures::channel::mpsc::UnboundedSender<Update>,
) -> Option<()> {
    let room = crate::utils::matrix::get_room(room_id)?;
    let timeline = Arc::new(room.timeline_builder().build().await.ok()?);
    let (_, mut stream) = timeline.subscribe().await;
    let mut cache = EntryCache::default();
    let mut counts = cache.publish(&timeline, updates).await?;

    loop {
        tokio::select! {
            diffs = stream.next() => {
                diffs?;
                // Diffs arrive in bursts (receipts, reactions, decryption):
                // publish once for everything already queued.
                while let Some(Some(_)) = stream.next().now_or_never() {}
                counts = cache.publish(&timeline, updates).await?;
            }
            kind = requests.recv() => {
                let kind = kind?;
                let i = kind_index(kind);
                let before = counts[i];
                let mut at_start = false;
                for _ in 0..MAX_EMPTY_PAGES {
                    at_start = timeline.paginate_backwards(PAGE_EVENTS).await.unwrap_or(true);
                    counts = cache.publish(&timeline, updates).await?;
                    if at_start || counts[i] > before {
                        break;
                    }
                }
                let found_new = counts[i] > before;
                updates
                    .unbounded_send(Update::Paged { kind, at_start, found_new })
                    .ok()?;
            }
        }
    }
}

/// Entries per timeline item, reused while the item is unchanged: the
/// timeline replaces an item's `Arc` when it changes, so the same `Arc`
/// means the same entries. Keeps a publish proportional to what changed,
/// not to how much history is loaded.
#[derive(Default)]
struct EntryCache(HashMap<TimelineUniqueId, (Arc<TimelineItem>, Vec<Arc<MediaEntry>>)>);

impl EntryCache {
    /// Sends the current entries, newest first; returns how many of each kind.
    async fn publish(
        &mut self,
        timeline: &Timeline,
        updates: &futures::channel::mpsc::UnboundedSender<Update>,
    ) -> Option<Counts> {
        let items = timeline.items().await;
        let mut next = HashMap::with_capacity(self.0.len());
        let mut entries = Vec::new();
        for item in items.iter().rev() {
            let id = item.unique_id();
            let item_entries = match self.0.remove(id) {
                Some((cached, e)) if Arc::ptr_eq(&cached, item) => e,
                _ => timeline_media::entries(item)
                    .into_iter()
                    .map(Arc::new)
                    .collect(),
            };
            // Newest first, and a message's links in reading order.
            entries.extend(item_entries.iter().cloned());
            next.insert(id.clone(), (item.clone(), item_entries));
        }
        self.0 = next;
        let mut counts = [0; 3];
        for entry in &entries {
            counts[kind_index(entry.kind())] += 1;
        }
        updates.unbounded_send(Update::Entries(entries)).ok()?;
        Some(counts)
    }
}
