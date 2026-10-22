use freya::prelude::*;
use matrix_sdk::ruma::events::room::{MediaSource, message::MessageType};
use matrix_sdk_ui::timeline::Message;

use crate::ui::components::{HoverableExt, MediaThumbnail, ViewerSource};
use crate::utils::const_values::AppColors;
use crate::utils::media::{self, format_file_size, format_media_duration};
use crate::utils::timeline_media::caption;

use super::message_row::PressGuard;

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

/// Body of a message bubble; `None` for message types not shown.
pub(super) fn message_content(
    message: &Message,
    event_id: Option<String>,
    is_me: bool,
    mut image_viewer: State<Option<String>>,
    guard: PressGuard,
    c: AppColors,
) -> Option<Element> {
    let text_color = if is_me {
        c.bubble_me_text
    } else {
        c.bubble_other_text
    };
    let key = event_id.unwrap_or_else(|| "media-unknown".to_string());
    Some(match message.msgtype() {
        MessageType::Text(t) => rect()
            .color(text_color)
            .child(MarkdownViewer::new(t.body.clone()).color(text_color))
            .into_element(),
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
                .maybe_child(caption(&img.body).map(|cap| {
                    rect()
                        .padding(Gaps::new(0., 12., 0., 12.))
                        .child(label().text(cap).color(text_color))
                }))
                .into_element()
        }
        MessageType::File(f) => file_attachment(
            freya_icons::lucide::paperclip(),
            f.filename.clone().unwrap_or_else(|| f.body.clone()),
            f.info
                .as_ref()
                .and_then(|i| i.size)
                .map(|s| format_file_size(s.into())),
            &f.source,
            text_color,
            guard,
            c,
        ),
        MessageType::Audio(a) => file_attachment(
            freya_icons::lucide::music(),
            a.body.clone(),
            a.info
                .as_ref()
                .and_then(|i| i.duration)
                .map(format_media_duration),
            &a.source,
            text_color,
            guard,
            c,
        ),
        MessageType::Video(v) => {
            let thumbnail = v.info.as_ref().and_then(|i| i.thumbnail_source.clone());
            rect()
                .vertical()
                .spacing(4.)
                .maybe_child(thumbnail.map(|thumbnail| {
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
                    .child(
                        rect()
                            .position(Position::new_absolute().top(0.).left(0.))
                            .layer(1)
                            .expanded()
                            .center()
                            .child(
                                SvgViewer::new(freya_icons::lucide::play())
                                    .color((255u8, 255u8, 255u8))
                                    .width(Size::px(32.))
                                    .height(Size::px(32.)),
                            ),
                    )
                }))
                .child(file_attachment(
                    freya_icons::lucide::film(),
                    v.body.clone(),
                    v.info
                        .as_ref()
                        .and_then(|i| i.duration)
                        .map(format_media_duration),
                    &v.source,
                    text_color,
                    guard,
                    c,
                ))
                .into_element()
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

/// Icon, name and a detail line (size or duration); downloads on press.
fn file_attachment(
    icon: Bytes,
    name: String,
    detail: Option<String>,
    source: &MediaSource,
    text_color: (u8, u8, u8),
    guard: PressGuard,
    c: AppColors,
) -> Element {
    let source = source.clone();
    rect()
        .horizontal()
        .cross_align(Alignment::Center)
        .spacing(8.)
        .padding(Gaps::new(4., 0., 4., 0.))
        .on_press(move |_| {
            if guard.allows() {
                media::download(&source);
            }
        })
        .child(
            SvgViewer::new(icon)
                .color(text_color)
                .width(Size::px(16.))
                .height(Size::px(16.)),
        )
        .child(
            rect()
                .vertical()
                .child(label().text(name).font_size(13.).color(text_color))
                .maybe_child(
                    detail.map(|d| label().text(d).font_size(11.).color(c.on_surface_muted)),
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
