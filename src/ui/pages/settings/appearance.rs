use std::sync::Arc;

use freya::prelude::*;
use freya_router::prelude::RouterContext;

use crate::Route;
use crate::ui::components::{TopAppBar, TopAppBarTitle};
use crate::utils::const_values::AppColors;
use crate::utils::use_app_colors;

#[derive(PartialEq)]
pub struct SettingsAppearance {}

impl Component for SettingsAppearance {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let theme = use_theme();
        let is_dark = theme.read().name == "dark";

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Appearance".to_string()),
                on_back: Some(Arc::new(|| {
                    let _ = RouterContext::get().push(Route::Settings);
                })),
                actions: vec![],
            })
            .child(
                rect()
                    .vertical()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 0., 8., 0.))
                    .child(super::section_label("Theme", c))
                    .child(theme_selector(is_dark, c, theme)),
            )
    }
}

fn theme_selector(is_dark: bool, c: AppColors, mut theme: State<Theme>) -> Element {
    const OPTIONS: &[(bool, &str)] = &[(false, "Light"), (true, "Dark")];
    let mut row = rect()
        .horizontal()
        .width(Size::fill())
        .content(Content::flex())
        .padding(Gaps::new(8., 16., 12., 16.))
        .spacing(8.);
    for &(dark, name) in OPTIONS {
        let is_selected = dark == is_dark;
        let bg = if is_selected {
            c.primary
        } else {
            c.surface_container
        };
        let text_col = if is_selected {
            c.on_primary
        } else {
            c.on_surface_variant
        };
        row = row.child(
            rect()
                .height(Size::px(32.))
                .corner_radius(16.)
                .width(Size::flex(1.))
                .background(bg)
                .overflow(Overflow::Clip)
                .on_press(move |_| {
                    theme.set(crate::effective_theme(dark));
                    spawn(async move {
                        crate::utils::matrix::save_theme_pref(dark).await;
                    });
                })
                .child(
                    freya_material_design::prelude::Ripple::new()
                        .color(if is_selected { c.on_primary } else { c.primary })
                        .width(Size::fill_minimum())
                        .height(Size::fill())
                        .child(
                            rect()
                                .horizontal()
                                .height(Size::fill())
                                .padding(Gaps::new(0., 16., 0., 16.))
                                .cross_align(Alignment::Center)
                                .child(label().text(name).font_size(13.).color(text_col)),
                        ),
                )
                .into_element(),
        );
    }
    row.into_element()
}
