//! Avatar fetching. Always asks for a server-side thumbnail: the original
//! upload is often a multi-megapixel photo that decodes to tens of MB of
//! pixels just to draw a small circle (measured: ~1.4 GB of decoded images).

use matrix_sdk::media::{MediaFormat, MediaRequestParameters, MediaThumbnailSettings};
use matrix_sdk::ruma::events::room::MediaSource;
use matrix_sdk::ruma::{OwnedMxcUri, UInt};
use matrix_sdk::{Client, Room};

/// Thumbnail edge in pixels: sharp up to 160px avatars at 2x, and one of the
/// sizes Synapse pre-generates.
const AVATAR_THUMBNAIL_PX: u32 = 320;

fn thumbnail() -> MediaFormat {
    let px = UInt::from(AVATAR_THUMBNAIL_PX);
    MediaFormat::Thumbnail(MediaThumbnailSettings::new(px, px))
}

/// Thumbnail of an avatar, or the original if the server can't thumbnail it.
pub async fn by_mxc(client: &Client, mxc: OwnedMxcUri) -> Option<Vec<u8>> {
    let media = client.media();
    for format in [thumbnail(), MediaFormat::File] {
        let request = MediaRequestParameters {
            source: MediaSource::Plain(mxc.clone()),
            format,
        };
        if let Ok(bytes) = media.get_media_content(&request, true).await {
            return Some(bytes);
        }
    }
    None
}

/// The room's own avatar (`m.room.avatar`), thumbnailed.
pub async fn of_room(room: &Room) -> Option<Vec<u8>> {
    match room.avatar(thumbnail()).await {
        Ok(Some(bytes)) => Some(bytes),
        _ => room.avatar(MediaFormat::File).await.ok().flatten(),
    }
}

/// The logged-in user's avatar, thumbnailed.
pub async fn own(client: &Client) -> Option<Vec<u8>> {
    let account = client.account();
    match account.get_avatar(thumbnail()).await {
        Ok(Some(bytes)) => Some(bytes),
        _ => account.get_avatar(MediaFormat::File).await.ok().flatten(),
    }
}

/// What an avatar shows. Each source has one fetch path and one cache entry,
/// so the same person or room looks the same everywhere.
#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub enum AvatarSource {
    /// A room: a DM shows the other user, then the room's own avatar, then a
    /// hero's.
    Room(String),
    /// A user as a member of a room: their room avatar, else their global one.
    Member { room_id: String, user_id: String },
    /// A user's global profile avatar.
    User(String),
    /// A known media URI (search results, room heroes).
    Mxc(String),
    /// The logged-in user.
    Me,
    /// Bytes already in hand (e.g. a just-uploaded avatar).
    Bytes(bytes::Bytes),
}

impl AvatarSource {
    pub fn member(room_id: impl Into<String>, user_id: impl Into<String>) -> Self {
        Self::Member {
            room_id: room_id.into(),
            user_id: user_id.into(),
        }
    }

    /// Asset cache key.
    pub fn cache_key(&self) -> String {
        match self {
            Self::Room(id) => format!("avatar:room:{id}"),
            Self::Member { room_id, user_id } => format!("avatar:member:{room_id}:{user_id}"),
            Self::User(id) => format!("avatar:user:{id}"),
            Self::Mxc(uri) => format!("avatar:mxc:{uri}"),
            Self::Me => "avatar:me".to_string(),
            Self::Bytes(bytes) => {
                use std::hash::{Hash, Hasher};
                let mut hasher = std::collections::hash_map::DefaultHasher::new();
                bytes.hash(&mut hasher);
                format!("avatar:bytes:{:x}", hasher.finish())
            }
        }
    }
}

/// The image for `source`, thumbnailed. `None` when there is none or it
/// failed to load (logged under `piaf::avatar`).
pub async fn fetch(source: &AvatarSource) -> Option<Vec<u8>> {
    let client = crate::utils::matrix::CLIENT.get().cloned()?;
    let bytes = match source {
        AvatarSource::Room(room_id) => room_avatar(&client, room_id).await,
        AvatarSource::Member { room_id, user_id } => member_avatar(&client, room_id, user_id).await,
        AvatarSource::User(user_id) => user_avatar(&client, user_id).await,
        AvatarSource::Mxc(uri) => by_mxc(&client, OwnedMxcUri::from(uri.as_str())).await,
        AvatarSource::Me => own(&client).await,
        AvatarSource::Bytes(bytes) => Some(bytes.to_vec()),
    };
    if bytes.is_none() {
        tracing::debug!(target: "piaf::avatar", ?source, "no avatar");
    }
    bytes
}

/// See [`AvatarSource::Room`].
async fn room_avatar(client: &Client, room_id: &str) -> Option<Vec<u8>> {
    use matrix_sdk::ruma::events::direct::DirectEventContent;

    let room = crate::utils::matrix::get_room(room_id)?;
    // A DM shows the other user. `m.direct` is authoritative even for bridged
    // DMs, where the room may have a third member (the bridge bot).
    let direct = client
        .account()
        .account_data::<DirectEventContent>()
        .await
        .ok()
        .flatten()
        .and_then(|raw| raw.deserialize().ok());
    let dm_user = direct.and_then(|direct| {
        direct
            .0
            .into_iter()
            .find(|(_, rooms)| rooms.iter().any(|r| r.as_str() == room_id))
            .map(|(user, _)| user.to_string())
    });
    if let Some(user_id) = dm_user
        && let Some(bytes) = member_avatar(client, room_id, &user_id).await
    {
        return Some(bytes);
    }
    if let Some(bytes) = of_room(&room).await {
        return Some(bytes);
    }
    for hero in room.heroes() {
        if let Some(uri) = hero.avatar_url
            && let Some(bytes) = by_mxc(client, uri).await
        {
            return Some(bytes);
        }
    }
    None
}

/// See [`AvatarSource::Member`]. Members are lazy-loaded with sliding sync,
/// so users who never sent a message (e.g. only in read receipts) are often
/// not in the store: those fall back to their global profile.
async fn member_avatar(client: &Client, room_id: &str, user_id: &str) -> Option<Vec<u8>> {
    let user = matrix_sdk::ruma::UserId::parse(user_id).ok()?;
    let member_uri = match crate::utils::matrix::get_room(room_id) {
        Some(room) => room
            .get_member_no_sync(&user)
            .await
            .ok()
            .flatten()
            .and_then(|m| m.avatar_url().map(|u| u.to_owned())),
        None => None,
    };
    match member_uri {
        Some(uri) => by_mxc(client, uri).await,
        None => user_avatar(client, user_id).await,
    }
}

/// See [`AvatarSource::User`].
async fn user_avatar(client: &Client, user_id: &str) -> Option<Vec<u8>> {
    let user = matrix_sdk::ruma::UserId::parse(user_id).ok()?;
    let profile = client.account().fetch_user_profile_of(&user).await.ok()?;
    let uri = profile.get("avatar_url")?.as_str()?;
    by_mxc(client, OwnedMxcUri::from(uri)).await
}
