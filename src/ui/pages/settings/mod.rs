use std::sync::Arc;

use freya::prelude::*;
use freya_router::prelude::RouterContext;

use crate::ui::components::{TopAppBar, TopAppBarTitle};
use crate::utils::const_values::AppColors;
use crate::utils::{use_app_colors, use_tokio_track_watcher};
use crate::{Route, utils::matrix::CLIENT};

mod appearance;
mod notifications;
mod profile;
mod security;

pub use appearance::SettingsAppearance;
pub use notifications::SettingsNotifications;
pub use profile::SettingsProfile;
pub use security::SettingsSecurity;

#[derive(PartialEq)]
pub struct Settings {}

impl Component for Settings {
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

        let user_id = CLIENT
            .get()
            .and_then(|c| c.user_id().map(|id| id.to_string()))
            .unwrap_or_default();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Settings".to_string()),
                on_back: Some(Arc::new(|| {
                    let _ = RouterContext::get().push(Route::HomePage);
                })),
                actions: vec![],
            })
            .child(
                ScrollView::new()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .child(
                        rect()
                            .vertical()
                            .width(Size::fill())
                            .padding(Gaps::new(8., 0., 8., 0.))
                            .child(section_label("Account", c))
                            .child(nav_row(
                                "Profile",
                                Some(user_id.as_str()),
                                freya_icons::lucide::user(),
                                c,
                                Arc::new(|| {
                                    let _ = RouterContext::get().push(Route::SettingsProfile);
                                }),
                            ))
                            .child(section_label("Privacy & Security", c))
                            .child(nav_row(
                                "Encryption & Sessions",
                                None,
                                freya_icons::lucide::shield(),
                                c,
                                Arc::new(|| {
                                    let _ = RouterContext::get().push(Route::SettingsSecurity);
                                }),
                            ))
                            .child(section_label("System", c))
                            .child(nav_row(
                                "Notifications",
                                None,
                                freya_icons::lucide::bell(),
                                c,
                                Arc::new(|| {
                                    let _ = RouterContext::get().push(Route::SettingsNotifications);
                                }),
                            ))
                            .child(section_label("Appearance", c))
                            .child(nav_row(
                                "Appearance",
                                Some(match current_pref {
                                    1 => "Light",
                                    2 => "Dark",
                                    _ => "System",
                                }),
                                freya_icons::lucide::sun_moon(),
                                c,
                                Arc::new(|| {
                                    let _ = RouterContext::get().push(Route::SettingsAppearance);
                                }),
                            )),
                    ),
            )
    }
}

pub(super) fn section_label(text: &str, c: AppColors) -> Element {
    rect()
        .width(Size::fill())
        .padding(Gaps::new(12., 16., 4., 16.))
        .child(
            label()
                .text(text.to_string())
                .font_size(11.)
                .font_weight(FontWeight::BOLD)
                .color(c.primary),
        )
        .into_element()
}

pub(super) fn section_heading(text: &str, c: AppColors) -> Element {
    rect()
        .width(Size::fill())
        .padding(Gaps::new(8., 0., 4., 0.))
        .child(
            label()
                .text(text.to_string())
                .font_size(12.)
                .font_weight(FontWeight::BOLD)
                .color(c.primary),
        )
        .into_element()
}

pub(super) fn info_row(
    label_text: &str,
    value: &str,
    value_color: (u8, u8, u8),
    c: AppColors,
) -> Element {
    rect()
        .horizontal()
        .width(Size::fill())
        .cross_align(Alignment::Center)
        .content(Content::Flex)
        .child(
            label()
                .width(Size::flex(1.))
                .text(label_text.to_string())
                .font_size(14.)
                .color(c.on_surface_variant)
                .width(Size::flex(1.0)),
        )
        .child(
            label()
                .width(Size::flex(1.))
                .text(value.to_string())
                .font_size(14.)
                .color(value_color),
        )
        .into_element()
}

fn nav_row(
    title: &str,
    subtitle: Option<&str>,
    icon: bytes::Bytes,
    c: AppColors,
    on_press: Arc<dyn Fn()>,
) -> Element {
    rect()
        .width(Size::fill())
        .overflow(Overflow::Clip)
        .on_press(move |_| on_press())
        .child(
            freya_material_design::prelude::Ripple::new()
                .width(Size::fill())
                .child(
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .padding(Gaps::new(14., 16., 14., 16.))
                        .spacing(12.)
                        .cross_align(Alignment::Center)
                        .child(
                            svg(icon)
                                .width(Size::px(20.))
                                .height(Size::px(20.))
                                .color(c.on_surface_variant),
                        )
                        .child(
                            rect()
                                .vertical()
                                .spacing(2.)
                                .width(Size::flex(1.0))
                                .child(
                                    label()
                                        .text(title.to_string())
                                        .font_size(15.)
                                        .color(c.on_surface),
                                )
                                .child(if let Some(sub) = subtitle {
                                    label()
                                        .text(sub.to_string())
                                        .font_size(12.)
                                        .color(c.on_surface_muted)
                                        .into_element()
                                } else {
                                    rect().into_element()
                                }),
                        )
                        .child(
                            svg(freya_icons::lucide::chevron_right())
                                .width(Size::px(16.))
                                .height(Size::px(16.))
                                .color(c.outline_variant_light),
                        ),
                ),
        )
        .into_element()
}
