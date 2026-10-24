use freya::prelude::*;

use super::room_list_model::{Mailbox, RoomFilter};
use crate::ui::components::{Chip, use_color_transition};
use crate::utils::spaces::{self, Selection, Space};
use crate::utils::use_app_colors;

/// Height of one row of [`RoomFilterBar`].
const FILTER_BAR_HEIGHT: f32 = 48.;

/// Height of [`RoomFilterBar`]: the room list leaves this much space at its top.
/// A space with sub-spaces adds a row of their chips.
pub(super) fn filter_bar_height(space: Option<&Space>) -> f32 {
    if space.is_some_and(|s| !s.subspaces.is_empty()) {
        2. * FILTER_BAR_HEIGHT
    } else {
        FILTER_BAR_HEIGHT
    }
}
const FADE_WIDTH: f32 = 24.;

/// Mailbox selector (Inbox / Recontact / Archived) followed by the filter
/// chips, which scroll horizontally when they don't fit.
pub struct RoomFilterBar {
    pub mailbox: State<Mailbox>,
    pub filter: State<RoomFilter>,
    /// Tinted surface while the list is scrolled under it.
    pub tinted: bool,
    /// The selected space (desktop rail) and sub-space: chips for its sub-spaces.
    pub space: Option<Space>,
    pub sub: Option<String>,
}

impl PartialEq for RoomFilterBar {
    fn eq(&self, other: &Self) -> bool {
        self.mailbox == other.mailbox
            && self.filter == other.filter
            && self.tinted == other.tinted
            && self.space == other.space
            && self.sub == other.sub
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
        // Room past the last chip, so the fade never covers it once scrolled.
        let chips = chips.child(rect().width(Size::px(FADE_WIDTH - 6.)));

        let filters = rect()
            .horizontal()
            .width(Size::fill())
            .height(Size::px(FILTER_BAR_HEIGHT))
            .content(Content::Flex)
            .cross_align(Alignment::Center)
            .padding(Gaps::new(0., 16., 0., 16.))
            .spacing(6.)
            // Android: the mailboxes are pages of the "More" tab.
            .maybe_child((!cfg!(target_os = "android")).then_some(selector))
            .child(
                rect()
                    .width(Size::flex(1.))
                    .height(Size::px(FILTER_BAR_HEIGHT))
                    .main_align(Alignment::Center)
                    .child(
                        ScrollView::new()
                            .direction(Direction::Horizontal)
                            .show_scrollbar(false)
                            .width(Size::fill())
                            .height(Size::auto())
                            .child(chips),
                    )
                    // Fades the chips out at the right edge: there are more.
                    .child(
                        rect()
                            .position(Position::new_absolute().top(0.).right(0.))
                            // Above the scroll view, which raises its content.
                            .layer(Layer::Relative(10))
                            .width(Size::px(FADE_WIDTH))
                            .height(Size::px(FILTER_BAR_HEIGHT))
                            .background(
                                LinearGradient::new()
                                    .angle(-90.)
                                    .stop((background.with_a(0), 0.))
                                    .stop((background, 100.)),
                            ),
                    ),
            );

        rect()
            .vertical()
            .width(Size::fill())
            .background(background)
            .maybe_child(
                self.space
                    .as_ref()
                    .filter(|space| !space.subspaces.is_empty())
                    .map(|space| subspace_chips(space, self.sub.as_deref())),
            )
            .child(filters)
    }
}

/// "All" and each sub-space of `space`; picking one narrows the list to it.
fn subspace_chips(space: &Space, sub: Option<&str>) -> Rect {
    let chip = |label: &str, selected: bool, sub: Option<String>| {
        let target = Selection {
            space: Some(space.room_id.clone()),
            sub,
        };
        Chip::new(label, selected, move |_| spaces::select(target.clone()))
            .icon(freya_icons::lucide::layers())
            .into_element()
    };
    let chips = rect()
        .horizontal()
        .spacing(6.)
        .child(chip(&space.name, sub.is_none(), None))
        .children(space.subspaces.iter().map(|s| {
            chip(
                &s.name,
                sub == Some(s.room_id.as_str()),
                Some(s.room_id.clone()),
            )
        }));
    rect()
        .width(Size::fill())
        .height(Size::px(FILTER_BAR_HEIGHT))
        .main_align(Alignment::Center)
        .padding(Gaps::new(0., 16., 0., 16.))
        .child(
            ScrollView::new()
                .direction(Direction::Horizontal)
                .show_scrollbar(false)
                .width(Size::fill())
                .height(Size::auto())
                .child(chips),
        )
}
