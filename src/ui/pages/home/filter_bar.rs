use freya::prelude::*;

use super::filter_chip::FilterChip;
use super::room_list_model::{Mailbox, RoomFilter};
use crate::utils::use_app_colors;

/// Mailbox selector (Inbox / Recontact / Archived) followed by the filter
/// chips, which scroll horizontally when they don't fit.
pub struct RoomFilterBar {
    pub mailbox: State<Mailbox>,
    pub filter: State<RoomFilter>,
}

impl PartialEq for RoomFilterBar {
    fn eq(&self, _: &Self) -> bool {
        false
    }
}

impl Component for RoomFilterBar {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let filter = self.filter;
        let mut mailbox = self.mailbox;
        let current = *mailbox.read();

        let selector =
            Select::new()
                .selected_item(current.label())
                .children(Mailbox::ALL.iter().map(|&m| {
                    MenuItem::new()
                        .selected(current == m)
                        .on_press(move |_| mailbox.set(m))
                        .child(m.label())
                        .into_element()
                }));

        let mut chips = rect().horizontal().spacing(6.);
        for f in &RoomFilter::ALL {
            let is_selected = *filter.read() == *f;
            chips = chips.child(FilterChip {
                chip_label: f.label(),
                selected: is_selected,
                filter,
                value: f.clone(),
            });
        }

        rect()
            .horizontal()
            .width(Size::fill())
            .content(Content::Flex)
            .cross_align(Alignment::Center)
            .padding(Gaps::new(6., 16., 6., 16.))
            .spacing(6.)
            .background(c.surface)
            .child(selector)
            .child(
                ScrollView::new()
                    .direction(Direction::Horizontal)
                    .show_scrollbar(false)
                    .width(Size::flex(1.))
                    .height(Size::auto())
                    .child(chips),
            )
    }
}
