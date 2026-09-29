use crate::utils::worker::client::WorkerTask;
use futures::channel::oneshot;
use tokio::sync::mpsc::UnboundedSender;

pub mod client;

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
