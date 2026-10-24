use freya::prelude::*;
use matrix_sdk::ruma::events::room::{MediaSource, message::MessageType};
use matrix_sdk_ui::timeline::Message;

use crate::ui::components::{HoverableExt, MediaThumbnail, ViewerSource};
use crate::utils::const_values::AppColors;
use crate::utils::media::{self, format_file_size, format_media_duration};
use crate::utils::timeline_media::{caption, formatted_html, forward_split, media_name};

use super::PressGuard;
use super::body::text_body;

const MEDIA_W: f32 = 240.;
const MEDIA_H: f32 = 180.;
/// Height range of an image in the timeline (very tall or wide ones are cropped).
const MEDIA_MIN_H: f32 = 120.;
const MEDIA_MAX_H: f32 = 320.;

/// Frame of an image in the timeline: full width, height from its aspect
/// ratio (when known), within [`MEDIA_MIN_H`]..[`MEDIA_MAX_H`].
pub(super) fn media_size(width: Option<u64>, height: Option<u64>) -> (f32, f32) {
    match (width, height) {
        (Some(w), Some(h)) if w > 0 && h > 0 => (
            MEDIA_W,
            (MEDIA_W * h as f32 / w as f32).clamp(MEDIA_MIN_H, MEDIA_MAX_H),
        ),
        _ => (MEDIA_W, MEDIA_H),
    }
}

/// What a message bubble shows.
pub(super) struct ContentCtx<'a> {
    pub room_id: &'a str,
    pub event_id: Option<String>,
    pub sender_name: &'a str,
    pub is_me: bool,
    pub image_viewer: State<Option<String>>,
    pub guard: PressGuard,
}

/// Body of a message bubble; `None` for message types not shown.
pub(super) fn message_content(message: &Message, cx: ContentCtx, c: AppColors) -> Option<Element> {
    let ContentCtx {
        room_id,
        event_id,
        sender_name,
        is_me,
        mut image_viewer,
        guard,
    } = cx;
    let text_color = if is_me {
        c.bubble_me_text
    } else {
        c.bubble_other_text
    };
    let key = event_id.unwrap_or_else(|| "media-unknown".to_string());
    let msgtype = message.msgtype();
    // Without a bridge's forward notice: the row marks it.
    let body = forward_split(msgtype).1;
    let html = formatted_html(msgtype);
    Some(match msgtype {
        MessageType::Text(_) => text_body(room_id, body, html, text_color),
        // Bots' messages: same text, a step quieter.
        MessageType::Notice(_) => text_body(
            room_id,
            body,
            html,
            if is_me {
                text_color
            } else {
                c.on_surface_variant
            },
        ),
        // "/me waves": the sender's name, then the action.
        MessageType::Emote(_) => text_body(
            room_id,
            &format!("* {sender_name} {body}"),
            None,
            text_color,
        ),
        MessageType::Image(img) => {
            let open_key = key.clone();
            let (w, h) = media_size(
                img.info.as_ref().and_then(|i| i.width).map(u64::from),
                img.info.as_ref().and_then(|i| i.height).map(u64::from),
            );
            rect()
                .vertical()
                .spacing(6.)
                .child(
                    media_frame(
                        w,
                        h,
                        MediaThumbnail {
                            item_key: key,
                            blurhash: img.info.as_ref().and_then(|i| i.blurhash.clone()),
                            thumbnail_source: img
                                .info
                                .as_ref()
                                .and_then(|i| i.thumbnail_source.clone())
                                .map(ViewerSource::Remote),
                            fallback_source: Some(ViewerSource::Remote(img.source.clone())),
                            thumb_size: Some((400, 300)),
                        },
                    )
                    .on_press(move |_| {
                        if guard.allows() {
                            image_viewer.set(Some(open_key.clone()));
                        }
                    })
                    .hoverable(Size::px(w), Size::px(h), 0.),
                )
                // The image fills the bubble edge to edge; its caption keeps the padding.
                .maybe_child(caption(body, img.filename.as_deref()).map(|cap| {
                    rect()
                        .padding(Gaps::new(0., 12., 0., 12.))
                        .child(label().text(cap).color(text_color))
                }))
                .into_element()
        }
        MessageType::File(f) => with_caption(
            file_attachment(
                freya_icons::lucide::file(),
                media_name(body, f.filename.as_deref(), "File"),
                f.info
                    .as_ref()
                    .and_then(|i| i.size)
                    .map(|s| format_file_size(s.into())),
                &f.source,
                is_me,
                guard,
                c,
            ),
            caption(body, f.filename.as_deref()),
            text_color,
        ),
        MessageType::Audio(a) => with_caption(
            file_attachment(
                freya_icons::lucide::music(),
                media_name(body, a.filename.as_deref(), "Audio"),
                a.info
                    .as_ref()
                    .and_then(|i| i.duration)
                    .map(format_media_duration),
                &a.source,
                is_me,
                guard,
                c,
            ),
            caption(body, a.filename.as_deref()),
            text_color,
        ),
        MessageType::Video(v) => {
            let duration = v
                .info
                .as_ref()
                .and_then(|i| i.duration)
                .map(format_media_duration);
            let thumbnail = v.info.as_ref().and_then(|i| i.thumbnail_source.clone());
            let video = match thumbnail {
                // The thumbnail, a play mark and the duration over it.
                Some(thumbnail) => {
                    let source = v.source.clone();
                    media_frame(
                        MEDIA_W,
                        MEDIA_H,
                        MediaThumbnail {
                            item_key: key,
                            blurhash: None,
                            thumbnail_source: Some(ViewerSource::Remote(thumbnail)),
                            fallback_source: None,
                            thumb_size: Some((400, 300)),
                        },
                    )
                    .on_press(move |_| {
                        if guard.allows() {
                            media::download(&source);
                        }
                    })
                    .child(
                        rect()
                            .position(Position::new_absolute().top(0.).left(0.))
                            .layer(1)
                            .expanded()
                            .center()
                            .child(
                                rect()
                                    .center()
                                    .width(Size::px(48.))
                                    .height(Size::px(48.))
                                    .corner_radius(24.)
                                    .background((0u8, 0u8, 0u8, 120u8))
                                    .child(
                                        SvgViewer::new(freya_icons::lucide::play())
                                            .color((255u8, 255u8, 255u8))
                                            .width(Size::px(24.))
                                            .height(Size::px(24.)),
                                    ),
                            ),
                    )
                    .maybe_child(duration.map(|d| {
                        rect()
                            .position(Position::new_absolute().bottom(6.).left(6.))
                            .layer(1)
                            .padding(Gaps::new(2., 8., 2., 8.))
                            .corner_radius(10.)
                            .background((0u8, 0u8, 0u8, 140u8))
                            .child(label().text(d).font_size(11.).color((255u8, 255u8, 255u8)))
                    }))
                    .into_element()
                }
                None => file_attachment(
                    freya_icons::lucide::play(),
                    media_name(body, v.filename.as_deref(), "Video"),
                    duration,
                    &v.source,
                    is_me,
                    guard,
                    c,
                ),
            };
            with_caption(video, caption(body, v.filename.as_deref()), text_color)
        }
        _ => return None,
    })
}

/// Clipped box an image or video thumbnail fills; the bubble rounds it.
fn media_frame(width: f32, height: f32, thumbnail: MediaThumbnail) -> Rect {
    rect()
        .width(Size::px(width))
        .height(Size::px(height))
        .overflow(Overflow::Clip)
        .child(thumbnail)
}

/// `body` with its caption under it.
fn with_caption(body: Element, caption: Option<String>, color: (u8, u8, u8)) -> Element {
    match caption {
        None => body,
        Some(caption) => rect()
            .vertical()
            .spacing(6.)
            .child(body)
            .child(label().text(caption).color(color))
            .into_element(),
    }
}

/// A round icon, then the name over a detail (size or duration), one line
/// each; downloads on press.
fn file_attachment(
    icon: Bytes,
    name: String,
    detail: Option<String>,
    source: &MediaSource,
    is_me: bool,
    guard: PressGuard,
    c: AppColors,
) -> Element {
    let source = source.clone();
    let (text, muted, icon_bg, icon_fg) = if is_me {
        (c.bubble_me_text, c.timestamp_me, c.on_primary, c.primary)
    } else {
        (
            c.bubble_other_text,
            c.on_surface_muted,
            c.primary,
            c.on_primary,
        )
    };
    rect()
        .horizontal()
        .max_width(Size::px(MEDIA_W))
        .content(Content::Flex)
        .cross_align(Alignment::Center)
        .spacing(10.)
        .on_press(move |_| {
            if guard.allows() {
                media::download(&source);
            }
        })
        .child(
            rect()
                .center()
                .width(Size::px(36.))
                .height(Size::px(36.))
                .corner_radius(18.)
                .background(icon_bg)
                .child(
                    SvgViewer::new(icon)
                        .color(icon_fg)
                        .width(Size::px(18.))
                        .height(Size::px(18.)),
                ),
        )
        .child(
            rect()
                .vertical()
                .width(Size::flex(1.))
                .child(
                    label()
                        .text(name)
                        .max_lines(1)
                        .text_overflow(TextOverflow::Ellipsis)
                        .font_size(14.)
                        .color(text),
                )
                .maybe_child(
                    detail.map(|d| label().text(d).max_lines(1).font_size(12.).color(muted)),
                ),
        )
        .hoverable(Size::auto(), Size::auto(), 0.)
}

#[cfg(test)]
mod tests {
    use super::media_size;

    #[test]
    fn image_frames_follow_the_aspect_ratio_within_limits() {
        assert_eq!(media_size(Some(1600), Some(900)), (240., 135.));
        assert_eq!(media_size(Some(1000), Some(1000)), (240., 240.));
        // Very tall or very wide: clamped (the image is cropped).
        assert_eq!(media_size(Some(500), Some(3000)), (240., 320.));
        assert_eq!(media_size(Some(3000), Some(300)), (240., 120.));
        assert_eq!(media_size(None, Some(10)), (240., 180.));
    }
}
