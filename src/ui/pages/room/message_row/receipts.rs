//! Under a bubble: who read up to it, and a failed send's "Discard".

use std::sync::Arc;

use freya::prelude::*;
use matrix_sdk_ui::timeline::{EventTimelineItem, TimelineItem};

use super::PressGuard;
use crate::ui::components::{Avatar, HoverableExt};
use crate::utils::avatars::AvatarSource;
use crate::utils::const_values::AppColors;
use crate::utils::id_color;

const SHOWN_RECEIPTS: usize = 5;

/// The readers' avatars (a few, then "+n"); a tap opens the details.
pub(super) fn read_receipts_row(
    readers: &[String],
    room_id: &str,
    item: Arc<TimelineItem>,
    mut detail_modal: State<Option<Arc<TimelineItem>>>,
    guard: PressGuard,
    c: AppColors,
) -> Element {
    let extra = readers.len().saturating_sub(SHOWN_RECEIPTS);
    rect()
        .horizontal()
        .width(Size::fill())
        .main_align(Alignment::End)
        .padding(Gaps::new(1., 12., 1., 12.))
        .spacing(2.)
        .on_press(move |_| {
            if guard.allows() {
                detail_modal.set(Some(item.clone()));
            }
        })
        .children(readers.iter().take(SHOWN_RECEIPTS).map(|uid| {
            Avatar {
                size: 16.,
                source: Some(AvatarSource::member(room_id, uid)),
                name: uid.clone(),
                color: id_color(uid),
            }
            .into_element()
        }))
        .maybe_child((extra > 0).then(|| {
            rect()
                .center()
                .width(Size::px(16.))
                .height(Size::px(16.))
                .corner_radius(8.)
                .background(c.overflow_badge_bg)
                .child(
                    label()
                        .text(format!("+{extra}"))
                        .font_size(8.)
                        .color(c.on_primary),
                )
        }))
        .hoverable(Size::fill(), Size::auto(), 0.)
}

/// "Failed to send" with a button dropping the local echo.
pub(super) fn failed_send_row(
    event: &EventTimelineItem,
    guard: PressGuard,
    c: AppColors,
) -> Option<Element> {
    let handle = event.local_echo_send_handle()?;
    Some(
        rect()
            .horizontal()
            .width(Size::fill())
            .main_align(Alignment::End)
            .padding(Gaps::new(1., 12., 2., 12.))
            .spacing(8.)
            .child(label().text("Failed to send").font_size(11.).color(c.error))
            .child(
                rect()
                    .corner_radius(4.)
                    .padding(Gaps::new(2., 8., 2., 8.))
                    .background(c.error)
                    .on_press(move |_| {
                        if guard.allows() {
                            let handle = handle.clone();
                            tokio::task::spawn(async move {
                                let _ = handle.abort().await;
                            });
                        }
                    })
                    .child(
                        label()
                            .text("Discard")
                            .font_size(11.)
                            .color((255u8, 255u8, 255u8)),
                    )
                    .hoverable(Size::auto(), Size::auto(), 4.),
            )
            .into_element(),
    )
}
