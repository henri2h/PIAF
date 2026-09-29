use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::OnceLock;
use std::sync::atomic::AtomicBool;

use tokio::sync::watch;

use crate::utils::{
    self, bookmarks::BookmarksEventContent, room_mailbox::RoomMailboxState, worker::Requester,
    worker::client::MatrixClientWorker,
};

pub static REQUESTER: OnceLock<Requester> = OnceLock::new();
pub static SYNC_TX: OnceLock<watch::Sender<()>> = OnceLock::new();
pub static SYNC_RX: OnceLock<watch::Receiver<()>> = OnceLock::new();
pub static ACTIVE_ROOM_TX: OnceLock<watch::Sender<Option<String>>> = OnceLock::new();
pub static ACTIVE_ROOM_RX: OnceLock<watch::Receiver<Option<String>>> = OnceLock::new();
/// `(room_id, event_id)` to scroll to once the room opens.
pub static FOCUS_EVENT_TX: OnceLock<watch::Sender<Option<(String, String)>>> = OnceLock::new();
pub static FOCUS_EVENT_RX: OnceLock<watch::Receiver<Option<(String, String)>>> = OnceLock::new();
pub static REACTIONS_TX: OnceLock<watch::Sender<Vec<utils::ReceivedReaction>>> = OnceLock::new();
pub static REACTIONS_RX: OnceLock<watch::Receiver<Vec<utils::ReceivedReaction>>> = OnceLock::new();
pub static BOOKMARKS_TX: OnceLock<watch::Sender<BookmarksEventContent>> = OnceLock::new();
pub static BOOKMARKS_RX: OnceLock<watch::Receiver<BookmarksEventContent>> = OnceLock::new();
pub static ROOM_MAILBOX_TX: OnceLock<watch::Sender<HashMap<String, RoomMailboxState>>> =
    OnceLock::new();
pub static ROOM_MAILBOX_RX: OnceLock<watch::Receiver<HashMap<String, RoomMailboxState>>> =
    OnceLock::new();
/// Window wide enough for split-pane view. Written by `Layout`.
pub static WIDE_MODE: AtomicBool = AtomicBool::new(false);
/// Last sync attempt failed.
pub static DISCONNECTED: AtomicBool = AtomicBool::new(false);
/// The app window has OS focus. Mirrored from Freya by the desktop `Layout`;
/// desktop notifications are only shown while it's false.
pub static APP_FOCUSED: AtomicBool = AtomicBool::new(true);
/// The server revoked our access token (e.g. device removed elsewhere).
/// Sync stops; the user must restart and sign in again.
pub static SESSION_EXPIRED: AtomicBool = AtomicBool::new(false);

/// Initializes all globals, then restores the session in the background.
/// Must run inside a Tokio runtime context.
pub fn init(data_dir: PathBuf) {
    REQUESTER.set(MatrixClientWorker::spawn()).unwrap();

    let (tx, rx) = watch::channel(());
    SYNC_TX.set(tx).unwrap();
    SYNC_RX.set(rx).unwrap();

    let (tx, rx) = watch::channel(None);
    ACTIVE_ROOM_TX.set(tx).unwrap();
    ACTIVE_ROOM_RX.set(rx).unwrap();

    let (tx, rx) = watch::channel(None);
    FOCUS_EVENT_TX.set(tx).unwrap();
    FOCUS_EVENT_RX.set(rx).unwrap();

    let (tx, rx) = watch::channel(vec![]);
    REACTIONS_TX.set(tx).unwrap();
    REACTIONS_RX.set(rx).unwrap();

    let (tx, rx) = watch::channel(BookmarksEventContent::default());
    BOOKMARKS_TX.set(tx).unwrap();
    BOOKMARKS_RX.set(rx).unwrap();

    let (tx, rx) = watch::channel(HashMap::new());
    ROOM_MAILBOX_TX.set(tx).unwrap();
    ROOM_MAILBOX_RX.set(rx).unwrap();

    tokio::spawn(async move {
        match utils::matrix::restore_matrix_client(data_dir).await {
            Ok(available) => tracing::info!("session restored: {available}"),
            Err(e) => tracing::warn!("could not restore session: {e:#}"),
        }
        let _ = SYNC_TX.get().map(|tx| tx.send(()));
    });
}
