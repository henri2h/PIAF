use std::sync::atomic::Ordering;

use matrix_sdk::{
    Client, ClientBuilder, Room, ServerName, SqliteStoreConfig,
    authentication::matrix::MatrixSession,
    encryption::{BackupDownloadStrategy, EncryptionSettings},
    ruma::{UserId, exports::serde_json},
};
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
pub static SESSION_FILE: OnceLock<PathBuf> = OnceLock::new();
pub static DATA_DIR: OnceLock<PathBuf> = OnceLock::new();

/// Looks up a room on the global client.
pub fn get_room(room_id: &str) -> Option<Room> {
    let room_id = matrix_sdk::ruma::RoomId::parse(room_id).ok()?;
    CLIENT.get()?.get_room(&room_id)
}

/// Whether `error` means the server no longer accepts our access token.
pub fn is_unknown_token(error: &matrix_sdk::Error) -> bool {
    matches!(
        error.client_api_error_kind(),
        Some(matrix_sdk::ruma::api::error::ErrorKind::UnknownToken(_))
    )
}

/// Stops using a revoked session: flags it, sets the session file aside so the
/// next launch goes to login, and wakes the UI. Idempotent.
pub async fn on_session_expired() {
    if crate::SESSION_EXPIRED.swap(true, Ordering::Relaxed) {
        return;
    }
    tracing::warn!("access token revoked, session expired");
    crate::utils::sync::stop().await;
    if let Some(file) = SESSION_FILE.get() {
        if let Err(e) = fs::rename(file, file.with_extension("expired")).await {
            tracing::warn!("could not set expired session file aside: {e}");
        }
    }
    let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
}

/// Catches token revocation on any request, not just sync.
fn watch_session_expiry(client: &Client) {
    use matrix_sdk::SessionChange;
    use tokio::sync::broadcast::error::RecvError;
    let mut changes = client.subscribe_to_session_changes();
    tokio::spawn(async move {
        loop {
            match changes.recv().await {
                Ok(SessionChange::UnknownToken(_)) => {
                    on_session_expired().await;
                    break;
                }
                Ok(_) | Err(RecvError::Lagged(_)) => {}
                Err(RecvError::Closed) => break,
            }
        }
    });
}

/// Timestamp (ms) of the room's latest event, if known.
pub fn latest_event_ts(room: &Room) -> Option<u64> {
    room.latest_event().timestamp().map(|ts| ts.get().into())
}

/// Logged-in user's ID, e.g. `@alice:example.org`.
pub fn my_user_id() -> Option<String> {
    CLIENT.get()?.user_id().map(|id| id.to_string())
}
/// Raw key of the stores. A passphrase costs a 200k-round PBKDF2 per store
/// (4 stores, ~370ms at startup on a phone); a key opens them directly.
type StoreKey = [u8; 32];

// No `Debug`: it would print the store secrets.
#[derive(Serialize, Deserialize)]
struct ClientSession {
    /// The URL of the homeserver of the user.
    homeserver: String,

    /// The path of the database.
    db_path: PathBuf,

    /// The stores' former passphrase: set until they are all re-keyed to
    /// `store_key` (see [`migrate_to_store_key`]), empty after.
    passphrase: String,

    #[serde(default)]
    store_key: Option<StoreKey>,
}

/// The full session to persist.
#[derive(Serialize, Deserialize)]
struct FullSession {
    /// The data to re-build the client.
    client_session: ClientSession,

    /// The Matrix user session.
    user_session: MatrixSession,
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
        // Serialized: the push context and the app can restore at the same
        // time in one process, and two store key migrations must never race.
        static RESTORE: tokio::sync::Mutex<()> = tokio::sync::Mutex::const_new(());
        let guard = RESTORE.lock().await;
        let client = if let Some(existing) = CLIENT.get() {
            existing.clone()
        } else {
            let c = restore_session(&session_file).await?;
            let _ = CLIENT.set(c.clone());
            tracing::debug!("restore_matrix_client: CLIENT set");
            c
        };
        drop(guard);

        // Signal immediately so the UI can navigate to the room list and show
        // cached rooms from the local store without waiting for the network.
        tracing::debug!("restore_matrix_client: sending initial SYNC_TX signal");
        let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));

        // Start sync only when the main app worker is available.
        // In the push context REQUESTER is not set, so this is skipped.
        tracing::debug!(
            "restore_matrix_client: calling activate_client (REQUESTER present={})",
            REQUESTER.get().is_some()
        );
        activate_client(&client).await;
        tracing::debug!("restore_matrix_client: activate_client returned");

        return Ok(true);
    }

    Ok(false)
}

/// Restore a previous session.
async fn restore_session(session_file: &Path) -> anyhow::Result<Client> {
    tracing::info!(
        "Previous session found in '{}'",
        session_file.to_string_lossy()
    );

    // The session was serialized as JSON in a file.
    let serialized_session = fs::read_to_string(session_file).await?;
    let mut session: FullSession = serde_json::from_str(&serialized_session)?;
    let store_config = match migrate_to_store_key(session_file, &mut session).await {
        Ok(()) => store_config(&session.client_session),
        Err(e) => {
            tracing::warn!("store key migration failed, keeping the passphrase: {e:#}");
            SqliteStoreConfig::new(&session.client_session.db_path)
                .passphrase(Some(&session.client_session.passphrase))
        }
    };
    let FullSession {
        client_session,
        user_session,
    } = session;

    // discover: false — homeserver is already a resolved base URL from the
    // prior login, so this builds instantly with no network I/O and works offline.
    let client = get_client_builder(&client_session.homeserver, store_config, false)
        .build()
        .await?;
    crate::logging::boot("stores opened");

    tracing::info!("Restoring session");

    // Restore the Matrix user session.
    client.restore_session(user_session).await?;
    crate::logging::boot("session restored");

    Ok(client)
}

async fn activate_client(client: &Client) {
    watch_session_expiry(client);
    crate::utils::drafts::load().await;
    crate::logging::boot("drafts loaded");
    if let Err(e) = crate::utils::sync::init(client).await {
        tracing::error!("activate_client: SyncService build failed: {e:#}");
    }
    crate::logging::boot("sync service built");

    // Push registration is a network round trip (measured 0.8-2.2s); it runs
    // once sync is up (`sync::watch_state`), never on the startup path.

    if REQUESTER.get().is_some() {
        crate::utils::reactions::register(client);
    }

    // Load bookmark lists from account_data once the client is ready.
    if let Some(tx) = crate::BOOKMARKS_TX.get() {
        let client = client.clone();
        let tx = tx.clone();
        tokio::spawn(async move {
            let bookmarks = crate::utils::bookmarks::load_bookmarks(&client).await;
            let _ = tx.send(bookmarks);
        });
    }

    // Load per-room mailbox state (recontact tag + archived flag) once the client is ready.
    if crate::ROOM_MAILBOX_TX.get().is_some() {
        let client = client.clone();
        tokio::spawn(async move {
            crate::utils::room_mailbox::load_room_mailbox(&client).await;
        });
    }

    #[cfg(not(target_os = "android"))]
    if REQUESTER.get().is_some() {
        crate::utils::notifications::register(client);
    }

    // No REQUESTER means the Android push context: enrichment only, no sync.
    if REQUESTER.get().is_some() {
        tracing::debug!("activate_client: starting sync service");
        crate::utils::sync::start(client.clone());
        crate::logging::boot("sync started");
        // Show cached rooms right away, before the first sync update.
        crate::utils::room_list::refresh("startup");
    }
}

pub async fn login_matrix(username: String, password: String) -> anyhow::Result<()> {
    let session_file = SESSION_FILE.get().unwrap();
    let data_dir = DATA_DIR.get().unwrap();

    let account = UserId::parse(username.as_str())?;

    let (client, client_session) = new_client(&data_dir, account.server_name()).await?;

    let matrix_auth = client.matrix_auth();

    tracing::info!("Logging in");

    match matrix_auth
        .login_username(&username, &password)
        .initial_device_display_name("persist-session client")
        .await
    {
        Ok(_) => {
            tracing::info!("Logged in");

            // Persist session
            let user_session = matrix_auth
                .session()
                .expect("A logged-in client should have a session");
            let serialized_session = serde_json::to_string(&FullSession {
                client_session,
                user_session,
            })?;
            fs::write(session_file, serialized_session).await?;

            tracing::debug!("session persisted in {}", session_file.to_string_lossy());

            // Saving client
            CLIENT.set(client).expect("Client already set");

            activate_client(CLIENT.get().unwrap()).await;

            Ok(())
        }
        Err(error) => {
            tracing::warn!("login failed: {error}");
            use matrix_sdk::ruma::api::error::ErrorKind;
            let message = match error.client_api_error_kind() {
                Some(ErrorKind::Forbidden) => "Wrong user ID or password.".to_string(),
                Some(ErrorKind::UserDeactivated) => {
                    "This account has been deactivated.".to_string()
                }
                Some(ErrorKind::LimitExceeded(_)) => {
                    "Too many attempts. Wait a moment and try again.".to_string()
                }
                _ => format!("Sign-in failed: {error}"),
            };
            Err(anyhow::anyhow!(message))
        }
    }
}

fn store_config(session: &ClientSession) -> SqliteStoreConfig {
    let config = SqliteStoreConfig::new(&session.db_path);
    match &session.store_key {
        Some(key) => config.key(Some(key)),
        None => config.passphrase(Some(&session.passphrase)),
    }
}

/// Re-keys the stores of a session made with a passphrase (once), so they open
/// with `store_key`. Crash-safe: the new key is saved before any store changes,
/// each store is skipped once it opens with the key, and the passphrase is only
/// dropped after all of them did.
async fn migrate_to_store_key(session_file: &Path, session: &mut FullSession) -> anyhow::Result<()> {
    let client_session = &mut session.client_session;
    if client_session.passphrase.is_empty() {
        return Ok(());
    }
    let key = match client_session.store_key {
        Some(key) => key,
        None => {
            let key: StoreKey = rng().random();
            client_session.store_key = Some(key);
            write_session(session_file, session).await?;
            key
        }
    };
    let client_session = &mut session.client_session;
    let db_path = client_session.db_path.clone();
    let passphrase = client_session.passphrase.clone();
    tokio::task::spawn_blocking(move || {
        // One thread per store: each runs a slow PBKDF2 one last time.
        std::thread::scope(|scope| {
            let migrations: Vec<_> = matrix_sdk_sqlite_files(&db_path)
                .map(|path| {
                    let passphrase = &passphrase;
                    scope.spawn(move || rekey_store(&path, passphrase, &key))
                })
                .collect();
            migrations
                .into_iter()
                .try_for_each(|m| m.join().map_err(|_| anyhow::anyhow!("re-key panicked"))?)
        })
    })
    .await??;
    session.client_session.passphrase.clear();
    write_session(session_file, session).await?;
    tracing::info!("stores re-keyed");
    Ok(())
}

/// The databases `sqlite_store` creates in `db_path`.
fn matrix_sdk_sqlite_files(db_path: &Path) -> impl Iterator<Item = PathBuf> + '_ {
    [
        "matrix-sdk-state.sqlite3",
        "matrix-sdk-crypto.sqlite3",
        "matrix-sdk-event-cache.sqlite3",
        "matrix-sdk-media.sqlite3",
    ]
    .into_iter()
    .map(|name| db_path.join(name))
}

/// Re-encrypts a store's cipher (`kv` row `cipher`) from the passphrase to `key`.
fn rekey_store(path: &Path, passphrase: &str, key: &StoreKey) -> anyhow::Result<()> {
    use matrix_sdk_store_encryption::StoreCipher;
    use rusqlite::OptionalExtension;

    if !path.exists() {
        return Ok(());
    }
    let conn = rusqlite::Connection::open(path)?;
    let encrypted: Option<Vec<u8>> = conn
        .query_row("SELECT value FROM kv WHERE key = 'cipher'", [], |row| row.get(0))
        .optional()?;
    // No cipher yet: the store creates one with the key.
    let Some(encrypted) = encrypted else {
        return Ok(());
    };
    if StoreCipher::import_with_key(key, &encrypted).is_ok() {
        return Ok(());
    }
    let export = StoreCipher::import(passphrase, &encrypted)?.export_with_key(key)?;
    conn.execute("UPDATE kv SET value = ?1 WHERE key = 'cipher'", (export,))?;
    Ok(())
}

/// Writes the session file atomically (temporary file, then rename).
async fn write_session(session_file: &Path, session: &FullSession) -> anyhow::Result<()> {
    let tmp = session_file.with_extension("tmp");
    fs::write(&tmp, serde_json::to_string(session)?).await?;
    fs::rename(&tmp, session_file).await?;
    Ok(())
}

/// `discover`: whether to resolve `homeserver` via a `.well-known` network
/// lookup. This blocks on network I/O with no timeout, so it must be `false`
/// when restoring a session — `homeserver` is already the fully-resolved
/// base URL saved from a prior successful login/discovery, and skipping
/// discovery lets the client build (and the room list render from the local
/// cache) even while offline. Fresh logins (where the user may have typed a
/// bare server name) still need `discover: true`.
fn get_client_builder(
    homeserver: &String,
    store_config: SqliteStoreConfig,
    discover: bool,
) -> ClientBuilder {
    let builder = if discover {
        Client::builder().server_name_or_homeserver_url(homeserver)
    } else {
        Client::builder().homeserver_url(homeserver)
    };
    // Build the client with the previous settings from the session.
    builder
        .sqlite_store_with_config_and_cache_path(store_config, None::<PathBuf>)
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
    let (db_path, store_key) = {
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

        let store_key: StoreKey = rng.random();

        (db_path, store_key)
    };
    let session = ClientSession {
        homeserver: homeserver.to_string(),
        db_path,
        passphrase: String::new(),
        store_key: Some(store_key),
    };

    tracing::info!("checking homeserver {homeserver}");

    let client_build = get_client_builder(&session.homeserver, store_config(&session), true)
        .build()
        .await;

    match client_build {
        Ok(client) => {
            let homeserver = client.homeserver().to_string();
            return Ok((client, ClientSession { homeserver, ..session }));
        }
        Err(error) => match &error {
            matrix_sdk::ClientBuildError::AutoDiscovery(_)
            | matrix_sdk::ClientBuildError::Url(_)
            | matrix_sdk::ClientBuildError::Http(_) => {
                tracing::warn!("homeserver check failed: {error}");
                Err(anyhow::anyhow!(
                    "Couldn't reach a Matrix server for {homeserver}."
                ))
            }
            _ => {
                // Forward other errors, it's unlikely we can retry with a different outcome.
                tracing::error!("homeserver error: {error}");
                return Err(error.into());
            }
        },
    }
}

// ── Theme preference persistence ─────────────────────────────────────────────

// ── Media download ────────────────────────────────────────────────────────────

// ── DM helpers ────────────────────────────────────────────────────────────────

pub async fn create_or_get_dm(user_id: String) -> Option<String> {
    let client = CLIENT.get().cloned()?;
    let Ok(parsed) = matrix_sdk::ruma::UserId::parse(&user_id) else {
        return None;
    };
    if let Some(room) = client.get_dm_room(&parsed) {
        return Some(room.room_id().to_string());
    }
    crate::utils::on_tokio(async move {
        use matrix_sdk::ruma::api::client::room::create_room::v3::Request as CreateRoom;
        let mut req = CreateRoom::new();
        req.is_direct = true;
        req.invite = vec![parsed.to_owned()];
        let room = client.create_room(req).await.ok()?;
        Some(room.room_id().to_string())
    })
    .await
    .flatten()
}

#[cfg(test)]
mod tests {
    use matrix_sdk::SqliteCryptoStore;

    use super::*;

    #[tokio::test]
    async fn rekey_store_moves_a_passphrase_store_to_the_key() {
        let dir = tempfile::tempdir().unwrap();
        let passphrase = "old passphrase";
        let key: StoreKey = [7; 32];
        drop(SqliteCryptoStore::open(dir.path(), Some(passphrase)).await.unwrap());

        let db = dir.path().join("matrix-sdk-crypto.sqlite3");
        rekey_store(&db, passphrase, &key).unwrap();
        // Idempotent: a second run (after a crash) leaves it keyed.
        rekey_store(&db, passphrase, &key).unwrap();

        assert!(SqliteCryptoStore::open_with_key(dir.path(), Some(&key)).await.is_ok());
        assert!(SqliteCryptoStore::open_with_key(dir.path(), Some(&[8; 32])).await.is_err());
        assert!(SqliteCryptoStore::open(dir.path(), Some(passphrase)).await.is_err());
    }

    #[test]
    fn rekey_store_skips_missing_stores() {
        let dir = tempfile::tempdir().unwrap();
        let missing = dir.path().join("matrix-sdk-media.sqlite3");
        rekey_store(&missing, "passphrase", &[0; 32]).unwrap();
        assert!(!missing.exists());
    }
}
