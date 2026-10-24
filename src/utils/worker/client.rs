use crate::utils::{matrix::login_matrix, worker::Requester};
use futures::channel::oneshot;
use tokio::sync::mpsc::{UnboundedReceiver, unbounded_channel};

pub struct MatrixClientWorker {}

pub enum WorkerTask {
    Login(String, String, oneshot::Sender<anyhow::Result<()>>),
    FetchRoomPreviews(Vec<matrix_sdk::ruma::OwnedRoomId>),
}

impl MatrixClientWorker {
    pub fn spawn() -> Requester {
        let (client_tx, client_rx) = unbounded_channel();

        let mut worker = MatrixClientWorker {};
        tokio::spawn(async move {
            worker.work(client_rx).await;
        });

        Requester { tx: client_tx }
    }

    pub async fn work(&mut self, mut rx: UnboundedReceiver<WorkerTask>) {
        loop {
            let t = rx.recv().await;

            match t {
                Some(task) => self.run(task).await,
                None => {
                    break;
                }
            }
        }
    }

    pub async fn run(&mut self, task: WorkerTask) {
        match task {
            WorkerTask::Login(username, password, reply) => {
                tracing::debug!("worker: login");
                let response = login_matrix(username, password).await;
                let _ = reply.send(response);
            }
            WorkerTask::FetchRoomPreviews(room_ids) => {
                do_fetch_room_previews(room_ids).await;
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Matrix operations — run sequentially inside the worker loop, which
// naturally prevents concurrent SQLite store access.
// ---------------------------------------------------------------------------

async fn do_fetch_room_previews(room_ids: Vec<matrix_sdk::ruma::OwnedRoomId>) {
    crate::utils::sync::subscribe_previews(room_ids);
}
