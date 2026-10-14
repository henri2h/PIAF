use freya::prelude::*;
use matrix_sdk::ruma::events::room::{MediaSource, message::MessageType};
use matrix_sdk_ui::timeline::Message;

use crate::ui::components::{HoverableExt, MediaThumbnail, ViewerSource};
use crate::utils::const_values::AppColors;
use crate::utils::media::{self, format_file_size, format_media_duration};
use crate::utils::timeline_media::caption;

const MEDIA_W: f32 = 200.;
const MEDIA_H: f32 = 150.;

/// Body of a message bubble; `None` for message types not shown.
pub(super) fn message_content(
    message: &Message,
    event_id: Option<String>,
    is_me: bool,
    mut image_viewer: State<Option<String>>,
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
            rect()
                .vertical()
                .spacing(6.)
                .child(
                    media_frame(MediaThumbnail {
                        item_key: key,
                        blurhash: img.info.as_ref().and_then(|i| i.blurhash.clone()),
                        thumbnail_source: img
                            .info
                            .as_ref()
                            .and_then(|i| i.thumbnail_source.clone())
                            .map(ViewerSource::Remote),
                        fallback_source: Some(ViewerSource::Remote(img.source.clone())),
                        thumb_size: Some((400, 300)),
                    })
                    .on_press(move |_| image_viewer.set(Some(open_key.clone())))
                    .hoverable(Size::px(MEDIA_W), Size::px(MEDIA_H), 8.),
                )
                .maybe_child(caption(&img.body).map(|cap| label().text(cap).color(text_color)))
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
            c,
        ),
        MessageType::Video(v) => {
            let thumbnail = v.info.as_ref().and_then(|i| i.thumbnail_source.clone());
            rect()
                .vertical()
                .spacing(4.)
                .maybe_child(thumbnail.map(|thumbnail| {
                    media_frame(MediaThumbnail {
                        item_key: key,
                        blurhash: None,
                        thumbnail_source: Some(ViewerSource::Remote(thumbnail)),
                        fallback_source: None,
                        thumb_size: Some((400, 300)),
                    })
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
                    c,
                ))
                .into_element()
        }
        _ => return None,
    })
}

/// Rounded, clipped box an image or video thumbnail fills.
fn media_frame(thumbnail: MediaThumbnail) -> Rect {
    rect()
        .width(Size::px(MEDIA_W))
        .height(Size::px(MEDIA_H))
        .corner_radius(8.)
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
    c: AppColors,
) -> Element {
    let source = source.clone();
    rect()
        .horizontal()
        .cross_align(Alignment::Center)
        .spacing(8.)
        .padding(Gaps::new(4., 0., 4., 0.))
        .on_press(move |_| media::download(&source))
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
