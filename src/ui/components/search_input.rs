use freya::prelude::*;

use crate::utils::const_values::AppColors;

/// Filled search field with a leading search icon; chain `auto_focus`,
/// `on_submit`, … on the returned `Input`.
pub fn search_input(
    value: impl Into<Writable<String>>,
    placeholder: &'static str,
    c: AppColors,
) -> Input {
    Input::new(value)
        .leading(
            SvgViewer::new(freya_icons::lucide::search())
                .color(c.on_surface_variant)
                .width(Size::px(15.))
                .height(Size::px(15.)),
        )
        .placeholder(placeholder)
        .width(Size::fill())
        .theme_colors(InputColorsThemePartial {
            background: Some(Preference::Specific(Color::from(c.surface_container))),
            focus_background: Some(Preference::Specific(Color::from(c.surface_container))),
            border_fill: Some(Preference::Specific(Color::TRANSPARENT)),
            focus_border_fill: Some(Preference::Specific(Color::from(c.primary))),
            ..Default::default()
        })
        .theme_layout(InputLayoutThemePartial {
            corner_radius: Some(Preference::Specific(CornerRadius::new_all(8.))),
            padding: Some(Preference::Specific(Gaps::new(10., 10., 10., 10.))),
        })
}
