use std::sync::Arc;

use freya::prelude::*;
use freya_router::prelude::RouterContext;

use crate::Route;
use crate::ui::components::{TopAppBar, TopAppBarTitle};
use crate::utils::const_values::AppColors;
use crate::utils::{use_app_colors, use_tokio_track_watcher};

#[derive(PartialEq)]
pub struct SettingsAppearance {}

impl Component for SettingsAppearance {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let mut _tpt: State<u64> = use_state(|| 0u64);
        if let Some(rx) = crate::THEME_PREF_RX.get() {
            use_tokio_track_watcher(rx, _tpt);
        }
        let current_pref = crate::THEME_PREF_RX
            .get()
            .map(|rx| *rx.borrow())
            .unwrap_or(0);

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
                    .child(theme_selector(current_pref, c)),
            )
    }
}

fn theme_selector(current: u8, c: AppColors) -> Element {
    const OPTIONS: &[(u8, &str)] = &[(0, "System"), (1, "Light"), (2, "Dark")];
    let mut row = rect()
        .horizontal()
        .width(Size::fill())
        .content(Content::flex())
        .padding(Gaps::new(8., 16., 12., 16.))
        .spacing(8.);
    for &(val, name) in OPTIONS {
        let is_selected = val == current;
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
                    if let Some(tx) = crate::THEME_PREF_TX.get() {
                        let _ = tx.send(val);
                    }
                    spawn(async move {
                        crate::utils::matrix::save_theme_pref(val).await;
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
