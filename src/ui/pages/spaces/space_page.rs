use freya::prelude::*;

use crate::ui::components::{Chip, TopAppBar, empty_state, loading_state};
use crate::ui::pages::home::{Mailbox, RoomFilter, RoomList};
use crate::utils::{spaces, use_app_colors, use_watch};

/// One space's rooms (Android), narrowed by its sub-space chips.
#[derive(PartialEq)]
pub struct SpacePage {
    pub space_id: String,
}

impl Component for SpacePage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let spaces = use_watch(spaces::receiver());
        let mut sub: State<Option<String>> = use_state(|| None);

        let space = spaces
            .read()
            .iter()
            .find(|s| s.room_id == self.space_id)
            .cloned();
        let Some(space) = space else {
            let content = if spaces.read().is_empty() {
                loading_state(None, c).into_element()
            } else {
                empty_state(
                    freya_icons::lucide::layers(),
                    "Space not found",
                    Some("You may have left it"),
                    c,
                )
                .into_element()
            };
            return rect()
                .vertical()
                .expanded()
                .content(Content::Flex)
                .background(c.surface)
                .child(TopAppBar::new("Space"))
                .child(content)
                .into_element();
        };

        let current = sub.read().clone();
        let chips = (!space.subspaces.is_empty()).then(|| {
            let mut chips = rect().horizontal().spacing(6.).child(Chip::new(
                "All",
                current.is_none(),
                move |_| sub.set(None),
            ));
            for s in &space.subspaces {
                let id = s.room_id.clone();
                chips = chips.child(Chip::new(
                    s.name.clone(),
                    current.as_deref() == Some(s.room_id.as_str()),
                    move |_| sub.set(Some(id.clone())),
                ));
            }
            rect()
                .width(Size::fill())
                .height(Size::px(48.))
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
        });

        rect()
            .vertical()
            .expanded()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar::new(space.name.clone()))
            .maybe_child(chips)
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.))
                    .child(RoomList {
                        mailbox: Mailbox::Inbox,
                        filter: RoomFilter::All,
                        filter_bar: None,
                        scope: Some(space.scope(current.as_deref())),
                    }),
            )
            .into_element()
    }
}
