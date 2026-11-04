use freya::prelude::*;

use crate::ui::components::IconButton;
use crate::utils::const_values::AppColors;

/// One action under the room header.
pub(super) struct Action {
    pub icon: bytes::Bytes,
    pub label: String,
    /// Filled with the primary container (e.g. a muted room).
    pub highlighted: bool,
    pub on_press: Box<dyn FnMut(()) + 'static>,
}

/// The row of round buttons under the room header, spread over the width.
pub(super) fn action_buttons(actions: Vec<Action>, c: AppColors) -> Element {
    rect()
        .horizontal()
        .width(Size::fill())
        .content(Content::Flex)
        .padding(Gaps::new(0., 8., 8., 8.))
        .children(actions.into_iter().map(|action| {
            let (background, color) = if action.highlighted {
                (c.primary_container, c.on_primary_container)
            } else {
                (c.surface_container_high, c.on_surface)
            };
            rect()
                .vertical()
                .width(Size::flex(1.))
                .cross_align(Alignment::Center)
                .spacing(6.)
                .child(
                    IconButton::new(action.icon, color, action.on_press)
                        .size(52., 22.)
                        .background(background),
                )
                .child(
                    label()
                        .text(action.label)
                        .max_lines(1)
                        .text_overflow(TextOverflow::Ellipsis)
                        .font_size(12.)
                        .color(c.on_surface_variant),
                )
                .into_element()
        }))
        .into_element()
}
