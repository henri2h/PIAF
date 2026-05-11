use crate::utils::matrix::{CLIENT, SESSION_FILE, matrix_sync};
use tokio::sync::mpsc::UnboundedReceiver;

pub struct MatrixSyncWorker {}
impl MatrixSyncWorker {
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

pub enum SyncTask {
    RunSyncForever(Option<String>),
}
