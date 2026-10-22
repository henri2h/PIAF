mod archived;
mod recontact;

pub use archived::ArchivedPage;
pub use recontact::RecontactPage;

use freya::prelude::*;

use crate::ui::components::TopAppBar;
use crate::ui::pages::home::{Mailbox, RoomFilter, RoomList};
use crate::utils::use_app_colors;

/// One mailbox's rooms (Android "More" tab): app bar, then the room list
/// without its filter bar.
#[derive(PartialEq)]
pub struct MailboxRooms {
    pub mailbox: Mailbox,
}

impl Component for MailboxRooms {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        rect()
            .vertical()
            .expanded()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar::new(self.mailbox.label().to_string()))
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.))
                    .child(RoomList {
                        mailbox: self.mailbox,
                        filter: RoomFilter::All,
                        filter_bar: None,
                    }),
            )
    }
}
