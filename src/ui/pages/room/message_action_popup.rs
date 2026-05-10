use std::{cell::RefCell, rc::Rc};

use freya::prelude::*;

use crate::utils::const_values::AppColors;

const REACTION_EMOJIS: &[&str] = &["👍", "❤️", "😂", "😮", "😢", "🎉"];

/// A single action entry shown in the popup button list.
pub struct PopupAction {
    pub icon: Bytes,
    pub label: &'static str,
    pub color: (u8, u8, u8),
    pub on_press: Box<dyn FnMut()>,
}

/// Builds the action popup using the Freya Popup component.
pub fn action_popup(
    c: AppColors,
    mut on_dismiss: impl FnMut() + 'static,
    on_react: Rc<RefCell<dyn FnMut(String) + 'static>>,
    actions: Vec<PopupAction>,
) -> Element {
    Popup::new()
        .show(true)
        .on_close_request(move |_| on_dismiss())
        .child(emoji_reaction_row(c, on_react))
        .children(action_button_list(c, actions))
        .into()
}

// ── Emoji row ─────────────────────────────────────────────────────────────────

fn emoji_reaction_row(c: AppColors, on_react: Rc<RefCell<dyn FnMut(String) + 'static>>) -> Element {
    let mut row = rect()
        .horizontal()
        .width(Size::fill())
        .content(Content::Flex)
        .spacing(4.);

    for emoji in REACTION_EMOJIS {
        let emoji_str = (*emoji).to_string();
        let react_fn = on_react.clone();
        let react_key = emoji_str.clone();
        row = row.child(
            rect()
                .center()
                .width(Size::flex(1.))
                .height(Size::px(44.))
                .corner_radius(10.)
                .background(c.surface_container)
                .on_press(move |_| (react_fn.borrow_mut())(react_key.clone()))
                .child(label().text(emoji_str).font_size(20.)),
        );
    }

    row.into()
}

// ── Action buttons ────────────────────────────────────────────────────────────

fn action_button_list(c: AppColors, actions: Vec<PopupAction>) -> Vec<Element> {
    actions
        .into_iter()
        .map(|mut a| {
            rect()
                .horizontal()
                .cross_align(Alignment::Center)
                .spacing(12.)
                .padding(Gaps::new(12., 8., 12., 8.))
                .corner_radius(10.)
                .background(c.surface_container)
                .width(Size::fill())
                .on_press(move |_| (a.on_press)())
                .child(
                    svg(a.icon)
                        .color(a.color)
                        .width(Size::px(18.))
                        .height(Size::px(18.)),
                )
                .child(label().text(a.label).font_size(15.).color(a.color))
                .into()
        })
        .collect()
}
