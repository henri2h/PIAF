use std::sync::{Arc, OnceLock};

use freya_query::prelude::QueryCapability;
use matrix_sdk::ruma::events::room::MediaSource;

use crate::REQUESTER;
use crate::utils::matrix::CLIENT;

/// Serialize a `MediaSource` to a stable string key usable with `FetchMediaContent`.
pub fn media_source_key(source: &MediaSource) -> String {
    matrix_sdk::ruma::exports::serde_json::to_string(source).unwrap_or_default()
}

// At most 4 media downloads run concurrently. Others yield on the main thread
// (via spawn_local / spawn_forever) until a permit is free, then spawn a tokio
// worker task so the actual I/O never blocks the main thread.
static MEDIA_FETCH_SEM: OnceLock<Arc<tokio::sync::Semaphore>> = OnceLock::new();

fn media_semaphore() -> Arc<tokio::sync::Semaphore> {
    MEDIA_FETCH_SEM
        .get_or_init(|| Arc::new(tokio::sync::Semaphore::new(4)))
        .clone()
}

// ---------------------------------------------------------------------------
// Helpers — run directly as parallel tokio tasks, bypassing the sequential
// worker, so many rooms can load their avatars/names concurrently.
// ---------------------------------------------------------------------------

async fn fetch_room_avatar_direct(room_id: &str) -> Result<Vec<u8>, ()> {
    use matrix_sdk::media::{MediaFormat, MediaRequestParameters};
    use matrix_sdk::ruma::events::direct::DirectEventContent;
    use matrix_sdk::ruma::events::room::MediaSource;

    let client = CLIENT.get().cloned().ok_or(())?;
    let parsed_id = matrix_sdk::ruma::RoomId::parse(room_id).map_err(|_| ())?;
    let room = client.get_room(&parsed_id).ok_or(())?;

    // For DM rooms, look up the user this room belongs to in the m.direct
    // account data (user_id → [room_ids] map) and use that user's avatar.
    // This is authoritative even for bridged DMs where the room may have
    // three members (self, other user, bridge bot).
    if let Ok(Some(raw)) = client.account().account_data::<DirectEventContent>().await {
        if let Ok(direct) = raw.deserialize() {
            let dm_user = direct.0.into_iter().find_map(|(user, rooms)| {
                if rooms.iter().any(|r| r == &parsed_id) {
                    Some(user)
                } else {
                    None
                }
            });

            if let Some(dm_user_id) = dm_user {
                // Resolve the DirectUserIdentifier to a plain UserId string.
                // DirectUserIdentifier is either a UserId or a ThirdPartyIdentifier;
                // only the UserId case gives us a Matrix user to look up.
                let user_id_str = dm_user_id.to_string();
                if let Ok(parsed_user) = matrix_sdk::ruma::UserId::parse(&user_id_str) {
                    if let Ok(Some(member)) = room.get_member_no_sync(&parsed_user).await {
                        if let Some(avatar_url) = member.avatar_url() {
                            let request = MediaRequestParameters {
                                source: MediaSource::Plain(avatar_url.to_owned()),
                                format: MediaFormat::File,
                            };
                            if let Ok(bytes) =
                                client.media().get_media_content(&request, true).await
                            {
                                return Ok(bytes.to_vec());
                            }
                        }
                    }
                }
            }
        }
    }

    // Try the room's own set avatar.
    if let Ok(Some(bytes)) = room.avatar(MediaFormat::File).await {
        return Ok(bytes);
    }

    // Fall back to the first hero member that has a non-null avatar_url.
    for hero in room.heroes() {
        let Some(mxc_uri) = hero.avatar_url else {
            continue;
        };
        let request = MediaRequestParameters {
            source: MediaSource::Plain(mxc_uri),
            format: MediaFormat::File,
        };
        if let Ok(bytes) = client.media().get_media_content(&request, true).await {
            return Ok(bytes.to_vec());
        }
    }

    Err(())
}

async fn fetch_sender_name_direct(key: &str) -> Result<String, ()> {
    let mut parts = key.splitn(2, '\x00');
    let room_id = parts.next().unwrap_or("").to_owned();
    let user_id = parts.next().unwrap_or("").to_owned();
    let client = CLIENT.get().cloned().ok_or(())?;
    let parsed_room = matrix_sdk::ruma::RoomId::parse(&room_id).map_err(|_| ())?;
    let parsed_user = matrix_sdk::ruma::UserId::parse(&user_id).map_err(|_| ())?;
    let room = client.get_room(&parsed_room).ok_or(())?;
    let name = room
        .get_member_no_sync(&parsed_user)
        .await
        .ok()
        .flatten()
        .and_then(|m| m.display_name().map(|s| s.to_string()))
        .unwrap_or_else(|| {
            user_id
                .trim_start_matches('@')
                .split(':')
                .next()
                .unwrap_or(&user_id)
                .to_string()
        });
    Ok(name)
}

// ---------------------------------------------------------------------------
// Queries
// ---------------------------------------------------------------------------

#[derive(Clone, PartialEq, Hash, Eq)]
pub struct FetchRoomAvatar;

impl QueryCapability for FetchRoomAvatar {
    type Ok = Vec<u8>;
    type Err = ();
    type Keys = String;

    async fn run(&self, room_id: &String) -> Result<Vec<u8>, ()> {
        // Spawn a real tokio task so many rooms can load concurrently without
        // going through the sequential worker.
        let (tx, rx) = futures::channel::oneshot::channel::<Result<Vec<u8>, ()>>();
        let room_id = room_id.clone();
        tokio::spawn(async move {
            let _ = tx.send(fetch_room_avatar_direct(&room_id).await);
        });
        rx.await.map_err(|_| ())?
    }
}

#[derive(Clone, PartialEq, Hash, Eq)]
pub struct FetchUserAvatar;

impl QueryCapability for FetchUserAvatar {
    type Ok = Vec<u8>;
    type Err = ();
    type Keys = ();

    async fn run(&self, _: &()) -> Result<Vec<u8>, ()> {
        REQUESTER.get().ok_or(())?.fetch_user_avatar().await
    }
}

/// Fetch the display name of a specific member in a room.
/// Key: `"room_id\x00user_id"` (null-byte separator)
#[derive(Clone, PartialEq, Hash, Eq)]
pub struct FetchSenderName;

impl QueryCapability for FetchSenderName {
    type Ok = String;
    type Err = ();
    type Keys = String; // "room_id\x00user_id"

    async fn run(&self, key: &String) -> Result<String, ()> {
        // Same approach: parallel tokio task per lookup.
        let (tx, rx) = futures::channel::oneshot::channel::<Result<String, ()>>();
        let key = key.clone();
        tokio::spawn(async move {
            let _ = tx.send(fetch_sender_name_direct(&key).await);
        });
        rx.await.map_err(|_| ())?
    }
}

/// Fetch raw bytes for a Matrix media item.
/// Key: JSON-serialised `MediaSource` — contains all info needed to decrypt
/// encrypted attachments, and doubles as a stable cache key.
#[derive(Clone, PartialEq, Hash, Eq)]
pub struct FetchMediaContent;

impl QueryCapability for FetchMediaContent {
    type Ok = Vec<u8>;
    type Err = ();
    type Keys = String; // output of `media_source_key()`

    async fn run(&self, key: &String) -> Result<Vec<u8>, ()> {
        use matrix_sdk::media::{MediaFormat, MediaRequestParameters};

        let source: MediaSource =
            matrix_sdk::ruma::exports::serde_json::from_str(key).map_err(|_| ())?;
        let client = CLIENT.get().cloned().ok_or(())?;

        // Spawn a real tokio task so the semaphore acquire and the download
        // both happen in a tokio context — never on the freya/smol main thread.
        // The freya task only awaits a futures::oneshot, which is smol-safe.
        let (tx, rx) = futures::channel::oneshot::channel::<Result<Vec<u8>, ()>>();
        tokio::spawn(async move {
            // Acquire the permit inside the tokio task (safe: real tokio context).
            let permit = match media_semaphore().acquire_owned().await {
                Ok(p) => p,
                Err(_) => {
                    let _ = tx.send(Err(()));
                    return;
                }
            };
            let _permit = permit; // released when this task finishes
            let request = MediaRequestParameters {
                source,
                format: MediaFormat::File,
            };
            let result = client
                .media()
                .get_media_content(&request, true)
                .await
                .map(|b| b.to_vec())
                .map_err(|_| ());
            let _ = tx.send(result);
        });

        rx.await.map_err(|_| ())?
    }
}

#[derive(Clone, PartialEq, Hash, Eq)]
pub struct FetchUserDisplayName;

impl QueryCapability for FetchUserDisplayName {
    type Ok = String;
    type Err = ();
    type Keys = ();

    async fn run(&self, _: &()) -> Result<String, ()> {
        REQUESTER.get().ok_or(())?.fetch_user_display_name().await
    }
}
