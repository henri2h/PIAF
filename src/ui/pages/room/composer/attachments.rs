//! Attachments: the Android picker sheet, and the banner of a pasted image
//! waiting to be sent (or of a file being sent).

use freya::prelude::*;

use crate::ui::components::{IconButton, ListItem, bottom_sheet};
use crate::utils::const_values::AppColors;
use crate::utils::media::{self, AttachSource};
use crate::utils::on_tokio;

/// Picks a file from `source` and sends it to `room_id`, `sending` meanwhile.
pub(super) fn send_picked(room_id: String, source: AttachSource, mut sending: State<bool>) {
    spawn(async move {
        let picked = on_tokio(media::pick_attachment(source)).await.flatten();
        let Some(file) = picked else { return };
        sending.set(true);
        on_tokio(async move {
            media::send_attachment(&room_id, &file.file_name, &file.mime, file.bytes).await
        })
        .await;
        sending.set(false);
    });
}

/// Sends a pasted PNG, `sending` meanwhile.
pub(super) fn send_pasted(room_id: String, png: Vec<u8>, mut sending: State<bool>) {
    sending.set(true);
    let done = on_tokio(async move {
        media::send_attachment(&room_id, "paste.png", &mime::IMAGE_PNG, png).await;
    });
    spawn(async move {
        done.await;
        sending.set(false);
    });
}

/// Android: Photos & videos / Camera / File.
pub(super) fn attach_sheet(
    room_id: String,
    mut open: State<bool>,
    sending: State<bool>,
    c: AppColors,
) -> Element {
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
                send_picked(room_id.clone(), source, sending);
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
    Some(
        row()
            .child(
                rect()
                    .width(Size::px(44.))
                    .height(Size::px(44.))
                    .corner_radius(4.)
                    .overflow(Overflow::Clip)
                    .child(
                        ImageViewer::new((format!("paste-{room_id}"), bytes::Bytes::from(png)))
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
