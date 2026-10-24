//! Background sync through matrix-sdk-ui's `SyncService`: one sliding-sync
//! connection for the room list (account data, receipts, typing) plus the
//! encryption sync (to-device, e2ee). Replaces the classic `/sync` loop.

use std::collections::{HashMap, HashSet};
use std::sync::atomic::Ordering;
use std::sync::{Arc, LazyLock, Mutex, OnceLock};
use std::time::Duration;

use matrix_sdk::Client;
use matrix_sdk::ruma::OwnedRoomId;
use matrix_sdk_ui::RoomListService;
use matrix_sdk_ui::sync_service::{State, SyncService};
use tokio::sync::broadcast::error::RecvError;

use crate::utils::room_list::{refresh, resolve_invite_dm_flags};

static SYNC_SERVICE: OnceLock<Arc<SyncService>> = OnceLock::new();

/// Events per room in room list updates. Kept at 1: on large accounts every
/// extra event is multiplied by thousands of rooms. Rows without a usable
/// preview get one through a room subscription (20 events, see
/// `RoomListItem`'s preview fetch) plus `track_latest_event`.
const ROOM_LIST_TIMELINE_LIMIT: u32 = 1;

/// Delay before restarting after a sync error (not network loss: offline mode handles that).
const RESTART_DELAY: Duration = Duration::from_secs(5);

/// Builds the sync service once per process. Doesn't start it.
pub async fn init(client: &Client) -> anyhow::Result<()> {
    if SYNC_SERVICE.get().is_some() {
        return Ok(());
    }
    let service = SyncService::builder(client.clone())
        .with_offline_mode()
        // Persist the sliding-sync position: without it every launch re-downloads
        // the whole room list, 100 rooms per batch.
        .with_share_pos(true)
        .with_room_list_timeline_limit(ROOM_LIST_TIMELINE_LIMIT)
        .build()
        .await?;
    let _ = SYNC_SERVICE.set(Arc::new(service));
    Ok(())
}

pub fn room_list_service() -> Option<Arc<RoomListService>> {
    SYNC_SERVICE.get().map(|s| s.room_list_service())
}

/// Rooms with a sliding-sync subscription: the ones on screen (counted, a
/// room can be open twice: list + panel) and the latest preview fetch.
/// Without one, an open room only gets the room list's single event per
/// update: two messages between syncs make the response `limited`, and the
/// event cache then unloads everything but the newest messages.
#[derive(Default)]
struct Subscriptions {
    open: HashMap<OwnedRoomId, usize>,
    previews: Vec<OwnedRoomId>,
}

impl Subscriptions {
    /// Every subscribed room, once.
    fn rooms(&self) -> Vec<OwnedRoomId> {
        let mut ids: Vec<OwnedRoomId> = self.open.keys().cloned().collect();
        ids.extend(
            self.previews
                .iter()
                .filter(|id| !self.open.contains_key(*id))
                .cloned(),
        );
        ids
    }
}

static SUBSCRIPTIONS: LazyLock<Mutex<Subscriptions>> = LazyLock::new(Default::default);

/// Keeps the room subscribed while alive.
pub struct RoomSubscription(OwnedRoomId);

impl Drop for RoomSubscription {
    fn drop(&mut self) {
        let mut subs = SUBSCRIPTIONS.lock().unwrap();
        if let Some(count) = subs.open.get_mut(&self.0) {
            *count -= 1;
            if *count == 0 {
                subs.open.remove(&self.0);
            }
        }
        drop(subs);
        apply_subscriptions();
    }
}

/// Subscribes to `room_id` (20 events per update) until the guard is dropped.
pub fn subscribe_room(room_id: &str) -> Option<RoomSubscription> {
    let room_id = OwnedRoomId::try_from(room_id).ok()?;
    *SUBSCRIPTIONS
        .lock()
        .unwrap()
        .open
        .entry(room_id.clone())
        .or_default() += 1;
    apply_subscriptions();
    Some(RoomSubscription(room_id))
}

/// Subscribes to `room_ids` for their previews, replacing the previous ones.
pub fn subscribe_previews(room_ids: Vec<OwnedRoomId>) {
    SUBSCRIPTIONS.lock().unwrap().previews = room_ids;
    apply_subscriptions();
}

fn apply_subscriptions() {
    // Applied one at a time, each reading the set when its turn comes: the
    // last one sent is the latest set.
    static APPLYING: LazyLock<tokio::sync::Mutex<()>> = LazyLock::new(Default::default);
    // A guard dropped while the app shuts down has no runtime left.
    let Ok(runtime) = tokio::runtime::Handle::try_current() else {
        return;
    };
    runtime.spawn(async {
        let _turn = APPLYING.lock().await;
        let Some(service) = room_list_service() else {
            return;
        };
        let room_ids = SUBSCRIPTIONS.lock().unwrap().rooms();
        let refs: Vec<&matrix_sdk::ruma::RoomId> = room_ids.iter().map(|id| id.as_ref()).collect();
        service.set_room_subscriptions(&refs).await;
    });
}

/// Starts syncing and the watchers that feed the UI. Call once.
pub fn start(client: Client) {
    let Some(service) = SYNC_SERVICE.get().cloned() else {
        tracing::error!("sync: start called before init");
        return;
    };
    tokio::spawn(watch_state(service.clone()));
    tokio::spawn(watch_room_info(client.clone()));
    crate::utils::spaces::start(client.clone());
    tokio::spawn(watch_room_updates(client));
    tokio::spawn(async move { service.start().await });
}

pub async fn stop() {
    if let Some(service) = SYNC_SERVICE.get() {
        service.stop().await;
    }
}

/// Mirrors the service state into the connection flags; restarts after errors.
async fn watch_state(service: Arc<SyncService>) {
    let mut states = service.state();
    #[cfg(target_os = "android")]
    let mut first_run = true;
    while let Some(state) = states.next().await {
        tracing::debug!("sync state: {state:?}");
        match state {
            State::Running => {
                crate::DISCONNECTED.store(false, Ordering::Relaxed);
                // Register for push once the server is reachable, off the startup path.
                #[cfg(target_os = "android")]
                if std::mem::take(&mut first_run) {
                    tokio::spawn(register_pusher());
                }
            }
            State::Offline => crate::DISCONNECTED.store(true, Ordering::Relaxed),
            State::Error(e) => {
                if crate::SESSION_EXPIRED.load(Ordering::Relaxed) {
                    break;
                }
                tracing::warn!("sync error, restarting in {RESTART_DELAY:?}: {e}");
                crate::DISCONNECTED.store(true, Ordering::Relaxed);
                let service = service.clone();
                tokio::spawn(async move {
                    tokio::time::sleep(RESTART_DELAY).await;
                    if !crate::SESSION_EXPIRED.load(Ordering::Relaxed) {
                        service.start().await;
                    }
                });
            }
            State::Idle | State::Terminated => {}
        }
        let _ = crate::SYNC_TX.get().expect("not initialized").send(());
    }
}

/// Latest events are computed lazily, only for registered rooms; without this
/// a room's preview stays empty until a timeline for it is opened. Called by
/// room rows as they're shown, so large accounts only pay for visible rooms.
/// New values arrive as `LATEST_EVENT` notable updates (see `watch_room_info`).
pub fn track_latest_event(room_id: &str) {
    static TRACKED: LazyLock<Mutex<HashSet<String>>> = LazyLock::new(Default::default);
    if !TRACKED.lock().unwrap().insert(room_id.to_string()) {
        return;
    }
    let Ok(room_id) = OwnedRoomId::try_from(room_id) else {
        return;
    };
    let Some(client) = crate::utils::matrix::CLIENT.get().cloned() else {
        return;
    };
    tokio::spawn(async move {
        if let Err(e) = client.latest_events().await.listen_to_room(&room_id).await {
            tracing::warn!("latest events: can't listen to {room_id}: {e}");
        }
    });
}

/// Wakes the UI after each processed sync response that changed the room list.
async fn watch_room_updates(client: Client) {
    let mut updates = client.subscribe_to_all_room_updates();
    // Invites restored from the store, before any sync update.
    resolve_invite_dm_flags(&client).await;
    loop {
        match updates.recv().await {
            Ok(_) | Err(RecvError::Lagged(_)) => {
                resolve_invite_dm_flags(&client).await;
                refresh("sync");
                #[cfg(target_os = "android")]
                {
                    let client = client.clone();
                    tokio::spawn(async move {
                        crate::utils::push::cancel_read_notifications_after_sync(&client).await;
                    });
                }
            }
            Err(RecvError::Closed) => break,
        }
    }
}

/// Room info changes that don't come with a room update (unread marker, receipts,
/// latest event, names). One per room; `refresh` coalesces them.
async fn watch_room_info(client: Client) {
    let mut updates = client.room_info_notable_update_receiver();
    loop {
        match updates.recv().await {
            Ok(_) | Err(RecvError::Lagged(_)) => {
                refresh("room_info");
            }
            Err(RecvError::Closed) => break,
        }
    }
}

#[cfg(target_os = "android")]
async fn register_pusher() {
    let base = crate::utils::matrix::DATA_DIR
        .get()
        .and_then(|d| d.parent())
        .map(|p| p.to_path_buf());
    if let (Some(base), Some(client)) = (base, crate::utils::matrix::CLIENT.get()) {
        crate::utils::push::register_pusher_if_stored(client, &base).await;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn subscriptions_cover_open_rooms_and_previews_once() {
        let (a, b) = (
            OwnedRoomId::try_from("!a:x").unwrap(),
            OwnedRoomId::try_from("!b:x").unwrap(),
        );
        let subs = Subscriptions {
            open: HashMap::from([(a.clone(), 2)]),
            previews: vec![a.clone(), b.clone()],
        };
        let mut rooms = subs.rooms();
        rooms.sort();
        assert_eq!(rooms, [a, b]);
    }
}
