//! Media, files and links found in timeline items. Shared by the room's media
//! viewer and the room media gallery.

use matrix_sdk::ruma::events::room::{
    MediaSource,
    message::{MessageFormat, MessageType},
};
use matrix_sdk_ui::timeline::{TimelineItem, TimelineItemContent};

use crate::utils::queries::media_source_key;
use crate::utils::{extract_urls, format_date_key, format_timestamp};

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum FileKind {
    File,
    Video,
    Audio,
}

impl FileKind {
    /// Name shown for a file that has none.
    pub fn label(self) -> &'static str {
        match self {
            Self::File => "File",
            Self::Video => "Video",
            Self::Audio => "Audio",
        }
    }
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
    let body = forward_split(message.msgtype()).1;
    let file =
        |kind, source: &MediaSource, filename: Option<&str>, body: &str, size| MediaContent::File {
            kind,
            source: source.clone(),
            name: media_name(body, filename, kind.label()),
            size,
        };

    let content = match message.msgtype() {
        MessageType::Image(img) => MediaContent::Image {
            source: img.source.clone(),
            caption: caption(body, img.filename.as_deref()),
            blurhash: img.info.as_ref().and_then(|i| i.blurhash.clone()),
            thumbnail_source: img.info.as_ref().and_then(|i| i.thumbnail_source.clone()),
        },
        MessageType::File(f) => file(
            FileKind::File,
            &f.source,
            f.filename.as_deref(),
            body,
            f.info.as_ref().and_then(|i| i.size).map(u64::from),
        ),
        MessageType::Video(v) => file(
            FileKind::Video,
            &v.source,
            v.filename.as_deref(),
            body,
            v.info.as_ref().and_then(|i| i.size).map(u64::from),
        ),
        MessageType::Audio(a) => file(
            FileKind::Audio,
            &a.source,
            a.filename.as_deref(),
            body,
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

/// The HTML body of a message, if any.
pub fn formatted_html(msgtype: &MessageType) -> Option<&str> {
    let formatted = match msgtype {
        MessageType::Text(m) => m.formatted.as_ref(),
        MessageType::Notice(m) => m.formatted.as_ref(),
        MessageType::Emote(m) => m.formatted.as_ref(),
        MessageType::Image(m) => m.formatted.as_ref(),
        MessageType::Video(m) => m.formatted.as_ref(),
        MessageType::Audio(m) => m.formatted.as_ref(),
        MessageType::File(m) => m.formatted.as_ref(),
        _ => None,
    }?;
    (formatted.format == MessageFormat::Html).then_some(formatted.body.as_str())
}

/// Text of the forward notice bridges (mautrix) put first in a forwarded
/// message's HTML: `<p data-mx-forwarded-notice>…</p>`.
fn forward_notice(html: &str) -> Option<String> {
    let rest = html.trim_start().strip_prefix("<p")?;
    let (attributes, rest) = rest.split_once('>')?;
    if !attributes.contains("data-mx-forwarded-notice") {
        return None;
    }
    let inner = rest.split_once("</p>").map_or(rest, |(inner, _)| inner);
    // Without its markup (`<em>`…).
    let mut text = String::new();
    let mut in_tag = false;
    for c in inner.chars() {
        match c {
            '<' => in_tag = true,
            '>' => in_tag = false,
            c if !in_tag => text.push(c),
            _ => {}
        }
    }
    Some(text.trim().to_string())
}

/// `(forwarded, body without the forward notice)` of a message: the notice
/// is found by its markup, whatever its wording, and dropped from the body
/// when the body repeats it.
pub fn forward_split(msgtype: &MessageType) -> (bool, &str) {
    let body = msgtype.body();
    match formatted_html(msgtype).and_then(forward_notice) {
        None => (false, body),
        Some(notice) => {
            let rest = body.trim_start();
            match rest.strip_prefix(notice.as_str()) {
                Some(rest) if !notice.is_empty() => (true, rest.trim_start()),
                _ => (true, body),
            }
        }
    }
}

/// A media message's caption: its `body` (without a forward notice, see
/// [`forward_split`]), unless that is only the file name.
pub fn caption(body: &str, filename: Option<&str>) -> Option<String> {
    let text = body.trim();
    let is_filename = match filename {
        Some(filename) => text == filename,
        None => text.starts_with("image") || looks_like_filename(text),
    };
    (!is_filename && !text.is_empty()).then(|| text.to_string())
}

/// `name.ext`: no spaces, a short alphanumeric extension.
fn looks_like_filename(text: &str) -> bool {
    !text.contains(char::is_whitespace)
        && text.rsplit_once('.').is_some_and(|(stem, ext)| {
            !stem.is_empty()
                && (1..=5).contains(&ext.len())
                && ext.chars().all(|c| c.is_ascii_alphanumeric())
        })
}

/// A media file's name: `filename`, else the body when it isn't a caption,
/// else `fallback` ("Video"…).
pub fn media_name(body: &str, filename: Option<&str>, fallback: &str) -> String {
    let text = body.trim();
    match filename {
        Some(name) if !name.trim().is_empty() => name.to_string(),
        _ if !text.is_empty() && !text.contains('\n') => text.to_string(),
        _ => fallback.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use matrix_sdk::ruma::events::room::message::MessageType;

    use super::{caption, forward_split, media_name};

    #[test]
    fn filenames_are_not_captions() {
        assert_eq!(caption("IMG_1.jpg", None), None);
        assert_eq!(caption("image.png", None), None);
        assert_eq!(caption("", None), None);
        assert_eq!(caption("clip.mp4", Some("clip.mp4")), None);
        assert_eq!(caption("fig49_2026_06_03__21_46_22.mp4", None), None);
        assert_eq!(
            caption("See you at 5.30 ok", None),
            Some("See you at 5.30 ok".into())
        );
    }

    fn image(body: &str, html: Option<&str>) -> MessageType {
        use matrix_sdk::ruma::events::room::message::{FormattedBody, ImageMessageEventContent};
        let mut content = ImageMessageEventContent::plain(body.to_string(), "mxc://x/y".into());
        content.formatted = html.map(FormattedBody::html);
        MessageType::Image(content)
    }

    #[test]
    fn forward_notice_found_by_markup() {
        let html = "<p data-mx-forwarded-notice><em>↷ Transféré</em></p><p>Look</p>";
        assert_eq!(
            forward_split(&image("↷ Transféré\n\nLook", Some(html))),
            (true, "Look")
        );
        // Wording that differs from the body: forwarded, body kept.
        assert_eq!(forward_split(&image("Look", Some(html))), (true, "Look"));
        // The same text without the markup is just text.
        assert_eq!(
            forward_split(&image("↷ Transféré\n\nLook", None)),
            (false, "↷ Transféré\n\nLook")
        );
    }

    #[test]
    fn media_names() {
        assert_eq!(media_name("", None, "Video"), "Video");
        assert_eq!(media_name("Look", Some("a.mp4"), "Video"), "a.mp4");
        assert_eq!(media_name("song.mp3", None, "Audio"), "song.mp3");
    }

    #[test]
    fn text_is_a_caption() {
        assert_eq!(caption("Sunset", None), Some("Sunset".to_string()));
    }
}
