use freya::prelude::*;

use crate::utils::use_app_colors;

pub(super) fn labeled_input(
    field_label: &'static str,
    input: Input,
    _has_error: bool,
) -> impl IntoElement {
    let c = use_app_colors();

    rect()
        .vertical()
        .width(Size::fill())
        .spacing(6.)
        .child(
            label()
                .text(field_label)
                .font_size(13.)
                .font_weight(FontWeight::MEDIUM)
                .color(c.on_surface),
        )
        .child(
            rect()
                .width(Size::fill())
                .corner_radius(10.)
                .background(c.surface_container)
                .border(
                    Border::new()
                        .fill(c.outline_variant)
                        .width(1.)
                        .alignment(BorderAlignment::Inner),
                )
                .padding(Gaps::new(4., 4., 4., 14.))
                .child(input),
        )
}
