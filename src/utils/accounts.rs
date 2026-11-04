//! Signed-in accounts. One is active (its client runs); switching restarts
//! the app, since the client and everything built on it are set once per
//! process.
//!
//! Layout under the data dir (`persist_session/`):
//! - `accounts.json`: the [`Registry`]
//! - `accounts/<id>/`: one account's `session` file, its stores, drafts,
//!   recent searches and cached avatar.

use std::path::{Path, PathBuf};
use std::sync::{Mutex, OnceLock};

use matrix_sdk::ruma::exports::serde_json;
use rand::{RngExt, rng};
use rand_distr::Alphanumeric;
use serde::{Deserialize, Serialize};

const REGISTRY_FILE: &str = "accounts.json";
const ACCOUNTS_DIR: &str = "accounts";
pub const SESSION_FILE: &str = "session";
const AVATAR_FILE: &str = "avatar";

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
pub struct Account {
    /// Directory name under `accounts/`.
    pub id: String,
    pub user_id: String,
    /// Cached while the account is active, for the switcher.
    #[serde(default)]
    pub display_name: Option<String>,
    /// The server revoked the session: shown to sign in again.
    #[serde(default)]
    pub expired: bool,
}

impl Account {
    /// Display name, else the user ID.
    pub fn name(&self) -> &str {
        self.display_name.as_deref().unwrap_or(&self.user_id)
    }
}

#[derive(Clone, Debug, Default, PartialEq, Serialize, Deserialize)]
pub struct Registry {
    #[serde(default)]
    pub active: Option<String>,
    #[serde(default)]
    pub accounts: Vec<Account>,
}

impl Registry {
    pub fn get(&self, id: &str) -> Option<&Account> {
        self.accounts.iter().find(|a| a.id == id)
    }

    pub fn active(&self) -> Option<&Account> {
        self.active.as_deref().and_then(|id| self.get(id))
    }

    /// The account to open at startup: the active one, else the first that
    /// isn't expired. Becomes the active one.
    fn pick_startup(&mut self) -> Option<Account> {
        let usable = |a: &&Account| !a.expired;
        let pick = self
            .active()
            .filter(usable)
            .or_else(|| self.accounts.iter().find(usable))
            .cloned();
        self.active = pick.as_ref().map(|a| a.id.clone());
        pick
    }

    /// Removes `id`; the active account moves to the next usable one.
    fn remove(&mut self, id: &str) {
        self.accounts.retain(|a| a.id != id);
        if self.active.as_deref() == Some(id) {
            self.active = None;
            self.pick_startup();
        }
    }

    /// Adds `account` as the active one, replacing an entry of the same user
    /// (an expired session signed in again). Returns the replaced account.
    fn add(&mut self, account: Account) -> Option<Account> {
        let replaced = self
            .accounts
            .iter()
            .position(|a| a.user_id == account.user_id)
            .map(|i| self.accounts.remove(i));
        self.active = Some(account.id.clone());
        self.accounts.push(account);
        replaced
    }
}

static ROOT: OnceLock<PathBuf> = OnceLock::new();
/// In memory, mirrored to `accounts.json` on every change.
static REGISTRY: Mutex<Option<Registry>> = Mutex::new(None);

fn root() -> Option<&'static Path> {
    ROOT.get().map(PathBuf::as_path)
}

/// Sets the data dir, moves a single-account install into `accounts/`, and
/// loads the registry. Idempotent.
pub fn init(data_dir: &Path) {
    if ROOT.set(data_dir.to_path_buf()).is_err() {
        return;
    }
    let registry = load(data_dir).unwrap_or_else(|| migrate(data_dir));
    *REGISTRY.lock().unwrap() = Some(registry);
}

fn load(data_dir: &Path) -> Option<Registry> {
    let json = std::fs::read_to_string(data_dir.join(REGISTRY_FILE)).ok()?;
    match serde_json::from_str(&json) {
        Ok(registry) => Some(registry),
        Err(e) => {
            tracing::error!("accounts: unreadable registry: {e}");
            None
        }
    }
}

/// Before accounts: `persist_session/session`, with drafts and recent
/// searches next to `persist_session/`.
fn migrate(data_dir: &Path) -> Registry {
    let mut registry = Registry::default();
    let legacy = data_dir.join(SESSION_FILE);
    let Some(user_id) = session_user_id(&legacy) else {
        return registry;
    };
    let account = new_account(&user_id);
    let dir = data_dir.join(ACCOUNTS_DIR).join(&account.id);
    let moved = std::fs::create_dir_all(&dir)
        .and_then(|()| std::fs::rename(&legacy, dir.join(SESSION_FILE)));
    if let Err(e) = moved {
        tracing::error!("accounts: could not move the session: {e}");
        return registry;
    }
    if let Some(base) = data_dir.parent() {
        for file in ["drafts.json", "recent_searches.json"] {
            let _ = std::fs::rename(base.join(file), dir.join(file));
        }
    }
    registry.add(account);
    if let Err(e) = write(data_dir, &registry) {
        tracing::error!("accounts: could not save the registry: {e}");
    }
    tracing::info!("accounts: moved the session into accounts/");
    registry
}

/// The user ID stored in a session file.
fn session_user_id(session_file: &Path) -> Option<String> {
    let json = std::fs::read_to_string(session_file).ok()?;
    let value: serde_json::Value = serde_json::from_str(&json).ok()?;
    value
        .pointer("/user_session/user_id")?
        .as_str()
        .map(str::to_string)
}

fn new_account(user_id: &str) -> Account {
    let id = rng()
        .sample_iter(Alphanumeric)
        .take(8)
        .map(char::from)
        .collect();
    Account {
        id,
        user_id: user_id.to_string(),
        display_name: None,
        expired: false,
    }
}

fn write(data_dir: &Path, registry: &Registry) -> std::io::Result<()> {
    let path = data_dir.join(REGISTRY_FILE);
    let tmp = path.with_extension("tmp");
    std::fs::write(&tmp, serde_json::to_string_pretty(registry)?)?;
    std::fs::rename(&tmp, &path)
}

/// Changes the registry and saves it.
fn update<T>(change: impl FnOnce(&mut Registry) -> T) -> T {
    let mut guard = REGISTRY.lock().unwrap();
    let registry = guard.get_or_insert_with(Registry::default);
    let result = change(registry);
    if let Some(root) = root()
        && let Err(e) = write(root, registry)
    {
        tracing::error!("accounts: could not save the registry: {e}");
    }
    result
}

pub fn registry() -> Registry {
    REGISTRY.lock().unwrap().clone().unwrap_or_default()
}

/// The account's directory.
pub fn dir(id: &str) -> Option<PathBuf> {
    Some(root()?.join(ACCOUNTS_DIR).join(id))
}

/// The account to restore at startup (saved as the active one).
pub fn startup_account() -> Option<Account> {
    update(Registry::pick_startup)
}

/// A new account's directory, for a sign-in in progress: registered by
/// [`commit`] once signed in, else deleted with [`discard`].
pub fn prepare(user_id: &str) -> std::io::Result<(Account, PathBuf)> {
    let account = new_account(user_id);
    let dir = dir(&account.id).ok_or_else(|| std::io::Error::other("no data dir"))?;
    std::fs::create_dir_all(&dir)?;
    Ok((account, dir))
}

pub async fn discard(account: &Account) {
    if let Some(dir) = dir(&account.id) {
        let _ = tokio::fs::remove_dir_all(dir).await;
    }
}

/// Registers a signed-in account as the active one. An older entry of the
/// same user (expired) is replaced and its data deleted.
pub async fn commit(account: Account) {
    if let Some(old) = update(|r| r.add(account)) {
        delete_data(&old).await;
    }
}

/// Restarts into account `id` (the client is set once per process), then
/// opens `room_id`, if any.
pub fn switch_to(id: &str, room_id: Option<&str>) -> ! {
    tracing::info!("switching account");
    set_active(id);
    if let Some(room_id) = room_id {
        save_open_room(room_id);
    }
    crate::app::restart::restart()
}

/// Makes `id` the account opened at the next start.
pub fn set_active(id: &str) {
    update(|r| r.active = Some(id.to_string()));
}

/// Forgets the account and deletes its data. The active account moves to the
/// next one, if any.
pub async fn remove(id: &str) {
    let Some(account) = update(|r| {
        let account = r.get(id).cloned();
        r.remove(id);
        account
    }) else {
        return;
    };
    delete_data(&account).await;
}

/// The session file, its stores (which older installs keep outside the
/// account directory) and everything else in the directory.
async fn delete_data(account: &Account) {
    let Some(dir) = dir(&account.id) else {
        return;
    };
    if let Some(db_path) = crate::utils::matrix::session_db_path(&dir.join(SESSION_FILE)).await
        && !db_path.starts_with(&dir)
        && let Err(e) = tokio::fs::remove_dir_all(&db_path).await
    {
        tracing::warn!("accounts: could not delete stores: {e}");
    }
    if let Err(e) = tokio::fs::remove_dir_all(&dir).await {
        tracing::warn!("accounts: could not delete the account: {e}");
    }
}

pub fn mark_expired(id: &str) {
    update(|r| {
        if let Some(a) = r.accounts.iter_mut().find(|a| a.id == id) {
            a.expired = true;
        }
    });
}

/// Caches the active account's name and avatar for the switcher.
pub fn save_profile(id: &str, display_name: Option<String>, avatar: Option<Vec<u8>>) {
    let changed = update(|r| {
        let Some(a) = r.accounts.iter_mut().find(|a| a.id == id) else {
            return false;
        };
        let changed = a.display_name != display_name;
        a.display_name = display_name;
        changed
    });
    let Some(file) = dir(id).map(|d| d.join(AVATAR_FILE)) else {
        return;
    };
    let _ = match avatar {
        Some(bytes) => std::fs::write(file, bytes),
        None => std::fs::remove_file(file),
    };
    if changed {
        tracing::debug!("accounts: profile updated");
    }
}

/// The avatar cached by [`save_profile`].
pub fn avatar(id: &str) -> Option<bytes::Bytes> {
    let file = dir(id)?.join(AVATAR_FILE);
    std::fs::read(file).ok().map(bytes::Bytes::from)
}

const OPEN_ROOM_FILE: &str = "open_room";

/// A room to open after the restart into its account (a tapped notification
/// of another account).
pub fn save_open_room(room_id: &str) {
    if let Some(root) = root() {
        let _ = std::fs::write(root.join(OPEN_ROOM_FILE), room_id);
    }
}

/// The room saved by [`save_open_room`], once. `data_dir` is the data dir
/// itself: this runs before [`init`].
pub fn take_open_room(data_dir: &Path) -> Option<String> {
    let file = data_dir.join(OPEN_ROOM_FILE);
    let room_id = std::fs::read_to_string(&file).ok()?;
    let _ = std::fs::remove_file(file);
    Some(room_id.trim().to_string()).filter(|r| !r.is_empty())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn account(id: &str, expired: bool) -> Account {
        Account {
            id: id.into(),
            user_id: format!("@{id}:x"),
            display_name: None,
            expired,
        }
    }

    fn registry(active: Option<&str>, accounts: Vec<Account>) -> Registry {
        Registry {
            active: active.map(str::to_string),
            accounts,
        }
    }

    #[test]
    fn startup_skips_an_expired_active_account() {
        let mut r = registry(Some("a"), vec![account("a", true), account("b", false)]);
        assert_eq!(r.pick_startup().map(|a| a.id), Some("b".into()));
        assert_eq!(r.active.as_deref(), Some("b"));
    }

    #[test]
    fn startup_without_usable_accounts_opens_none() {
        let mut r = registry(Some("a"), vec![account("a", true)]);
        assert_eq!(r.pick_startup(), None);
        assert_eq!(r.active, None);
    }

    #[test]
    fn removing_the_active_account_moves_to_the_next() {
        let mut r = registry(Some("a"), vec![account("a", false), account("b", false)]);
        r.remove("a");
        assert_eq!(r.active.as_deref(), Some("b"));
        r.remove("b");
        assert_eq!(r.active, None);
        assert!(r.accounts.is_empty());
    }

    #[test]
    fn signing_in_again_replaces_the_expired_entry() {
        let mut r = registry(Some("b"), vec![account("a", true), account("b", false)]);
        let mut again = account("c", false);
        again.user_id = "@a:x".into();
        let replaced = r.add(again);
        assert_eq!(replaced.map(|a| a.id), Some("a".into()));
        assert_eq!(r.active.as_deref(), Some("c"));
        assert_eq!(r.accounts.len(), 2);
    }

    #[test]
    fn a_single_account_install_is_migrated() {
        let base = tempfile::tempdir().unwrap();
        let data_dir = base.path().join("persist_session");
        std::fs::create_dir_all(&data_dir).unwrap();
        let session = serde_json::json!({
            "client_session": {},
            "user_session": { "user_id": "@me:x", "device_id": "D" },
        });
        std::fs::write(data_dir.join(SESSION_FILE), session.to_string()).unwrap();
        std::fs::write(base.path().join("drafts.json"), "{}").unwrap();

        let r = migrate(&data_dir);
        let active = r.active().unwrap();
        assert_eq!(active.user_id, "@me:x");
        let dir = data_dir.join(ACCOUNTS_DIR).join(&active.id);
        assert!(dir.join(SESSION_FILE).exists());
        assert!(dir.join("drafts.json").exists());
        assert!(!data_dir.join(SESSION_FILE).exists());
        assert_eq!(load(&data_dir), Some(r));
    }
}
