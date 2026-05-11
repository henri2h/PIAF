use crate::utils::{
    matrix::ROOM_LIST_SERVICE,
    worker::{
        client::{ClientReply, ClientResponse, WorkerTask},
        sync::SyncTask,
    },
};
use futures::channel::oneshot;
use std::sync::mpsc::sync_channel;
use tokio::sync::mpsc::UnboundedSender;

pub mod client;
pub mod sync;

#[derive(Clone, Debug)]
pub struct Requester {
    pub tx: UnboundedSender<WorkerTask>,
    pub sync_tx: UnboundedSender<SyncTask>,
}

impl Requester {
    pub fn login(&self, username: String, password: String) -> anyhow::Result<()> {
        let (reply, response) = oneshot_blocking();

        self.tx
            .send(WorkerTask::Login(username, password, reply))
            .unwrap();

        return response.recv();
    }

    pub fn start_sync(&self, initial_sync_token: Option<String>) {
        self.sync_tx
            .send(SyncTask::RunSyncForever(initial_sync_token))
            .unwrap();
    }

    pub fn start_room_list_sync(&self) {
        tokio::spawn(async move {
            use futures::StreamExt;
            let Some(service) = ROOM_LIST_SERVICE.get() else {
                return;
            };
            let sync = service.sync();
            futures::pin_mut!(sync);
            while let Some(result) = sync.next().await {
                if let Err(e) = result {
                    eprintln!("Room list sync error: {e}");
                    continue;
                }
                crate::SYNCING.store(false, std::sync::atomic::Ordering::Relaxed);
                let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
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

fn oneshot_blocking<T>() -> (ClientReply<T>, ClientResponse<T>) {
    let (tx, rx) = sync_channel(1);
    let reply = ClientReply(tx);
    let response = ClientResponse(rx);

    return (reply, response);
}
