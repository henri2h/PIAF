//! Media, files and links found in timeline items. Shared by the room's media
//! viewer and the room media gallery.

use matrix_sdk::ruma::events::room::{MediaSource, message::MessageType};
use matrix_sdk_ui::timeline::{TimelineItem, TimelineItemContent};

use crate::utils::queries::media_source_key;
use crate::utils::{extract_urls, format_date_key, format_timestamp};

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum FileKind {
    File,
    Video,
    Audio,
}

#[derive(Clone, Debug)]
pub enum MediaContent {
    Image {
        source: MediaSource,
        caption: Option<String>,
        blurhash: Option<String>,
        thumbnail_source: Option<MediaSource>,
    },
    File {
        kind: FileKind,
        source: MediaSource,
        name: String,
        size: Option<u64>,
    },
    Link {
        url: String,
    },
}

/// `MediaSource` has no `PartialEq`; compare sources by their cache key.
impl PartialEq for MediaContent {
    fn eq(&self, other: &Self) -> bool {
        let key = |s: &MediaSource| media_source_key(s);
        match (self, other) {
            (
                Self::Image {
                    source: a,
                    caption: ca,
                    blurhash: ba,
                    thumbnail_source: ta,
                },
                Self::Image {
                    source: b,
                    caption: cb,
                    blurhash: bb,
                    thumbnail_source: tb,
                },
            ) => {
                key(a) == key(b)
                    && ca == cb
                    && ba == bb
                    && ta.as_ref().map(key) == tb.as_ref().map(key)
            }
            (
                Self::File {
                    kind: ka,
                    source: a,
                    name: na,
                    size: sa,
                },
                Self::File {
                    kind: kb,
                    source: b,
                    name: nb,
                    size: sb,
                },
            ) => ka == kb && key(a) == key(b) && na == nb && sa == sb,
            (Self::Link { url: a }, Self::Link { url: b }) => a == b,
            _ => false,
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct MediaEntry {
    /// Unique per entry (a message can hold several links).
    pub key: String,
    pub event_id: Option<String>,
    pub sender_name: String,
    pub timestamp: String,
    pub date_key: String,
    pub content: MediaContent,
}

/// The gallery tab an entry belongs to.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum MediaKind {
    Image,
    File,
    Link,
}

impl MediaEntry {
    pub fn kind(&self) -> MediaKind {
        match self.content {
            MediaContent::Image { .. } => MediaKind::Image,
            MediaContent::File { .. } => MediaKind::File,
            MediaContent::Link { .. } => MediaKind::Link,
        }
    }
}

/// Entries shared without copying, compared by identity: entries never change
/// once extracted (an edited event yields new ones), so this is both cheap and exact.
#[derive(Clone, Debug, Default)]
pub struct SharedEntries(pub std::rc::Rc<Vec<std::sync::Arc<MediaEntry>>>);

impl PartialEq for SharedEntries {
    fn eq(&self, other: &Self) -> bool {
        std::rc::Rc::ptr_eq(&self.0, &other.0)
            || (self.0.len() == other.0.len()
                && self
                    .0
                    .iter()
                    .zip(other.0.iter())
                    .all(|(a, b)| std::sync::Arc::ptr_eq(a, b)))
    }
}

impl std::ops::Deref for SharedEntries {
    type Target = [std::sync::Arc<MediaEntry>];

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl FromIterator<std::sync::Arc<MediaEntry>> for SharedEntries {
    fn from_iter<I: IntoIterator<Item = std::sync::Arc<MediaEntry>>>(iter: I) -> Self {
        Self(std::rc::Rc::new(iter.into_iter().collect()))
    }
}

/// Entries in one timeline item: an image or file, or each link of a text message.
pub fn entries(item: &TimelineItem) -> Vec<MediaEntry> {
    let Some(event) = item.as_event() else {
        return vec![];
    };
    let TimelineItemContent::MsgLike(msg_like) = event.content() else {
        return vec![];
    };
    let Some(message) = msg_like.as_message() else {
        return vec![];
    };
    let event_id = event.event_id().map(|id| id.to_string());
    let key = event_id
        .clone()
        .unwrap_or_else(|| format!("local-{}", u64::from(event.timestamp().get())));
    let sender_name = crate::utils::room_preview::sender_name(event);
    let entry = |key: String, content| MediaEntry {
        key,
        event_id: event_id.clone(),
        sender_name: sender_name.clone(),
        timestamp: format_timestamp(event.timestamp()),
        date_key: format_date_key(event.timestamp()),
        content,
    };
    let file =
        |kind, source: &MediaSource, filename: Option<&str>, body: &str, size| MediaContent::File {
            kind,
            source: source.clone(),
            name: filename.unwrap_or(body).to_string(),
            size,
        };

    let content = match message.msgtype() {
        MessageType::Image(img) => MediaContent::Image {
            source: img.source.clone(),
            caption: caption(&img.body),
            blurhash: img.info.as_ref().and_then(|i| i.blurhash.clone()),
            thumbnail_source: img.info.as_ref().and_then(|i| i.thumbnail_source.clone()),
        },
        MessageType::File(f) => file(
            FileKind::File,
            &f.source,
            f.filename.as_deref(),
            &f.body,
            f.info.as_ref().and_then(|i| i.size).map(u64::from),
        ),
        MessageType::Video(v) => file(
            FileKind::Video,
            &v.source,
            v.filename.as_deref(),
            &v.body,
            v.info.as_ref().and_then(|i| i.size).map(u64::from),
        ),
        MessageType::Audio(a) => file(
            FileKind::Audio,
            &a.source,
            a.filename.as_deref(),
            &a.body,
            a.info.as_ref().and_then(|i| i.size).map(u64::from),
        ),
        MessageType::Text(t) => {
            return extract_urls(&t.body)
                .into_iter()
                .enumerate()
                .map(|(i, url)| entry(format!("{key}#{i}"), MediaContent::Link { url }))
                .collect();
        }
        _ => return vec![],
    };
    vec![entry(key, content)]
}

/// Image body, unless it's just a filename.
pub fn caption(body: &str) -> Option<String> {
    const FILE_EXTS: [&str; 5] = [".jpg", ".jpeg", ".png", ".gif", ".webp"];
    let is_filename = body.starts_with("image") || FILE_EXTS.iter().any(|e| body.ends_with(e));
    (!is_filename && !body.is_empty()).then(|| body.to_string())
}

#[cfg(test)]
mod tests {
    use super::caption;

    #[test]
    fn filenames_are_not_captions() {
        assert_eq!(caption("IMG_1.jpg"), None);
        assert_eq!(caption("image.png"), None);
        assert_eq!(caption(""), None);
    }

    #[test]
    fn text_is_a_caption() {
        assert_eq!(caption("Sunset"), Some("Sunset".to_string()));
    }
}
