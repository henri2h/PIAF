use freya::prelude::*;

use crate::utils::const_values::AppColors;

/// Placeholder filling its parent: an empty list or a failed load. Icon,
/// title and an optional hint, centered.
pub fn empty_state(
    icon: Bytes,
    title: impl Into<String>,
    hint: Option<&str>,
    c: AppColors,
) -> Rect {
    rect()
        .expanded()
        .center()
        .vertical()
        .spacing(12.)
        .padding(Gaps::new_all(24.))
        .child(
            SvgViewer::new(icon)
                .width(Size::px(48.))
                .height(Size::px(48.))
                .color(c.outline_variant_light),
        )
        .child(
            label()
                .text(title.into())
                .font_size(16.)
                .color(c.on_surface_muted),
        )
        .maybe_child(hint.map(|hint| {
            // Full width: an auto-width label draws centered text off its box.
            label()
                .width(Size::fill())
                .text(hint.to_string())
                .font_size(13.)
                .color(c.on_surface_faint)
                .text_align(TextAlign::Center)
        }))
}

/// Spinner filling its parent, with an optional caption.
pub fn loading_state(caption: Option<&str>, c: AppColors) -> Rect {
    rect()
        .expanded()
        .center()
        .vertical()
        .spacing(16.)
        .child(CircularLoader::new().size(40.))
        .maybe_child(caption.map(|caption| {
            label()
                .text(caption.to_string())
                .font_size(14.)
                .color(c.on_surface_muted)
        }))
}
