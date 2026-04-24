use freya::prelude::*;

use crate::ui::components::Avatar;
use crate::utils::use_app_colors;

#[derive(Debug, Clone, PartialEq)]
pub(super) struct SearchResultItem {
    pub sender_name: String,
    pub sender_initial: char,
    pub sender_color: (u8, u8, u8),
    pub body: String,
    pub timestamp: String,
}

#[derive(Clone, PartialEq)]
pub(super) struct SearchResultRow {
    pub item: SearchResultItem,
}

impl Component for SearchResultRow {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let item = &self.item;
        rect()
            .horizontal()
            .width(Size::fill())
            .padding(Gaps::new(10., 16., 10., 16.))
            .spacing(12.)
            .cross_align(Alignment::Start)
            .child(Avatar {
                size: 36.,
                bytes: None,
                initial: item.sender_initial.to_string(),
                color: item.sender_color,
                image_key: String::new(),
            })
            .child(
                rect()
                    .vertical()
                    .spacing(2.)
                    .width(Size::fill())
                    .child(
                        rect()
                            .horizontal()
                            .content(Content::Flex)
                            .width(Size::fill())
                            .child(
                                label()
                                    .text(item.sender_name.clone())
                                    .width(Size::flex(1.0))
                                    .font_weight(FontWeight::MEDIUM)
                                    .font_size(14.),
                            )
                            .child(
                                label()
                                    .text(item.timestamp.clone())
                                    .font_size(12.)
                                    .color(c.on_surface_faint),
                            ),
                    )
                    .child(
                        label()
                            .text(item.body.clone())
                            .width(Size::fill())
                            .font_size(13.)
                            .color(c.reply_other_text),
                    ),
            )
    }
}
