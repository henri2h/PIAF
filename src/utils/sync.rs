//! Background sync through matrix-sdk-ui's `SyncService`: one sliding-sync
//! connection for the room list (account data, receipts, typing) plus the
//! encryption sync (to-device, e2ee). Replaces the classic `/sync` loop.

use std::collections::HashSet;
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

/// Starts syncing and the watchers that feed the UI. Call once.
pub fn start(client: Client) {
    let Some(service) = SYNC_SERVICE.get().cloned() else {
        tracing::error!("sync: start called before init");
        return;
    };
    tokio::spawn(watch_state(service.clone()));
    tokio::spawn(watch_room_info(client.clone()));
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
                // The startup registration may have failed without network.
                #[cfg(target_os = "android")]
                if std::mem::take(&mut first_run) {
                    retry_pusher_registration().await;
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
async fn retry_pusher_registration() {
    let base = crate::utils::matrix::DATA_DIR
        .get()
        .and_then(|d| d.parent())
        .map(|p| p.to_path_buf());
    if let (Some(base), Some(client)) = (base, crate::utils::matrix::CLIENT.get()) {
        crate::utils::push::register_pusher_if_stored(client, &base).await;
    }
}
