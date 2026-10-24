use freya::prelude::*;
use matrix_sdk::ruma::events::room::message::MessageType;
use matrix_sdk_ui::timeline::{
    InReplyToDetails, MsgLikeKind, TimelineDetails, TimelineItemContent,
};

use super::PressGuard;
use crate::ui::components::{Avatar, HoverableExt, MediaThumbnail, ViewerSource};
use crate::ui::pages::room::focus::focus_event;
use crate::utils::avatars::AvatarSource;
use crate::utils::const_values::AppColors;
use crate::utils::matrix::my_user_id;
use crate::utils::media::format_media_duration;
use crate::utils::room_preview::reply_preview;
use crate::utils::timeline_media::{forward_split, media_name};
use crate::utils::{id_color, mentions};

const THUMB: f32 = 20.;
const AVATAR: f32 = 16.;
/// The connector's size, and how far in from the bubble's edge it starts.
const CONNECTOR_W: f32 = 18.;
/// Tall enough to reach from the line's middle down to the bubble.
const CONNECTOR_H: f32 = 12.;
const CONNECTOR_TOP: f32 = 8.;
const INDENT: f32 = 14.;

/// Who wrote the quoted message.
struct QuotedSender {
    user_id: String,
    name: String,
}

/// What the quote shows of the quoted message.
enum QuotedBody {
    Text(String),
    /// An icon and a label ("Photo", "Video · 0:55", a file name), with a
    /// thumbnail for pictures and videos.
    Media {
        icon: Bytes,
        label: String,
        thumbnail: Option<ViewerSource>,
    },
}

/// The quoted message of a reply, as shown above it.
pub(super) struct Quote {
    event_id: String,
    /// `None` until the quoted event is known.
    sender: Option<QuotedSender>,
    body: QuotedBody,
}

impl Quote {
    pub fn new(reply: &InReplyToDetails) -> Self {
        let text = |s: &str| QuotedBody::Text(s.to_string());
        let (sender, body) = match &reply.event {
            TimelineDetails::Ready(event) => {
                let user_id = event.sender.to_string();
                let name = if my_user_id().as_deref() == Some(user_id.as_str()) {
                    "You".to_string()
                } else {
                    match &event.sender_profile {
                        TimelineDetails::Ready(p) => p.display_name.clone(),
                        _ => None,
                    }
                    .unwrap_or_else(|| event.sender.localpart().to_string())
                };
                let body = match &event.content {
                    TimelineItemContent::MsgLike(m) => match &m.kind {
                        MsgLikeKind::Message(msg) => quoted_message(msg.msgtype()),
                        MsgLikeKind::Redacted => text("Message deleted"),
                        MsgLikeKind::UnableToDecrypt(_) => text("Encrypted message"),
                        MsgLikeKind::Sticker(_) => text("Sticker"),
                        MsgLikeKind::Poll(_) => text("Poll"),
                        _ => text("Message"),
                    },
                    _ => text("Message"),
                };
                (Some(QuotedSender { user_id, name }), body)
            }
            TimelineDetails::Error(_) => (None, text("Original message unavailable")),
            _ => (None, text("Loading…")),
        };
        Self {
            event_id: reply.event_id.to_string(),
            sender,
            body,
        }
    }

    /// One line above the bubble, joined to it by a curved connector: the
    /// quoted sender (avatar, name in their colour) and an excerpt; a tap
    /// scrolls to the quoted message. Mirrored for our messages (`is_me`).
    pub fn render(self, room_id: &str, is_me: bool, guard: PressGuard, c: AppColors) -> Element {
        let muted = c.on_surface_muted;
        let accent = self
            .sender
            .as_ref()
            .map_or(muted, |sender| id_color(&sender.user_id));
        let (excerpt_icon, excerpt, thumbnail) = match self.body {
            QuotedBody::Text(text) => (None, text.replace('\n', " "), None),
            QuotedBody::Media {
                icon,
                label: media_label,
                thumbnail,
            } => (Some(icon), media_label, thumbnail),
        };
        let sender = self.sender.map(|sender| {
            rect()
                .horizontal()
                .cross_align(Alignment::Center)
                .spacing(4.)
                .child(Avatar {
                    size: AVATAR,
                    source: Some(AvatarSource::member(room_id, &sender.user_id)),
                    name: sender.name.clone(),
                    color: id_color(&sender.user_id),
                })
                .child(
                    label()
                        .text(sender.name)
                        .max_lines(1)
                        .font_size(12.)
                        .font_weight(FontWeight::BOLD)
                        .color(accent),
                )
        });
        let quote = rect()
            .horizontal()
            .width(Size::flex(1.))
            .content(Content::Flex)
            .cross_align(Alignment::Center)
            .spacing(6.)
            .maybe_child(sender)
            .maybe_child(excerpt_icon.map(|icon| {
                SvgViewer::new(icon)
                    .color(muted)
                    .width(Size::px(12.))
                    .height(Size::px(12.))
            }))
            .child(
                label()
                    .width(Size::flex(1.))
                    .text(excerpt)
                    .max_lines(1)
                    .text_overflow(TextOverflow::Ellipsis)
                    .font_size(12.)
                    .color(muted),
            )
            .maybe_child(thumbnail.map(|source| {
                rect()
                    .width(Size::px(THUMB))
                    .height(Size::px(THUMB))
                    .corner_radius(4.)
                    .overflow(Overflow::Clip)
                    .child(MediaThumbnail {
                        item_key: format!("quote-{}", self.event_id),
                        blurhash: None,
                        thumbnail_source: None,
                        fallback_source: Some(source),
                        thumb_size: Some((64, 64)),
                    })
            }));
        // The curve: from the bubble's top edge up and across to the line.
        let side = BorderWidth {
            top: 2.,
            right: if is_me { 2. } else { 0. },
            bottom: 0.,
            left: if is_me { 0. } else { 2. },
        };
        let connector = rect()
            .width(Size::px(CONNECTOR_W))
            .height(Size::px(CONNECTOR_H))
            .margin(Gaps::new(CONNECTOR_TOP, 0., 0., 0.))
            .corner_radius(if is_me {
                CornerRadius::new(0., 8., 0., 0.)
            } else {
                CornerRadius::new(8., 0., 0., 0.)
            })
            .border(Border::new().fill(c.outline_variant).width(side));
        let room_id = room_id.to_string();
        let event_id = self.event_id;
        let row = rect()
            .horizontal()
            // The hover wrapper below is the one sized like a bubble.
            .width(Size::fill())
            .content(Content::Flex)
            .cross_align(Alignment::Start)
            .spacing(4.)
            .padding(Gaps::new(0., INDENT, 0., INDENT));
        let row = if is_me {
            row.child(quote).child(connector)
        } else {
            row.child(connector).child(quote)
        };
        row.on_press(move |e: Event<PressEventData>| {
            e.stop_propagation();
            if guard.allows() {
                focus_event(&room_id, &event_id);
            }
        })
        .hoverable(Size::percent(82.), Size::auto(), 6.)
    }
}

/// The quote of a message: its text, or a media label with a thumbnail.
fn quoted_message(msgtype: &MessageType) -> QuotedBody {
    let body = forward_split(msgtype).1;
    let with_duration = |name: &str, duration: Option<std::time::Duration>| match duration {
        Some(d) => format!("{name} · {}", format_media_duration(d)),
        None => name.to_string(),
    };
    match msgtype {
        MessageType::Image(img) => QuotedBody::Media {
            icon: freya_icons::lucide::image(),
            label: crate::utils::timeline_media::caption(body, img.filename.as_deref())
                .unwrap_or_else(|| "Photo".to_string()),
            thumbnail: Some(ViewerSource::Remote(
                img.info
                    .as_ref()
                    .and_then(|i| i.thumbnail_source.clone())
                    .unwrap_or_else(|| img.source.clone()),
            )),
        },
        MessageType::Video(v) => QuotedBody::Media {
            icon: freya_icons::lucide::video(),
            label: with_duration("Video", v.info.as_ref().and_then(|i| i.duration)),
            thumbnail: v
                .info
                .as_ref()
                .and_then(|i| i.thumbnail_source.clone())
                .map(ViewerSource::Remote),
        },
        MessageType::Audio(a) => QuotedBody::Media {
            icon: freya_icons::lucide::music(),
            label: with_duration("Audio", a.info.as_ref().and_then(|i| i.duration)),
            thumbnail: None,
        },
        MessageType::File(f) => QuotedBody::Media {
            icon: freya_icons::lucide::file(),
            label: media_name(body, f.filename.as_deref(), "File"),
            thumbnail: None,
        },
        MessageType::Location(_) => QuotedBody::Media {
            icon: freya_icons::lucide::map_pin(),
            label: "Location".to_string(),
            thumbnail: None,
        },
        // Text: mentions by name, not ID.
        _ => QuotedBody::Text(plain_mentions(&reply_preview(msgtype))),
    }
}

/// `@user:server` written as `@user` (the quote is plain text).
fn plain_mentions(text: &str) -> String {
    mentions::segments(text, &[])
        .into_iter()
        .map(|segment| match segment {
            mentions::Segment::Text(text) => text,
            mentions::Segment::User(id) => {
                format!(
                    "@{}",
                    id.trim_start_matches('@').split(':').next().unwrap_or(&id)
                )
            }
            mentions::Segment::Room => "@room".to_string(),
        })
        .collect()
}
