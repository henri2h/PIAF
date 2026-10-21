use freya::prelude::*;

use crate::utils::const_values::AppColors;

/// Label, outlined input, and an optional helper line in its colour.
///
/// The outline is the field's own (primary while `focused`): the input's
/// border and background are cleared, or both outlines would show.
///
/// `action` (e.g. a show-password toggle) sits beside the input rather than in
/// `Input::trailing`: the input's own pointer handlers stop and cancel presses
/// anywhere inside it, so a button there never receives `on_press`.
pub(super) fn field(
    c: AppColors,
    field_label: &'static str,
    input: Input,
    focused: bool,
    action: Option<Element>,
    helper: Option<(String, (u8, u8, u8))>,
) -> Rect {
    let input = input.theme_colors(
        InputColorsThemePartial::new()
            .background(Color::TRANSPARENT)
            .focus_background(Color::TRANSPARENT)
            .border_fill(Color::TRANSPARENT)
            .focus_border_fill(Color::TRANSPARENT),
    );
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
                        .fill(if focused {
                            c.primary
                        } else {
                            c.outline_variant
                        })
                        .width(if focused { 2. } else { 1. })
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
        .maybe_child(helper.map(|(text, color)| label().text(text).font_size(12.).color(color)))
}

pub(super) fn icon(svg: bytes::Bytes, color: (u8, u8, u8)) -> SvgViewer {
    SvgViewer::new(svg)
        .width(Size::px(18.))
        .height(Size::px(18.))
        .color(color)
}
