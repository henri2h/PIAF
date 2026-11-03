//! Attachments: the Android picker sheet, and the banner of a pasted image
//! waiting to be sent (or of a file being sent).

use freya::prelude::*;

use crate::ui::components::{IconButton, ListItem, bottom_sheet};
use crate::utils::const_values::AppColors;
use crate::utils::media::{self, AttachSource};
use crate::utils::on_tokio;

/// Picks a file from `source` and sends it to `room_id`. All on tokio: the
/// picker (camera…) can outlive the sheet or the room page that opened it.
/// The timeline shows the upload (local echo).
pub(super) fn send_picked(room_id: String, source: AttachSource) {
    tokio::spawn(async move {
        let Some(file) = media::pick_attachment(source).await else {
            tracing::info!(?source, "attachment: nothing picked");
            return;
        };
        tracing::info!(?source, size = file.bytes.len(), "attachment picked");
        media::send_attachment(&room_id, &file.file_name, &file.mime, file.bytes).await;
    });
}

/// Sends a pasted image, `sending` meanwhile.
pub(super) fn send_pasted(room_id: String, image: Vec<u8>, mut sending: State<bool>) {
    sending.set(true);
    let done = on_tokio(async move {
        let (mime, ext) = media::sniff_image_mime(&image);
        media::send_attachment(&room_id, &format!("paste.{ext}"), &mime, image).await;
    });
    spawn(async move {
        done.await;
        sending.set(false);
    });
}

/// Android: Photos & videos / Camera / File.
pub(super) fn attach_sheet(room_id: String, mut open: State<bool>, c: AppColors) -> Element {
    let option = |icon: Bytes, text: &'static str, source: AttachSource| {
        let room_id = room_id.clone();
        ListItem::new(text)
            .leading(
                rect()
                    .width(Size::px(40.))
                    .height(Size::px(40.))
                    .corner_radius(20.)
                    .center()
                    .background(c.primary_container)
                    .child(
                        SvgViewer::new(icon)
                            .width(Size::px(20.))
                            .height(Size::px(20.))
                            .color(c.on_primary_container),
                    ),
            )
            .on_press(move |_| {
                open.set(false);
                send_picked(room_id.clone(), source);
            })
    };
    bottom_sheet(c, move || open.set(false))
        .title("Attach")
        .child(option(
            freya_icons::lucide::image(),
            "Photos & videos",
            AttachSource::Gallery,
        ))
        .child(option(
            freya_icons::lucide::camera(),
            "Camera",
            AttachSource::Camera,
        ))
        .child(option(
            freya_icons::lucide::file(),
            "File",
            AttachSource::File,
        ))
        .into_element()
}

/// "Sending…", or the pasted image ready to go (× drops it).
pub(super) fn attachment_banner(
    room_id: &str,
    sending: bool,
    mut pending: State<Option<Vec<u8>>>,
    c: AppColors,
) -> Option<Element> {
    let row = || {
        rect()
            .horizontal()
            .width(Size::fill())
            .padding(Gaps::new(4., 12., 0., 12.))
            .cross_align(Alignment::Center)
            .spacing(8.)
    };
    if sending {
        return Some(
            row()
                .child(CircularLoader::new().size(16.))
                .child(
                    label()
                        .text("Sending…")
                        .font_size(12.)
                        .color(c.on_surface_muted),
                )
                .into_element(),
        );
    }
    let png = pending.read().clone()?;
    // Per image: the viewer caches by key, a second paste must not show the first.
    let key = {
        use std::hash::{Hash, Hasher};
        let mut hasher = std::collections::hash_map::DefaultHasher::new();
        png.hash(&mut hasher);
        format!("paste-{room_id}-{:x}", hasher.finish())
    };
    Some(
        row()
            .child(
                rect()
                    .width(Size::px(44.))
                    .height(Size::px(44.))
                    .corner_radius(4.)
                    .overflow(Overflow::Clip)
                    .child(
                        ImageViewer::new((key, bytes::Bytes::from(png)))
                            .width(Size::fill())
                            .height(Size::fill())
                            .aspect_ratio(AspectRatio::Max)
                            .image_cover(ImageCover::Center),
                    ),
            )
            .child(
                label()
                    .text("Image ready to send")
                    .font_size(12.)
                    .color(c.on_surface_muted)
                    .width(Size::fill_minimum()),
            )
            .child(
                IconButton::new(freya_icons::lucide::x(), c.on_surface_muted, move |_| {
                    pending.set(None)
                })
                .size(20., 14.),
            )
            .into_element(),
    )
}
