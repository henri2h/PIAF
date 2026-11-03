//! Warms the event cache of the rooms most likely to be opened next.
//!
//! The room list syncs one event per room, so a room never opened has no
//! history stored and its first open waits for `/messages`. Fetching the
//! first page of the top rooms once, in the background, makes those opens
//! come from the store.

use std::sync::atomic::Ordering;
use std::time::Duration;

use crate::logging::PERF;
use crate::utils::room_list;

/// Rooms warmed, in list order.
const ROOMS: usize = 10;
/// Events per room: what the room page's first page asks for.
const EVENTS: u16 = 40;
/// Lets the first screen, the room list and the sync settle first.
const START_DELAY: Duration = Duration::from_secs(4);
/// A room that doesn't answer doesn't hold up the next ones.
const ROOM_TIMEOUT: Duration = Duration::from_secs(15);

/// Starts the prefetch once the room list is built. Call once per process.
pub fn start() {
    tokio::spawn(async {
        let mut list = room_list::receiver().clone();
        if list.wait_for(|snapshot| snapshot.version > 0).await.is_err() {
            return;
        }
        tokio::time::sleep(START_DELAY).await;
        if crate::DISCONNECTED.load(Ordering::Relaxed) {
            return;
        }
        let rooms: Vec<_> = list
            .borrow()
            .rooms
            .iter()
            .filter(|summary| !summary.is_invite)
            .take(ROOMS)
            .map(|summary| summary.room.clone())
            .collect();
        let started = std::time::Instant::now();
        // One at a time: a burst would compete with the sync and the room
        // the user opens meanwhile.
        for room in rooms {
            let Ok((cache, _guard)) = room.event_cache().await else {
                continue;
            };
            let _ = tokio::time::timeout(
                ROOM_TIMEOUT,
                cache.pagination().run_backwards_until(EVENTS),
            )
            .await;
        }
        tracing::debug!(target: PERF, ms = started.elapsed().as_millis() as u64, "history prefetch done");
    });
}
