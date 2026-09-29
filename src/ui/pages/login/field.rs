use freya::prelude::*;

use crate::utils::const_values::AppColors;

/// Label, outlined input, and an optional helper line (red when `is_error`).
///
/// `action` (e.g. a show-password toggle) sits beside the input rather than in
/// `Input::trailing`: the input's own pointer handlers stop and cancel presses
/// anywhere inside it, so a button there never receives `on_press`.
pub(super) fn field(
    c: AppColors,
    field_label: &'static str,
    input: Input,
    action: Option<Rect>,
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
                .horizontal()
                .content(Content::Flex)
                .cross_align(Alignment::Center)
                .spacing(4.)
                .child(input.width(Size::flex(1.)))
                .maybe_child(action),
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
