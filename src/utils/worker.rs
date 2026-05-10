use matrix_sdk::media::MediaFormat;

use crate::utils::matrix::{CLIENT, ROOM_LIST_SERVICE, SESSION_FILE, login_matrix, matrix_sync};
use futures::channel::oneshot;
use std::sync::mpsc::{Receiver, SyncSender, sync_channel};
use tokio::sync::mpsc::{UnboundedReceiver, UnboundedSender, unbounded_channel};

pub struct ClientWorker {}
pub struct SyncWorker {}

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

    pub async fn fetch_room_avatar(&self, room_id: String) -> Result<Vec<u8>, ()> {
        let (tx, rx) = oneshot::channel();
        self.tx
            .send(WorkerTask::FetchRoomAvatar(room_id, tx))
            .map_err(|_| ())?;
        rx.await.map_err(|_| ())?
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

impl ClientWorker {
    pub async fn spawn() -> Requester {
        let (tx, rx) = unbounded_channel();
        let (sync_tx, sync_rx) = unbounded_channel();

        // Main worker
        let mut worker = ClientWorker {};

        tokio::spawn(async move {
            worker.work(rx).await;
        });

        // Sync worker
        let mut sync_worker = SyncWorker {};

        tokio::spawn(async move {
            sync_worker.work(sync_rx).await;
        });

        return Requester { tx, sync_tx };
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
            WorkerTask::Init => todo!(),
            WorkerTask::Login(username, password, reply) => {
                println!("Call worker login");
                let response = login_matrix(username, password).await;
                reply.send(response);
            }
            WorkerTask::FetchRoomAvatar(room_id, reply) => {
                println!("Get room: {room_id}");
                let result = do_fetch_room_avatar(&room_id).await;
                println!("Get room (done): {room_id}");
                let _ = reply.send(result);
            }
            WorkerTask::FetchUserAvatar(reply) => {
                let result = do_fetch_user_avatar().await;
                let _ = reply.send(result);
            }
            WorkerTask::FetchUserDisplayName(reply) => {
                let result = do_fetch_user_display_name().await;
                let _ = reply.send(result);
            }
            WorkerTask::FetchRoomPreviews(room_ids) => {
                do_fetch_room_previews(room_ids).await;
            }
        }
    }
}

impl SyncWorker {
    pub async fn work(&mut self, mut rx: UnboundedReceiver<SyncTask>) {
        loop {
            let t = rx.recv().await;
            match t {
                Some(task) => match task {
                    SyncTask::RunSyncForever(initial_sync_token) => {
                        println!("Asked to run");
                        let mut token = initial_sync_token;
                        loop {
                            let Some(client) = CLIENT.get() else {
                                break;
                            };
                            let Some(session_file) = SESSION_FILE.get() else {
                                break;
                            };
                            match matrix_sync(client.clone(), token.take(), session_file).await {
                                Ok(()) => break,
                                Err(e) => {
                                    eprintln!("Sync error: {e:#}, retrying in 5s…");
                                    tokio::time::sleep(std::time::Duration::from_secs(5)).await;
                                }
                            }
                        }
                    }
                },
                None => {
                    break;
                }
            }
        }
    }
}

pub enum WorkerTask {
    Init,
    Login(String, String, ClientReply<anyhow::Result<()>>),
    FetchRoomAvatar(String, oneshot::Sender<Result<Vec<u8>, ()>>),
    FetchUserAvatar(oneshot::Sender<Result<Vec<u8>, ()>>),
    FetchUserDisplayName(oneshot::Sender<Result<String, ()>>),
    FetchRoomPreviews(Vec<matrix_sdk::ruma::OwnedRoomId>),
}

pub enum SyncTask {
    RunSyncForever(Option<String>),
}

pub struct ClientResponse<T>(Receiver<T>);
pub struct ClientReply<T>(SyncSender<T>);

impl<T> ClientResponse<T> {
    fn recv(self) -> T {
        self.0
            .recv()
            .expect("failed to receive response from client thread")
    }
}

impl<T> ClientReply<T> {
    fn send(self, t: T) {
        self.0.send(t).unwrap();
    }
}

fn oneshot_blocking<T>() -> (ClientReply<T>, ClientResponse<T>) {
    let (tx, rx) = sync_channel(1);
    let reply = ClientReply(tx);
    let response = ClientResponse(rx);

    return (reply, response);
}

// ---------------------------------------------------------------------------
// Matrix operations — run sequentially inside the worker loop, which
// naturally prevents concurrent SQLite store access.
// ---------------------------------------------------------------------------

async fn do_fetch_room_avatar(room_id: &str) -> Result<Vec<u8>, ()> {
    let Some(client) = CLIENT.get().cloned() else {
        return Err(());
    };
    let Ok(parsed_id) = matrix_sdk::ruma::RoomId::parse(room_id) else {
        return Err(());
    };
    let Some(room) = client.get_room(&parsed_id) else {
        return Err(());
    };
    room.avatar(MediaFormat::File)
        .await
        .ok()
        .flatten()
        .ok_or(())
}

async fn do_fetch_user_avatar() -> Result<Vec<u8>, ()> {
    let Some(client) = CLIENT.get().cloned() else {
        return Err(());
    };
    client
        .account()
        .get_avatar(MediaFormat::File)
        .await
        .ok()
        .flatten()
        .ok_or(())
}

async fn do_fetch_room_previews(room_ids: Vec<matrix_sdk::ruma::OwnedRoomId>) {
    let Some(service) = ROOM_LIST_SERVICE.get() else {
        return;
    };
    let refs: Vec<&matrix_sdk::ruma::RoomId> = room_ids.iter().map(|id| id.as_ref()).collect();
    service.subscribe_to_rooms(&refs).await;
}

async fn do_fetch_user_display_name() -> Result<String, ()> {
    let Some(client) = CLIENT.get().cloned() else {
        return Err(());
    };
    let name = client
        .account()
        .get_display_name()
        .await
        .ok()
        .flatten()
        .or_else(|| client.user_id().map(|id| id.to_string()))
        .unwrap_or_default();
    Ok(name)
}
