use freya::prelude::*;

use crate::utils::const_values::AppColors;

/// Label, outlined input, and an optional helper line (red when `is_error`).
pub(super) fn field(
    c: AppColors,
    field_label: &'static str,
    input: Input,
    helper: Option<(String, bool)>,
) -> Rect {
    rect()
        .vertical()
        .width(Size::fill())
        .spacing(6.)
        .child(
            label()
                .text(field_label)
                .font_size(13.)
                .font_weight(FontWeight::MEDIUM)
                .color(c.on_surface_variant),
        )
        .child(
            rect()
                .width(Size::fill())
                .corner_radius(12.)
                .background(c.surface_container)
                .border(
                    Border::new()
                        .fill(c.outline_variant)
                        .width(1.)
                        .alignment(BorderAlignment::Inner),
                )
                .padding(Gaps::new(4., 8., 4., 12.))
                .child(input),
        )
        .maybe_child(helper.map(|(text, is_error)| {
            label().text(text).font_size(12.).color(if is_error {
                c.error
            } else {
                c.on_surface_muted
            })
        }))
}

pub(super) fn icon(svg: bytes::Bytes, color: (u8, u8, u8)) -> SvgViewer {
    SvgViewer::new(svg)
        .width(Size::px(18.))
        .height(Size::px(18.))
        .color(color)
}
