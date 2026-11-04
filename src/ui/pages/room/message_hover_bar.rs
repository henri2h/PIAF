use freya::prelude::*;

use crate::ui::components::{HoverableExt, IconButton};
use crate::utils::const_values::AppColors;

const QUICK_REACTIONS: &[&str] = &["👍", "❤️", "😂"];
const BUTTON: f32 = 28.;

/// Desktop toolbar shown beside a hovered message's bubble: quick reactions, reply, and
/// "more" (the full action popup).
pub(super) fn hover_bar(
    c: AppColors,
    on_react: impl Fn(String) + Clone + 'static,
    mut on_reply: impl FnMut() + 'static,
    mut on_more: impl FnMut() + 'static,
) -> Element {
    rect()
        .horizontal()
        .cross_align(Alignment::Center)
        .spacing(2.)
        .padding(Gaps::new_all(2.))
        .corner_radius(16.)
        .background(c.surface_container_high)
        .border(Border::new().width(1.).fill(c.outline_variant))
        .children(QUICK_REACTIONS.iter().map(|emoji| {
            let on_react = on_react.clone();
            rect()
                .center()
                .width(Size::px(BUTTON))
                .height(Size::px(BUTTON))
                .on_press(move |e: Event<PressEventData>| {
                    e.stop_propagation();
                    on_react((*emoji).to_string());
                })
                .child(label().text(*emoji).font_size(15.))
                .hoverable(Size::px(BUTTON), Size::px(BUTTON), BUTTON / 2.)
        }))
        .child(
            IconButton::new(freya_icons::lucide::reply(), c.on_surface, move |_| {
                on_reply()
            })
            .tooltip("Reply")
            .size(BUTTON, 16.),
        )
        .child(
            IconButton::new(freya_icons::lucide::ellipsis(), c.on_surface, move |_| {
                on_more()
            })
            .tooltip("More")
            .size(BUTTON, 16.),
        )
        .into_element()
}
