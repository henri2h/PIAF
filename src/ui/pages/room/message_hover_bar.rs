use freya::prelude::*;

use crate::ui::components::Hoverable;
use crate::utils::const_values::AppColors;

const QUICK_REACTIONS: &[&str] = &["👍", "❤️", "😂"];

/// Desktop toolbar shown beside a hovered message's bubble: quick reactions, reply, and
/// "more" (the full action popup).
pub(super) fn hover_bar(
    c: AppColors,
    on_react: impl Fn(String) + Clone + 'static,
    mut on_reply: impl FnMut() + 'static,
    mut on_more: impl FnMut() + 'static,
) -> Element {
    let mut bar = rect()
        .horizontal()
        .cross_align(Alignment::Center)
        .spacing(2.)
        .padding(Gaps::new_all(2.))
        .corner_radius(16.)
        .background(c.surface_container_high)
        .border(Border::new().width(1.).fill(c.outline_variant));

    for emoji in QUICK_REACTIONS {
        let on_react = on_react.clone();
        bar = bar.child(button(
            move || on_react((*emoji).to_string()),
            label().text(*emoji).font_size(15.).into_element(),
        ));
    }

    bar.child(icon_button(
        c,
        "Reply",
        freya_icons::lucide::reply(),
        move || on_reply(),
    ))
    .child(icon_button(
        c,
        "More",
        freya_icons::lucide::ellipsis(),
        move || on_more(),
    ))
    .into_element()
}

fn button(mut on_press: impl FnMut() + 'static, content: Element) -> Element {
    Hoverable {
        width: Size::px(28.),
        height: Size::px(28.),
        corner_radius: 14.,
        child: rect()
            .expanded()
            .center()
            .on_press(move |e: Event<PressEventData>| {
                e.stop_propagation();
                on_press();
            })
            .child(content)
            .into_element(),
    }
    .into_element()
}

fn icon_button(
    c: AppColors,
    tooltip: &'static str,
    icon: Bytes,
    on_press: impl FnMut() + 'static,
) -> Element {
    TooltipContainer::new(Tooltip::new_text(tooltip))
        .position(AttachedPosition::Top)
        .child(button(
            on_press,
            SvgViewer::new(icon)
                .color(c.on_surface)
                .width(Size::px(16.))
                .height(Size::px(16.))
                .into_element(),
        ))
        .into_element()
}
