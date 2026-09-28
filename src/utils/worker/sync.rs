use crate::utils::matrix::{CLIENT, SESSION_FILE, matrix_sync};

pub struct MatrixSyncWorker {}

impl MatrixSyncWorker {
    pub async fn run(&mut self, initial_sync_token: Option<String>) {
        tracing::debug!("sync worker started");
        let mut token = initial_sync_token;
        loop {
            let Some(client) = CLIENT.get() else {
                tracing::warn!("sync: client not available, stopping");
                break;
            };
            let Some(session_file) = SESSION_FILE.get() else {
                tracing::warn!("sync: session file not available, stopping");
                break;
            };
            match matrix_sync(client.clone(), token.take(), session_file).await {
                Ok(()) => break,
                Err(_) if crate::SESSION_EXPIRED.load(std::sync::atomic::Ordering::Relaxed) => {
                    break;
                }
                Err(e) => {
                    tracing::warn!("sync error, retrying in 5s: {e:#}");
                    tokio::time::sleep(std::time::Duration::from_secs(5)).await;
                }
            }
        }
    }
}
