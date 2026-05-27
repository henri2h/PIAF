use crate::utils::{
    matrix::{CLIENT, ROOM_LIST_SERVICE, login_matrix},
    worker::Requester,
};
use futures::channel::oneshot;
use matrix_sdk::media::MediaFormat;
use tokio::sync::mpsc::{UnboundedReceiver, unbounded_channel};

pub struct MatrixClientWorker {}

pub enum WorkerTask {
    Login(String, String, oneshot::Sender<anyhow::Result<()>>),
    FetchRoomAvatar(String, oneshot::Sender<Result<Vec<u8>, ()>>),
    FetchUserAvatar(oneshot::Sender<Result<Vec<u8>, ()>>),
    FetchUserDisplayName(oneshot::Sender<Result<String, ()>>),
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
                println!("Call worker login");
                let response = login_matrix(username, password).await;
                let _ = reply.send(response);
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
