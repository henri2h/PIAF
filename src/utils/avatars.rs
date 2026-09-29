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
