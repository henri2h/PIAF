use crate::utils::{
    matrix::ROOM_LIST_SERVICE,
    worker::{client::WorkerTask, sync::MatrixSyncWorker},
};
use futures::channel::oneshot;
use tokio::sync::mpsc::UnboundedSender;

pub mod client;
pub mod sync;

#[derive(Clone, Debug)]
pub struct Requester {
    pub tx: UnboundedSender<WorkerTask>,
}

impl Requester {
    pub async fn login(&self, username: String, password: String) -> anyhow::Result<()> {
        let (tx, rx) = oneshot::channel();
        self.tx
            .send(WorkerTask::Login(username, password, tx))
            .unwrap();
        rx.await.map_err(|_| anyhow::anyhow!("worker dropped"))?
    }

    pub fn start_sync(&self, initial_sync_token: Option<String>) {
        tokio::spawn(async move {
            MatrixSyncWorker {}.run(initial_sync_token).await;
        });
    }

    pub fn start_room_list_sync(&self) {
        tokio::spawn(async move {
            use std::sync::atomic::Ordering;

            use futures::StreamExt;
            let Some(service) = ROOM_LIST_SERVICE.get() else {
                return;
            };
            let sync = service.sync();
            futures::pin_mut!(sync);
            while let Some(result) = sync.next().await {
                if let Err(e) = result {
                    eprintln!("Room list sync error: {e}");
                    // Wake the UI so it can show the offline banner; rooms
                    // still render from the local cache while disconnected.
                    crate::DISCONNECTED.store(true, Ordering::Relaxed);
                    let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
                    continue;
                }
                crate::SYNCING.store(false, Ordering::Relaxed);
                crate::DISCONNECTED.store(false, Ordering::Relaxed);
                // The sliding-sync stream completes periodically even when
                // nothing changed (long-poll timeouts); only wake the UI when
                // the room list actually looks different.
                if let Some(client) = crate::utils::matrix::CLIENT.get() {
                    crate::utils::matrix::notify_sync_if_changed(client);
                }
            }
        });
    }

    pub fn fetch_room_previews(&self, room_ids: Vec<matrix_sdk::ruma::OwnedRoomId>) {
        if room_ids.is_empty() {
            return;
        }
        self.tx.send(WorkerTask::FetchRoomPreviews(room_ids)).ok();
    }

    pub async fn fetch_user_avatar(&self) -> Result<Vec<u8>, ()> {
        let (tx, rx) = oneshot::channel();
        self.tx
            .send(WorkerTask::FetchUserAvatar(tx))
            .map_err(|_| ())?;
        rx.await.map_err(|_| ())?
    }

    pub async fn fetch_user_display_name(&self) -> Result<String, ()> {
        let (tx, rx) = oneshot::channel();
        self.tx
            .send(WorkerTask::FetchUserDisplayName(tx))
            .map_err(|_| ())?;
        rx.await.map_err(|_| ())?
    }
}
