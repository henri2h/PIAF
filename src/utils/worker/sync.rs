use crate::utils::matrix::{CLIENT, SESSION_FILE, matrix_sync};

pub struct MatrixSyncWorker {}

impl MatrixSyncWorker {
    pub async fn run(&mut self, initial_sync_token: Option<String>) {
        println!("Asked to run");
        let mut token = initial_sync_token;
        loop {
            let Some(client) = CLIENT.get() else {
                eprintln!("Sync: client not available, stopping");
                break;
            };
            let Some(session_file) = SESSION_FILE.get() else {
                eprintln!("Sync: session file not available, stopping");
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
}
