use std::sync::Arc;

use freya::prelude::*;

use crate::Route;
use crate::ui::components::{M3ListItem, TopAppBar, TopAppBarTitle};
use crate::utils::const_values::AppColors;
use crate::utils::use_app_colors;

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

        let is_dark = use_theme().read().name == "dark";
        let theme_label = if is_dark { "Dark" } else { "Light" };

        let user_id = crate::utils::matrix::my_user_id().unwrap_or_default();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Settings".to_string()),
                on_back: Some(Arc::new(crate::app::navigation::go_back_or_home)),
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
                                    crate::app::navigation::push(Route::SettingsProfile);
                                }),
                            ))
                            .child(section_label("Privacy & Security", c))
                            .child(nav_row(
                                "Encryption & Sessions",
                                None,
                                freya_icons::lucide::shield(),
                                c,
                                Arc::new(|| {
                                    crate::app::navigation::push(Route::SettingsSecurity);
                                }),
                            ))
                            .child(section_label("System", c))
                            .child(nav_row(
                                "Notifications",
                                None,
                                freya_icons::lucide::bell(),
                                c,
                                Arc::new(|| {
                                    crate::app::navigation::push(Route::SettingsNotifications);
                                }),
                            ))
                            .child(section_label("Appearance", c))
                            .child(nav_row(
                                "Appearance",
                                Some(theme_label),
                                freya_icons::lucide::sun_moon(),
                                c,
                                Arc::new(|| {
                                    crate::app::navigation::push(Route::SettingsAppearance);
                                }),
                            )),
                    ),
            )
    }
}

/// Icon + text content for a settings `Button`.
pub(super) fn button_label(icon: bytes::Bytes, text: &'static str, c: AppColors) -> Rect {
    rect()
        .horizontal()
        .cross_align(Alignment::Center)
        .spacing(6.)
        .child(
            SvgViewer::new(icon)
                .color(c.on_surface)
                .width(Size::px(16.))
                .height(Size::px(16.)),
        )
        .child(label().text(text))
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
    M3ListItem {
        icon,
        item_label: title.to_string(),
        sublabel: subtitle.map(str::to_string),
        icon_color: c.on_surface_variant,
        destructive: false,
        on_press: EventHandler::new(move |_| on_press()),
    }
    .into_element()
}
