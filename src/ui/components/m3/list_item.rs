use freya::prelude::*;
use freya_material_design::prelude::Ripple;

use crate::utils::use_app_colors;

#[derive(PartialEq)]
pub struct M3ListItem {
    pub icon: bytes::Bytes,
    pub item_label: String,
    pub sublabel: Option<String>,
    pub icon_color: (u8, u8, u8),
    pub destructive: bool,
    pub on_press: EventHandler<Event<PressEventData>>,
}

impl Component for M3ListItem {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let text_color = if self.destructive {
            c.error
        } else {
            c.on_surface
        };
        let item_label = self.item_label.clone();
        let sublabel = self.sublabel.clone();
        let icon = self.icon.clone();
        let icon_color = self.icon_color;
        let destructive = self.destructive;
        let on_press = self.on_press.clone();
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
                                    .child(
                                        label().text(item_label).font_size(16.).color(text_color),
                                    )
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
    }
}
