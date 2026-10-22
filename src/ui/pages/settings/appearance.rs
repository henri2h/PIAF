use freya::prelude::*;

use crate::ui::components::{Chip, TopAppBar};
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
            .child(TopAppBar::new("Appearance"))
            .child(
                rect()
                    .vertical()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 0., 8., 0.))
                    .child(super::section_label("Theme", c))
                    .child(theme_selector(is_dark, theme)),
            )
    }
}

fn theme_selector(is_dark: bool, theme: State<Theme>) -> Element {
    const OPTIONS: [(bool, &str); 2] = [(false, "Light"), (true, "Dark")];
    rect()
        .horizontal()
        .width(Size::fill())
        .content(Content::flex())
        .padding(Gaps::new(8., 16., 12., 16.))
        .spacing(8.)
        .children(OPTIONS.into_iter().map(|(dark, name)| {
            Chip::new(name, dark == is_dark, move |_| {
                crate::app::theme::set_dark(theme, dark);
            })
            .width(Size::flex(1.))
            .height(32.)
            .into_element()
        }))
        .into_element()
}
