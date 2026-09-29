use freya::prelude::*;

use crate::ROOM_MAILBOX_RX;
use crate::ui::pages::room_mailbox::MailboxRoomList;
use crate::utils::matrix::CLIENT;
use crate::utils::room_mailbox::is_room_archived;
use crate::utils::use_watch;

#[derive(PartialEq)]
pub struct ArchivedPage {}

impl Component for ArchivedPage {
    fn render(&self) -> impl IntoElement {
        let mailbox = use_watch(ROOM_MAILBOX_RX.get().expect("not initialized"));
        let mailbox = mailbox.read();

        let rooms = CLIENT
            .get()
            .map(|c| {
                c.joined_rooms()
                    .into_iter()
                    .filter(|r| is_room_archived(r, &mailbox))
                    .collect()
            })
            .unwrap_or_default();

        MailboxRoomList {
            title: "Archived",
            empty_title: "Nothing archived",
            empty_subtitle: "Swipe a room away once you're done with it",
            rooms,
        }
    }
}
