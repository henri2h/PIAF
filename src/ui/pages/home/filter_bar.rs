use freya::prelude::*;

use super::room_list_model::{Mailbox, RoomFilter};
use crate::ui::components::{Chip, use_color_transition};
use crate::utils::use_app_colors;

/// Height of [`RoomFilterBar`]: the room list leaves this much space at its top.
pub(super) const FILTER_BAR_HEIGHT: f32 = 48.;

/// Mailbox selector (Inbox / Recontact / Archived) followed by the filter
/// chips, which scroll horizontally when they don't fit.
pub struct RoomFilterBar {
    pub mailbox: State<Mailbox>,
    pub filter: State<RoomFilter>,
    /// Tinted surface while the list is scrolled under it.
    pub tinted: bool,
}

impl PartialEq for RoomFilterBar {
    fn eq(&self, other: &Self) -> bool {
        self.mailbox == other.mailbox && self.filter == other.filter && self.tinted == other.tinted
    }
}

impl Component for RoomFilterBar {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let background = use_color_transition(
            if self.tinted {
                c.surface_container
            } else {
                c.surface
            },
            200,
        );
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
        for f in RoomFilter::ALL {
            let selected = *filter.read() == f;
            let mut filter = filter;
            chips = chips.child(Chip::new(f.label(), selected, move |_| {
                filter.set(f.clone())
            }));
        }

        rect()
            .horizontal()
            .width(Size::fill())
            .height(Size::px(FILTER_BAR_HEIGHT))
            .content(Content::Flex)
            .cross_align(Alignment::Center)
            .padding(Gaps::new(0., 16., 0., 16.))
            .spacing(6.)
            .background(background)
            // Android: the mailboxes are pages of the "More" tab.
            .maybe_child((!cfg!(target_os = "android")).then_some(selector))
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
