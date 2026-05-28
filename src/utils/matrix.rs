use std::sync::atomic::Ordering;

use futures::channel::oneshot;
use matrix_sdk::{
    Client, ClientBuilder, LoopCtrl, ServerName,
    authentication::matrix::MatrixSession,
    config::SyncSettings,
    encryption::{BackupDownloadStrategy, EncryptionSettings},
    ruma::{UserId, api::client::filter::FilterDefinition, exports::serde_json},
};
use matrix_sdk_ui::RoomListService;
use rand::{RngExt, rng};
use rand_distr::Alphanumeric;
use serde::{Deserialize, Serialize};
use std::{
    path::{Path, PathBuf},
    sync::OnceLock,
};
use tokio::fs;

use crate::REQUESTER;

pub static CLIENT: OnceLock<Client> = OnceLock::new();
pub static ROOM_LIST_SERVICE: OnceLock<RoomListService> = OnceLock::new();
pub static SESSION_FILE: OnceLock<PathBuf> = OnceLock::new();
pub static DATA_DIR: OnceLock<PathBuf> = OnceLock::new();

#[derive(Debug, Serialize, Deserialize)]
struct ClientSession {
    /// The URL of the homeserver of the user.
    homeserver: String,

    /// The path of the database.
    db_path: PathBuf,

    /// The passphrase of the database.
    passphrase: String,
}

/// The full session to persist.
#[derive(Debug, Serialize, Deserialize)]
struct FullSession {
    /// The data to re-build the client.
    client_session: ClientSession,

    /// The Matrix user session.
    user_session: MatrixSession,

    /// The latest sync token.
    ///
    /// It is only needed to persist it when using `Client::sync_once()` and we
    /// want to make our syncs faster by not receiving all the initial sync
    /// again.
    #[serde(skip_serializing_if = "Option::is_none")]
    sync_token: Option<String>,
}

pub async fn restore_matrix_client(base_dir: PathBuf) -> anyhow::Result<bool> {
    let data_dir = base_dir.join("persist_session");
    let session_file = data_dir.join("session");

    // OnceLock sets are idempotent: if push context already set them, the existing
    // values (identical paths) are reused and the error is silently ignored.
    let _ = DATA_DIR.set(data_dir.clone());
    let _ = SESSION_FILE.set(session_file.clone());

    if session_file.exists() {
        // If the push context already restored the client, reuse it and only
        // re-read the sync token so the main sync loop can resume where it left off.
        let (client, sync_token) = if let Some(existing) = CLIENT.get() {
            let serialized = fs::read_to_string(&session_file).await?;
            let full: FullSession = serde_json::from_str(&serialized)?;
            (existing.clone(), full.sync_token)
        } else {
            let (c, t) = restore_session(&session_file).await?;
            let _ = CLIENT.set(c.clone());
            (c, t)
        };

        // Signal immediately so the UI can navigate to the room list and show
        // cached rooms from the local store without waiting for the network.
        let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));

        // Start sync only when the main app worker is available.
        // In the push context REQUESTER is not set, so this is skipped.
        activate_client(&client, sync_token, &base_dir).await;

        return Ok(true);
    }

    Ok(false)
}

/// Restore a previous session.
async fn restore_session(session_file: &Path) -> anyhow::Result<(Client, Option<String>)> {
    println!(
        "Previous session found in '{}'",
        session_file.to_string_lossy()
    );

    // The session was serialized as JSON in a file.
    let serialized_session = fs::read_to_string(session_file).await?;
    let FullSession {
        client_session,
        user_session,
        sync_token,
    } = serde_json::from_str(&serialized_session)?;

    let client = get_client_builder(
        &client_session.homeserver,
        &client_session.db_path,
        &client_session.passphrase,
    )
    .build()
    .await?;

    println!("Restoring session for {}…", user_session.meta.user_id);

    // Restore the Matrix user session.
    client.restore_session(user_session).await?;

    Ok((client, sync_token))
}

async fn activate_client(client: &Client, sync_token: Option<String>, _pusher_dir: &Path) {
    if ROOM_LIST_SERVICE.get().is_none() {
        if let Ok(room_list_s) = RoomListService::new(client.clone()).await {
            ROOM_LIST_SERVICE.set(room_list_s).ok();
        }
    }

    #[cfg(target_os = "android")]
    crate::utils::push::register_pusher_if_stored(client, _pusher_dir).await;

    if let Some(rq) = REQUESTER.get() {
        rq.start_sync(sync_token);
        rq.start_room_list_sync();
    }
}

pub async fn login_matrix(username: String, password: String) -> anyhow::Result<()> {
    let session_file = SESSION_FILE.get().unwrap();
    let data_dir = DATA_DIR.get().unwrap();

    let account = UserId::parse(username.as_str())?;

    let (client, client_session) = new_client(&data_dir, account.server_name()).await?;

    let matrix_auth = client.matrix_auth();

    println!("Trying login in user {username}");

    match matrix_auth
        .login_username(&username, &password)
        .initial_device_display_name("persist-session client")
        .await
    {
        Ok(_) => {
            println!("Logged in as {username}");

            // Persist session
            let user_session = matrix_auth
                .session()
                .expect("A logged-in client should have a session");
            let serialized_session = serde_json::to_string(&FullSession {
                client_session,
                user_session,
                sync_token: None,
            })?;
            fs::write(session_file, serialized_session).await?;

            println!("Session persisted in {}", session_file.to_string_lossy());

            // Saving client
            CLIENT.set(client).expect("Client already set");

            activate_client(CLIENT.get().unwrap(), None, data_dir).await;

            Ok(())
        }
        Err(error) => {
            println!("Error logging in: {error}");
            println!("Please try again\n");
            Err(anyhow::anyhow!("Invalid username"))
        }
    }
}

fn get_client_builder(
    homeserver: &String,
    db_path: &PathBuf,
    passphrase: &String,
) -> ClientBuilder {
    // Build the client with the previous settings from the session.
    Client::builder()
        .server_name_or_homeserver_url(homeserver)
        .sqlite_store(db_path, Some(&passphrase))
        .with_encryption_settings(EncryptionSettings {
            auto_enable_cross_signing: true,
            backup_download_strategy: BackupDownloadStrategy::AfterDecryptionFailure,
            auto_enable_backups: true,
        })
        .with_enable_share_history_on_invite(true)
}

/// Build a new client.
async fn new_client(
    data_dir: &Path,
    homeserver: &ServerName,
) -> anyhow::Result<(Client, ClientSession)> {
    let (db_path, passphrase) = {
        let mut rng = rng();

        // Generating a subfolder for the database is not mandatory, but it is useful if
        // you allow several clients to run at the same time. Each one must have a
        // separate database, which is a different folder with the SQLite store.
        let db_subfolder: String = (&mut rng)
            .sample_iter(Alphanumeric)
            .take(7)
            .map(char::from)
            .collect();
        let db_path = data_dir.join(db_subfolder);

        // Generate a random passphrase.
        let passphrase: String = (&mut rng)
            .sample_iter(Alphanumeric)
            .take(32)
            .map(char::from)
            .collect();

        (db_path, passphrase)
    };

    println!("\nChecking homeserver {homeserver}");

    let client_build = get_client_builder(&homeserver.to_string(), &db_path, &passphrase)
        .build()
        .await;

    match client_build {
        Ok(client) => {
            let homeserver = client.homeserver().to_string();
            return Ok((
                client,
                ClientSession {
                    homeserver,
                    db_path,
                    passphrase,
                },
            ));
        }
        Err(error) => match &error {
            matrix_sdk::ClientBuildError::AutoDiscovery(_)
            | matrix_sdk::ClientBuildError::Url(_)
            | matrix_sdk::ClientBuildError::Http(_) => {
                println!("Error checking the homeserver: {error}");
                println!("Please try again\n");
                Err(anyhow::anyhow!("Invalid homeserver"))
            }
            _ => {
                // Forward other errors, it's unlikely we can retry with a different outcome.
                println!("Error: {error}");
                return Err(error.into());
            }
        },
    }
}

pub async fn matrix_sync(
    client: Client,
    initial_sync_token: Option<String>,
    session_file: &Path,
) -> anyhow::Result<()> {
    println!("Launching a first sync to ignore past messages…");

    // Enable room members lazy-loading, it will speed up the initial sync a lot
    // with accounts in lots of rooms.
    // See <https://spec.matrix.org/v1.6/client-server-api/#lazy-loading-room-members>.
    let filter = FilterDefinition::with_lazy_loading();

    let mut sync_settings = SyncSettings::default().filter(filter.into());

    // We restore the sync where we left.
    // This is not necessary when not using `sync_once`. The other sync methods get
    // the sync token from the store.
    if let Some(sync_token) = initial_sync_token {
        sync_settings = sync_settings.token(sync_token);
    }

    // Let's ignore messages before the program was launched.
    // This is a loop in case the initial sync is longer than our timeout. The
    // server should cache the response and it will ultimately take less time to
    // receive.
    loop {
        match client.sync_once(sync_settings.clone()).await {
            Ok(response) => {
                // This is the last time we need to provide this token, the sync method after
                // will handle it on its own.
                sync_settings = sync_settings.token(response.next_batch.clone());
                persist_sync_token(session_file, response.next_batch).await?;
                break;
            }
            Err(error) => {
                println!("An error occurred during initial sync: {error}");
                println!("Trying again in 5s…");
                tokio::time::sleep(std::time::Duration::from_secs(5)).await;
            }
        }
    }

    println!("The client is ready! Listening to new messages…");

    // Retry pusher registration now that we know the homeserver is reachable.
    // The startup attempt may have failed due to no network connectivity yet.
    #[cfg(target_os = "android")]
    if let Some(base) = DATA_DIR
        .get()
        .and_then(|d| d.parent())
        .map(|p| p.to_path_buf())
    {
        crate::utils::push::register_pusher_if_stored(&client, &base).await;
    }

    // This loops until we kill the program or an error happens.
    client
        .sync_with_result_callback(sync_settings, |sync_result| {
            // Clone before `async move`: each Fn invocation borrows `client` to
            // clone it, then moves the owned clone into the future.
            #[cfg(target_os = "android")]
            let nc = client.clone();
            async move {
                let response = sync_result?;

                persist_sync_token(session_file, response.next_batch)
                    .await
                    .map_err(|err| matrix_sdk::Error::UnknownError(err.into()))?;

                crate::SYNCING.store(false, Ordering::Relaxed);
                let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));

                // Dismiss notifications for rooms that were read on any device since last sync.
                #[cfg(target_os = "android")]
                tokio::spawn(async move {
                    crate::utils::push::cancel_read_notifications_after_sync(&nc).await;
                });

                Ok(LoopCtrl::Continue)
            }
        })
        .await?;

    Ok(())
}

// ── Theme preference persistence ─────────────────────────────────────────────

fn theme_pref_file() -> Option<std::path::PathBuf> {
    DATA_DIR
        .get()
        .and_then(|d| d.parent())
        .map(|p| p.join("theme_pref"))
}

pub fn load_theme_is_dark() -> bool {
    theme_pref_file()
        .and_then(|p| std::fs::read_to_string(p).ok())
        .and_then(|s| s.trim().parse::<u8>().ok())
        .map(|v| v == 2)
        .unwrap_or(false)
}

pub async fn save_theme_pref(is_dark: bool) {
    let Some(path) = theme_pref_file() else {
        return;
    };
    let _ = fs::write(&path, if is_dark { "2" } else { "1" }).await;
}

// ── Draft persistence ─────────────────────────────────────────────────────────

fn drafts_file() -> Option<std::path::PathBuf> {
    DATA_DIR
        .get()
        .and_then(|d| d.parent())
        .map(|p| p.join("drafts.json"))
}

async fn read_drafts() -> std::collections::HashMap<String, String> {
    let Some(path) = drafts_file() else {
        return Default::default();
    };
    fs::read_to_string(&path)
        .await
        .ok()
        .and_then(|s| serde_json::from_str(&s).ok())
        .unwrap_or_default()
}

async fn write_drafts(map: &std::collections::HashMap<String, String>) {
    let Some(path) = drafts_file() else { return };
    if let Ok(json) = serde_json::to_string(map) {
        let _ = fs::write(&path, json).await;
    }
}

pub async fn load_draft(room_id: &str) -> Option<String> {
    let s = read_drafts().await.remove(room_id)?;
    if s.trim().is_empty() { None } else { Some(s) }
}

pub async fn save_draft(room_id: &str, text: &str) {
    let mut map = read_drafts().await;
    if text.trim().is_empty() {
        map.remove(room_id);
    } else {
        map.insert(room_id.to_string(), text.to_string());
    }
    write_drafts(&map).await;
}

pub async fn clear_draft(room_id: &str) {
    let mut map = read_drafts().await;
    if map.remove(room_id).is_some() {
        write_drafts(&map).await;
    }
}

// ── Image download ────────────────────────────────────────────────────────────

pub async fn save_image_to_downloads(bytes: &[u8]) {
    let Some(data_dir) = DATA_DIR.get() else {
        return;
    };
    let downloads_dir = data_dir.join("downloads");
    let _ = fs::create_dir_all(&downloads_dir).await;
    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis();
    let path = downloads_dir.join(format!("image_{}.jpg", ts));
    let _ = fs::write(&path, bytes).await;
}

// ── DM helpers ────────────────────────────────────────────────────────────────

pub async fn create_or_get_dm(user_id: String) -> Option<String> {
    let client = CLIENT.get().cloned()?;
    let Ok(parsed) = matrix_sdk::ruma::UserId::parse(&user_id) else {
        return None;
    };
    if let Some(room) = client.get_dm_room(&parsed) {
        return Some(room.room_id().to_string());
    }
    let (tx, rx) = oneshot::channel::<Option<String>>();
    tokio::spawn(async move {
        use matrix_sdk::ruma::api::client::room::create_room::v3::Request as CreateRoom;
        let mut req = CreateRoom::new();
        req.is_direct = true;
        req.invite = vec![parsed.to_owned()];
        match client.create_room(req).await {
            Ok(room) => {
                let _ = tx.send(Some(room.room_id().to_string()));
            }
            Err(_) => {
                let _ = tx.send(None);
            }
        }
    });
    rx.await.ok().flatten()
}

/// Persist the sync token for a future session.
/// Note that this is needed only when using `sync_once`. Other sync methods get
/// the sync token from the store.
async fn persist_sync_token(session_file: &Path, sync_token: String) -> anyhow::Result<()> {
    let serialized_session = fs::read_to_string(session_file).await?;
    let mut full_session: FullSession = serde_json::from_str(&serialized_session)?;

    full_session.sync_token = Some(sync_token);
    let serialized_session = serde_json::to_string(&full_session)?;
    fs::write(session_file, serialized_session).await?;

    Ok(())
}
