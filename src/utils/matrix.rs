use std::sync::atomic::Ordering;

use futures::channel::oneshot;
use matrix_sdk::{
    Client, ClientBuilder, Room, ServerName,
    authentication::matrix::MatrixSession,
    encryption::{BackupDownloadStrategy, EncryptionSettings},
    ruma::{
        UserId,
        events::{
            AnySyncMessageLikeEvent, AnySyncTimelineEvent, OriginalSyncMessageLikeEvent,
            SyncMessageLikeEvent, reaction::ReactionEventContent,
        },
        exports::serde_json,
    },
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
use crate::utils::room_preview::message_body;

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
/// Ensures the reaction event handler is registered at most once across all
/// calls to `activate_client` (login + restore can both call it).
static REACTION_HANDLER_GUARD: OnceLock<()> = OnceLock::new();
/// Fingerprint of the room list as of the last `SYNC_TX` fire, used by
/// `notify_sync_if_changed` to suppress redundant UI wakeups.
static LAST_ROOM_FINGERPRINT: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
#[cfg(not(target_os = "android"))]
static NOTIFICATION_HANDLER_GUARD: OnceLock<()> = OnceLock::new();

#[cfg(not(target_os = "android"))]
/// Events older than this are catch-up, not something to notify about.
const NOTIFY_MAX_AGE_MS: u64 = 5 * 60 * 1000;
#[cfg(not(target_os = "android"))]
/// When this client session started (ms since epoch); older events never notify.
static NOTIFY_SINCE_MS: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);

#[cfg(not(target_os = "android"))]
fn now_ms() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

#[cfg(not(target_os = "android"))]
/// Desktop notification gate: only messages sent since this session started,
/// still fresh, and only while the window is in the background.
fn should_notify(event_ts_ms: u64, now_ms: u64, since_ms: u64, app_focused: bool) -> bool {
    !app_focused
        && event_ts_ms >= since_ms
        && now_ms.saturating_sub(event_ts_ms) <= NOTIFY_MAX_AGE_MS
}

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
        let client = if let Some(existing) = CLIENT.get() {
            existing.clone()
        } else {
            let c = restore_session(&session_file).await?;
            let _ = CLIENT.set(c.clone());
            tracing::debug!("restore_matrix_client: CLIENT set");
            c
        };

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
        activate_client(&client, &base_dir).await;
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
    let FullSession {
        client_session,
        user_session,
    } = serde_json::from_str(&serialized_session)?;

    // discover: false — homeserver is already a resolved base URL from the
    // prior login, so this builds instantly with no network I/O and works offline.
    let client = get_client_builder(
        &client_session.homeserver,
        &client_session.db_path,
        &client_session.passphrase,
        false,
    )
    .build()
    .await?;

    tracing::info!("Restoring session for {}…", user_session.meta.user_id);

    // Restore the Matrix user session.
    client.restore_session(user_session).await?;

    Ok(client)
}

async fn activate_client(client: &Client, _pusher_dir: &Path) {
    watch_session_expiry(client);
    if let Err(e) = crate::utils::sync::init(client).await {
        tracing::error!("activate_client: SyncService build failed: {e:#}");
    }

    #[cfg(target_os = "android")]
    crate::utils::push::register_pusher_if_stored(client, _pusher_dir).await;

    // Track reactions to the current user's messages for the Reactions feed.
    // The OnceLock guard ensures the handler is registered exactly once even if
    // activate_client is called on both the restore and login paths.
    if REQUESTER.get().is_some() && REACTION_HANDLER_GUARD.set(()).is_ok() {
        client.add_event_handler(
            |ev: OriginalSyncMessageLikeEvent<ReactionEventContent>, room: Room, client: Client| async move {
                collect_reaction(ev, room, client).await;
            },
        );
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

    // Desktop notifications for incoming messages.
    #[cfg(not(target_os = "android"))]
    if REQUESTER.get().is_some() && NOTIFICATION_HANDLER_GUARD.set(()).is_ok() {
        use matrix_sdk::ruma::events::room::message::RoomMessageEventContent;
        NOTIFY_SINCE_MS.store(now_ms(), Ordering::Relaxed);
        client.add_event_handler(
            |ev: OriginalSyncMessageLikeEvent<RoomMessageEventContent>,
             room: Room,
             client: Client| async move {
                send_desktop_notification(ev, room, client).await;
            },
        );
    }

    // No REQUESTER means the Android push context: enrichment only, no sync.
    if REQUESTER.get().is_some() {
        tracing::debug!("activate_client: starting sync service");
        crate::utils::sync::start(client.clone());
    }
}

async fn collect_reaction(
    ev: OriginalSyncMessageLikeEvent<ReactionEventContent>,
    room: Room,
    client: Client,
) {
    let Some(me) = client.user_id() else { return };
    if ev.sender == me {
        return;
    }

    let target_event_id = ev.content.relates_to.event_id.clone();
    let emoji = ev.content.relates_to.key.clone();
    let timestamp_ms: u64 = ev.origin_server_ts.0.into();

    let Ok(target_event) = room.event(&target_event_id, None).await else {
        return;
    };
    let Ok(deserialized) = target_event.kind.raw().deserialize() else {
        return;
    };

    if deserialized.sender() != me {
        return;
    }

    let message_preview = extract_message_preview(&deserialized);

    let room_name = room
        .display_name()
        .await
        .map(|n| n.to_string())
        .unwrap_or_default();

    let sender_display = room
        .get_member_no_sync(&ev.sender)
        .await
        .ok()
        .flatten()
        .and_then(|m| m.display_name().map(|s| s.to_string()))
        .unwrap_or_else(|| ev.sender.localpart().to_string());

    let reaction = crate::utils::ReceivedReaction {
        room_id: room.room_id().to_string(),
        room_name,
        target_event_id: target_event_id.to_string(),
        message_preview,
        emoji,
        sender_id: ev.sender.to_string(),
        sender_display,
        timestamp_ms,
    };

    crate::REACTIONS_TX
        .get()
        .expect("REACTIONS_TX not initialized")
        .send_modify(|v| {
            // Dedup: the list is sorted descending by timestamp; binary-search for the
            // insertion point so we avoid a full O(n log n) re-sort on every reaction.
            let ts = reaction.timestamp_ms;
            let already_exists = v.iter().any(|r| {
                r.sender_id == reaction.sender_id
                    && r.target_event_id == reaction.target_event_id
                    && r.emoji == reaction.emoji
            });
            if !already_exists {
                // partition_point on descending order: first index where ts[i] < ts.
                let pos = v.partition_point(|r| r.timestamp_ms > ts);
                v.insert(pos, reaction);
            }
        });
}

fn extract_message_preview(event: &AnySyncTimelineEvent) -> String {
    let body = match event {
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
            SyncMessageLikeEvent::Original(msg),
        )) => message_body(&msg.content.msgtype),
        _ => None,
    };
    body.map(|b| b.chars().take(60).collect())
        .unwrap_or_else(|| "Message".to_string())
}

#[cfg(not(target_os = "android"))]
async fn send_desktop_notification(
    ev: OriginalSyncMessageLikeEvent<
        matrix_sdk::ruma::events::room::message::RoomMessageEventContent,
    >,
    room: Room,
    client: Client,
) {
    let event_ts_ms: u64 = ev.origin_server_ts.0.into();
    if !should_notify(
        event_ts_ms,
        now_ms(),
        NOTIFY_SINCE_MS.load(Ordering::Relaxed),
        crate::APP_FOCUSED.load(Ordering::Relaxed),
    ) {
        return;
    }
    let Some(me) = client.user_id() else { return };
    if ev.sender == me {
        return;
    }

    // Skip muted rooms.
    let ns = client.notification_settings().await;
    let mode = ns
        .get_user_defined_room_notification_mode(room.room_id())
        .await;
    if mode == Some(matrix_sdk::notification_settings::RoomNotificationMode::Mute) {
        return;
    }

    let room_name = room
        .cached_display_name()
        .map(|n| n.to_string())
        .unwrap_or_else(|| room.room_id().to_string());

    let sender_name = room
        .get_member_no_sync(&ev.sender)
        .await
        .ok()
        .flatten()
        .and_then(|m| m.display_name().map(|s| s.to_string()))
        .unwrap_or_else(|| ev.sender.localpart().to_string());

    let body = match &ev.content.msgtype {
        matrix_sdk::ruma::events::room::message::MessageType::Emote(e) => {
            format!("* {} {}", sender_name, e.body)
        }
        other => message_body(other).unwrap_or_else(|| "New message".to_string()),
    };

    let summary = if room.is_dm() {
        sender_name.clone()
    } else {
        format!("{sender_name} · {room_name}")
    };

    let _ = notify_rust::Notification::new()
        .appname("Piaf")
        .summary(&summary)
        .body(&body)
        .icon("dialog-information")
        .timeout(notify_rust::Timeout::Milliseconds(5000))
        .show();
}

pub async fn login_matrix(username: String, password: String) -> anyhow::Result<()> {
    let session_file = SESSION_FILE.get().unwrap();
    let data_dir = DATA_DIR.get().unwrap();

    let account = UserId::parse(username.as_str())?;

    let (client, client_session) = new_client(&data_dir, account.server_name()).await?;

    let matrix_auth = client.matrix_auth();

    tracing::info!("Trying login in user {username}");

    match matrix_auth
        .login_username(&username, &password)
        .initial_device_display_name("persist-session client")
        .await
    {
        Ok(_) => {
            tracing::info!("Logged in as {username}");

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

            activate_client(CLIENT.get().unwrap(), data_dir).await;

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

/// `discover`: whether to resolve `homeserver` via a `.well-known` network
/// lookup. This blocks on network I/O with no timeout, so it must be `false`
/// when restoring a session — `homeserver` is already the fully-resolved
/// base URL saved from a prior successful login/discovery, and skipping
/// discovery lets the client build (and the room list render from the local
/// cache) even while offline. Fresh logins (where the user may have typed a
/// bare server name) still need `discover: true`.
fn get_client_builder(
    homeserver: &String,
    db_path: &PathBuf,
    passphrase: &String,
    discover: bool,
) -> ClientBuilder {
    let builder = if discover {
        Client::builder().server_name_or_homeserver_url(homeserver)
    } else {
        Client::builder().homeserver_url(homeserver)
    };
    // Build the client with the previous settings from the session.
    builder
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

    tracing::info!("checking homeserver {homeserver}");

    let client_build = get_client_builder(&homeserver.to_string(), &db_path, &passphrase, true)
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

/// Cheap fingerprint of "does the room list look any different from last
/// time we woke the UI". Sync loops (raw `/sync` and the sliding-sync room
/// list service) both complete periodically even when nothing changed (e.g.
/// long-poll timeouts); firing `SYNC_TX` on every one of those forces
/// `RoomList` to rebuild and sort its full room vector for no reason. This
/// intentionally skips `latest_event().timestamp()` (expensive: walks the
/// room's timeline) in favor of `recency_stamp`, which the server already
/// bumps whenever it considers the room updated.
fn room_list_fingerprint(client: &Client) -> u64 {
    use std::hash::{Hash, Hasher};

    let mut hasher = std::collections::hash_map::DefaultHasher::new();
    let mut rooms = client.joined_rooms();
    rooms.extend(client.invited_rooms());
    rooms.len().hash(&mut hasher);
    for room in &rooms {
        room.room_id().hash(&mut hasher);
        room.recency_stamp().map(u64::from).hash(&mut hasher);
        (room.state() == matrix_sdk::RoomState::Invited).hash(&mut hasher);
        room.num_unread_messages().hash(&mut hasher);
        room.num_unread_notifications().hash(&mut hasher);
        room.cached_user_defined_notification_mode()
            .map(|m| m as u8)
            .hash(&mut hasher);
    }
    hasher.finish()
}

/// Fires `SYNC_TX` only if the room list actually looks different since the
/// last time this was called. See `room_list_fingerprint`.
pub fn notify_sync_if_changed(client: &Client, source: &'static str) {
    let start = std::time::Instant::now();
    let fp = room_list_fingerprint(client);
    let prev = LAST_ROOM_FINGERPRINT.swap(fp, Ordering::Relaxed);
    let changed = prev != fp;
    if changed {
        let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
    }
    tracing::debug!(
        target: crate::logging::PERF,
        source,
        changed,
        "sync batch, fingerprint {}µs",
        start.elapsed().as_micros()
    );
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

// ── Media download ────────────────────────────────────────────────────────────

fn media_extension(bytes: &[u8]) -> &'static str {
    if bytes.starts_with(b"\x89PNG") {
        "png"
    } else if bytes.starts_with(b"\xFF\xD8\xFF") {
        "jpg"
    } else if bytes.starts_with(b"GIF8") {
        "gif"
    } else if bytes.len() >= 12 && &bytes[..4] == b"RIFF" && &bytes[8..12] == b"WEBP" {
        "webp"
    } else {
        "bin"
    }
}

pub async fn save_media_to_downloads(bytes: &[u8]) {
    let Some(data_dir) = DATA_DIR.get() else {
        return;
    };
    let downloads_dir = data_dir.join("downloads");
    let _ = fs::create_dir_all(&downloads_dir).await;
    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis();
    let ext = media_extension(bytes);
    let path = downloads_dir.join(format!("media_{}.{}", ts, ext));
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

#[cfg(test)]
mod tests {
    use super::{NOTIFY_MAX_AGE_MS, should_notify};

    const SINCE: u64 = 1_000_000;

    #[test]
    fn notifies_fresh_message_in_background() {
        assert!(should_notify(SINCE + 10, SINCE + 20, SINCE, false));
    }

    #[test]
    fn never_while_focused() {
        assert!(!should_notify(SINCE + 10, SINCE + 20, SINCE, true));
    }

    #[test]
    fn skips_history_from_before_session() {
        assert!(!should_notify(SINCE - 1, SINCE + 20, SINCE, false));
    }

    #[test]
    fn skips_stale_catch_up() {
        let ts = SINCE + 10;
        assert!(!should_notify(ts, ts + NOTIFY_MAX_AGE_MS + 1, SINCE, false));
        assert!(should_notify(ts, ts + NOTIFY_MAX_AGE_MS, SINCE, false));
    }

    #[test]
    fn server_clock_ahead_is_fresh() {
        assert!(should_notify(SINCE + 5_000, SINCE + 10, SINCE, false));
    }

    use super::media_extension;

    #[test]
    fn detects_png() {
        // PNG magic: \x89 P N G
        assert_eq!(media_extension(b"\x89PNG\r\n\x1a\nextra"), "png");
    }

    #[test]
    fn detects_jpeg() {
        // JPEG SOI marker: FF D8 FF
        assert_eq!(media_extension(b"\xFF\xD8\xFF\xE0extra"), "jpg");
    }

    #[test]
    fn detects_gif() {
        // GIF87a and GIF89a both start with GIF8
        assert_eq!(media_extension(b"GIF89a..."), "gif");
        assert_eq!(media_extension(b"GIF87a..."), "gif");
    }

    #[test]
    fn detects_webp() {
        // WebP: RIFF????WEBP
        let mut bytes = Vec::new();
        bytes.extend_from_slice(b"RIFF");
        bytes.extend_from_slice(&[0u8; 4]); // file size (ignored)
        bytes.extend_from_slice(b"WEBP");
        bytes.extend_from_slice(b"VP8 extra");
        assert_eq!(media_extension(&bytes), "webp");
    }

    #[test]
    fn unknown_format_returns_bin() {
        assert_eq!(media_extension(b"PK\x03\x04"), "bin"); // zip
        assert_eq!(media_extension(b"unknown data"), "bin");
    }

    #[test]
    fn empty_slice_returns_bin() {
        assert_eq!(media_extension(b""), "bin");
    }

    #[test]
    fn webp_requires_full_12_byte_header() {
        // RIFF present but only 11 bytes — must not panic
        let bytes = b"RIFF\x00\x00\x00\x00WEB";
        assert_eq!(media_extension(bytes), "bin");
    }
}
