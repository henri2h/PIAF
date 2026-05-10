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

/// Builds the full action popup: backdrop + positioned card with emoji row and buttons.
///
/// The card appears above the message when it sits in the lower half of the screen,
/// and below it otherwise.  Horizontal position is clamped to remain on screen.
pub fn action_popup(
    area: Area,
    c: AppColors,
    mut on_dismiss: impl FnMut() + 'static,
    on_react: Rc<RefCell<dyn FnMut(String) + 'static>>,
    actions: Vec<PopupAction>,
) -> Element {
    let win = Platform::get().root_size.peek();
    let win_w = win.width;
    let win_h = win.height;

    const CARD_W: f32 = 300.;
    const CARD_MARGIN: f32 = 8.;

    let space_below = win_h - (area.origin.y + area.size.height);
    let show_below = space_below >= area.origin.y;

    let card_top = if show_below {
        area.origin.y + area.size.height + CARD_MARGIN
    } else {
        let estimated_h = 68. + actions.len() as f32 * 52. + 48.;
        (area.origin.y - estimated_h - CARD_MARGIN).max(CARD_MARGIN)
    };

    let msg_center_x = area.origin.x + area.size.width / 2.;
    let card_left = (msg_center_x - CARD_W / 2.)
        .max(CARD_MARGIN)
        .min(win_w - CARD_W - CARD_MARGIN);

    rect()
        .position(Position::new_global().top(0.).left(0.))
        .layer(Layer::Overlay)
        .width(Size::window_percent(100.))
        .height(Size::window_percent(100.))
        .background((0u8, 0u8, 0u8, 100u8))
        .on_press(move |_| on_dismiss())
        .child(
            rect()
                .position(Position::new_absolute().top(card_top).left(card_left))
                .width(Size::px(CARD_W))
                .background(c.surface_container_high)
                .corner_radius(16.)
                .shadow((0., 4., 16., 0., (0u8, 0u8, 0u8, 80u8)))
                .vertical()
                .padding(Gaps::new(12., 12., 12., 12.))
                .spacing(8.)
                .on_press(|e: Event<PressEventData>| e.stop_propagation())
                .child(emoji_reaction_row(c, on_react))
                .children(action_button_list(c, actions)),
        )
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
