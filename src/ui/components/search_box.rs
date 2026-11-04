use freya::prelude::*;

use super::{SearchField, search_input};
use crate::utils::use_app_colors;

/// A search box inside a page (filtering a list). On Android the keyboard
/// types through the IME bridge like [`SearchField`] (suggestions, accents,
/// swipe typing), which a plain `Input` doesn't get.
#[derive(PartialEq)]
pub struct SearchBox {
    pub value: State<String>,
    pub placeholder: &'static str,
    pub auto_focus: bool,
}

impl Component for SearchBox {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let dismiss = use_state(|| false);
        if !cfg!(target_os = "android") {
            return search_input(self.value, self.placeholder, c)
                .auto_focus(self.auto_focus)
                .into_element();
        }
        rect()
            .horizontal()
            .width(Size::fill())
            .height(Size::px(44.))
            .content(Content::Flex)
            .cross_align(Alignment::Center)
            .corner_radius(8.)
            .background(c.surface_container)
            .padding(Gaps::new(0., 2., 0., 12.))
            .spacing(10.)
            .child(
                SvgViewer::new(freya_icons::lucide::search())
                    .color(c.on_surface_variant)
                    .width(Size::px(15.))
                    .height(Size::px(15.)),
            )
            .child(SearchField {
                value: self.value,
                placeholder: self.placeholder,
                on_submit: EventHandler::new(|_: String| {}),
                dismiss,
                auto_focus: self.auto_focus,
                font_size: 16.,
            })
            .into_element()
    }
}
