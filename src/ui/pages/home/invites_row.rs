use freya::prelude::*;
use freya_icons::lucide;

use super::room_list_item::ROOM_ROW_HEIGHT;
use crate::ui::components::HoverableExt;
use crate::utils::haptics::{self, Haptic};
use crate::utils::use_app_colors;

/// Pending invites folded into one row at the top of the list; a tap lists
/// them below it (or folds them back).
#[derive(PartialEq)]
pub struct InvitesRow {
    pub count: usize,
    /// Names of the invited rooms, newest first.
    pub names: Vec<String>,
    pub expanded: State<bool>,
}

impl Component for InvitesRow {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut expanded = self.expanded;
        let is_expanded = *expanded.read();

        let icon = rect()
            .width(Size::px(48.))
            .height(Size::px(48.))
            .corner_radius(24.)
            .center()
            .background(c.primary_container)
            .child(
                SvgViewer::new(lucide::mail())
                    .width(Size::px(22.))
                    .height(Size::px(22.))
                    .color(c.on_primary_container),
            );

        let text = rect()
            .vertical()
            .width(Size::flex(1.))
            .spacing(2.)
            .child(
                label()
                    .text("Invites")
                    .font_size(16.)
                    .font_weight(FontWeight::BOLD)
                    .color(c.on_surface),
            )
            .child(
                label()
                    .text(self.names.join(", "))
                    .max_lines(1)
                    .text_overflow(TextOverflow::Ellipsis)
                    .font_size(13.5)
                    .color(c.on_surface_variant),
            );

        let count = rect()
            .min_width(Size::px(20.))
            .height(Size::px(20.))
            .corner_radius(10.)
            .padding(Gaps::new(0., 6., 0., 6.))
            .center()
            .background(c.primary)
            .child(
                label()
                    .text(self.count.to_string())
                    .font_size(11.)
                    .color(c.on_primary),
            );

        rect()
            .width(Size::fill())
            .height(Size::px(ROOM_ROW_HEIGHT))
            .padding(Gaps::new(2., 8., 2., 8.))
            .child(
                rect()
                    .horizontal()
                    .expanded()
                    .content(Content::Flex)
                    .padding(Gaps::new(8., 12., 8., 12.))
                    .spacing(14.)
                    .cross_align(Alignment::Center)
                    .on_press(move |_| {
                        haptics::play(Haptic::Click);
                        expanded.toggle();
                    })
                    .child(icon)
                    .child(text)
                    .child(count)
                    .child(
                        SvgViewer::new(if is_expanded {
                            lucide::chevron_up()
                        } else {
                            lucide::chevron_down()
                        })
                        .width(Size::px(18.))
                        .height(Size::px(18.))
                        .color(c.on_surface_variant),
                    )
                    .hoverable(Size::fill(), Size::fill(), 12.),
            )
    }
}
