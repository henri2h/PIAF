use freya::prelude::*;
use freya_material_design::prelude::Ripple;

use crate::utils::use_app_colors;

/// A Material Design 3 list item with leading icon, label, optional sub-label,
/// and a trailing chevron. `overflow(Overflow::Clip)` is applied internally so
/// the Ripple animation is clipped without affecting adjacent dividers.
pub fn m3_list_item(
    icon: bytes::Bytes,
    item_label: impl Into<String>,
    sublabel: Option<String>,
    icon_color: (u8, u8, u8),
    destructive: bool,
    on_press: impl FnMut(Event<PressEventData>) + 'static,
) -> Element {
    let c = use_app_colors();
    let text_color = if destructive { c.error } else { c.on_surface };
    let item_label = item_label.into();
    let mut hovered: State<bool> = use_state(|| false);
    let bg = if *hovered.read() {
        c.surface_container
    } else {
        c.surface
    };

    rect()
        .width(Size::fill())
        .overflow(Overflow::Clip)
        .background(bg)
        .on_pointer_enter(move |_| *hovered.write() = true)
        .on_pointer_leave(move |_| *hovered.write() = false)
        .on_press(on_press)
        .child(
            Ripple::new()
                .color(if destructive { c.error } else { c.primary })
                .width(Size::fill_minimum())
                .child(
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .height(Size::px(56.))
                        .padding(Gaps::new(0., 24., 0., 16.))
                        .spacing(16.)
                        .cross_align(Alignment::Center)
                        .content(Content::Flex)
                        .child(
                            svg(icon)
                                .color(icon_color)
                                .width(Size::px(24.))
                                .height(Size::px(24.)),
                        )
                        .child(
                            rect()
                                .vertical()
                                .width(Size::flex(1.0))
                                .spacing(2.)
                                .child(label().text(item_label).font_size(16.).color(text_color))
                                .maybe_child(sublabel.map(|sub| {
                                    label().text(sub).font_size(14.).color(c.on_surface_variant)
                                })),
                        )
                        .child(
                            svg(freya_icons::lucide::chevron_right())
                                .color(c.on_surface_variant)
                                .width(Size::px(20.))
                                .height(Size::px(20.)),
                        ),
                ),
        )
        .into()
}
