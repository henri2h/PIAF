use std::sync::{Arc, OnceLock};

use freya_query::prelude::QueryCapability;
use matrix_sdk::ruma::events::room::MediaSource;

use crate::utils::matrix::CLIENT;
use crate::utils::on_tokio;

/// Serialize a `MediaSource` to a stable string key usable with `FetchMediaContent`.
pub fn media_source_key(source: &MediaSource) -> String {
    matrix_sdk::ruma::exports::serde_json::to_string(source).unwrap_or_default()
}

// At most 4 media downloads run concurrently. Others yield on the main thread
// (via spawn_local / spawn_in_window) until a permit is free, then spawn a tokio
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

async fn fetch_sender_name_direct(key: &str) -> Result<String, ()> {
    let mut parts = key.splitn(2, '\x00');
    let room_id = parts.next().unwrap_or("").to_owned();
    let user_id = parts.next().unwrap_or("").to_owned();
    let parsed_user = matrix_sdk::ruma::UserId::parse(&user_id).map_err(|_| ())?;
    let room = crate::utils::matrix::get_room(&room_id).ok_or(())?;
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
        let key = key.clone();
        on_tokio(async move { fetch_sender_name_direct(&key).await })
            .await
            .ok_or(())?
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
        let rx = on_tokio::<Result<Vec<u8>, ()>, _>(async move {
            // Acquire the permit inside the tokio task (safe: real tokio context).
            let permit = match media_semaphore().acquire_owned().await {
                Ok(p) => p,
                Err(_) => {
                    return Err(());
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
            result
        });

        rx.await.ok_or(())?
    }
}

/// Key format: `"WxH:{json_media_source}"` — encodes requested size + source.
pub fn media_thumbnail_key(source: &MediaSource, width: u32, height: u32) -> String {
    format!("{}x{}:{}", width, height, media_source_key(source))
}

/// Fetch a server-side scaled thumbnail for a Matrix media item.
/// Uses `MediaFormat::Thumbnail` so the server returns a small image.
#[derive(Clone, PartialEq, Hash, Eq)]
pub struct FetchMediaThumbnail;

impl QueryCapability for FetchMediaThumbnail {
    type Ok = Vec<u8>;
    type Err = ();
    type Keys = String; // output of `media_thumbnail_key()`

    async fn run(&self, key: &String) -> Result<Vec<u8>, ()> {
        use matrix_sdk::media::{MediaFormat, MediaRequestParameters, MediaThumbnailSettings};
        use matrix_sdk::ruma::UInt;

        // Parse "WxH:{json_source}"
        let (dims, json) = key.split_once(':').ok_or(())?;
        let (w_str, h_str) = dims.split_once('x').ok_or(())?;
        let width: u32 = w_str.parse().map_err(|_| ())?;
        let height: u32 = h_str.parse().map_err(|_| ())?;

        let source: MediaSource =
            matrix_sdk::ruma::exports::serde_json::from_str(json).map_err(|_| ())?;
        let client = CLIENT.get().cloned().ok_or(())?;

        let rx = on_tokio::<Result<Vec<u8>, ()>, _>(async move {
            let permit = match media_semaphore().acquire_owned().await {
                Ok(p) => p,
                Err(_) => {
                    return Err(());
                }
            };
            let _permit = permit;
            let settings = MediaThumbnailSettings::new(
                UInt::new(width as u64).unwrap_or(UInt::MAX),
                UInt::new(height as u64).unwrap_or(UInt::MAX),
            );
            let request = MediaRequestParameters {
                source,
                format: MediaFormat::Thumbnail(settings),
            };
            let result = client
                .media()
                .get_media_content(&request, true)
                .await
                .map(|b| b.to_vec())
                .map_err(|_| ());
            result
        });

        rx.await.ok_or(())?
    }
}

#[derive(Clone, PartialEq, Hash, Eq)]
pub struct FetchUserDisplayName;

impl QueryCapability for FetchUserDisplayName {
    type Ok = String;
    type Err = ();
    type Keys = ();

    async fn run(&self, _: &()) -> Result<String, ()> {
        let client = CLIENT.get().cloned().ok_or(())?;
        let rx = on_tokio::<Result<String, ()>, _>(async move {
            let name = client
                .account()
                .get_display_name()
                .await
                .ok()
                .flatten()
                .or_else(|| client.user_id().map(|id| id.to_string()))
                .unwrap_or_default();
            Ok(name)
        });
        rx.await.ok_or(())?
    }
}

/// Fetches rooms shared with a given user ID.
/// Uses MSC2666 first, falls back to iterating locally cached rooms.
#[derive(Clone, PartialEq, Hash, Eq)]
pub struct FetchMutualRooms;

impl QueryCapability for FetchMutualRooms {
    type Ok = Vec<String>;
    type Err = ();
    type Keys = String; // user_id

    async fn run(&self, user_id: &String) -> Result<Vec<String>, ()> {
        use ruma::api::client::membership::mutual_rooms::unstable::Request as MutualRoomsRequest;

        let client = CLIENT.get().cloned().ok_or(())?;
        let parsed = ruma::UserId::parse(user_id.as_str()).map_err(|_| ())?;

        let rx = on_tokio::<Result<Vec<String>, ()>, _>(async move {
            // Try MSC2666 via the native ruma request.
            if let Ok(resp) = client
                .send(MutualRoomsRequest::new(parsed.to_owned()))
                .await
            {
                return Ok(resp.joined.into_iter().map(|r| r.to_string()).collect());
            }

            // Fallback: iterate locally cached joined rooms.
            let mut result = vec![];
            for room in client.rooms() {
                if let Ok(Some(_)) = room.get_member_no_sync(&parsed).await {
                    result.push(room.room_id().to_string());
                }
            }
            Ok(result)
        });
        rx.await.unwrap_or(Err(()))
    }
}

/// Members with a picture standing in for a room's avatar
/// ([`crate::utils::avatars::members_with_avatar`], at most 2). Key: room id.
#[derive(Clone, PartialEq, Hash, Eq)]
pub struct FetchAvatarMembers;

impl QueryCapability for FetchAvatarMembers {
    type Ok = Vec<crate::utils::avatars::MemberWithAvatar>;
    type Err = ();
    type Keys = String;

    async fn run(&self, room_id: &String) -> Result<Self::Ok, ()> {
        let room_id = room_id.clone();
        on_tokio(async move {
            let room = crate::utils::matrix::get_room(&room_id).ok_or(())?;
            Ok(crate::utils::avatars::members_with_avatar(&room, 2).await)
        })
        .await
        .ok_or(())?
    }
}
