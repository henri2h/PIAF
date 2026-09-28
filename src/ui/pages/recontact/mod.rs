use freya::prelude::*;

use crate::ROOM_MAILBOX_RX;
use crate::ui::pages::room_mailbox::MailboxRoomList;
use crate::utils::matrix::CLIENT;
use crate::utils::use_watch;

#[derive(PartialEq)]
pub struct RecontactPage {}

impl Component for RecontactPage {
    fn render(&self) -> impl IntoElement {
        let mailbox = use_watch(ROOM_MAILBOX_RX.get().expect("not initialized"));
        let mailbox = mailbox.read();

        let rooms = CLIENT
            .get()
            .map(|c| {
                c.joined_rooms()
                    .into_iter()
                    .filter(|r| {
                        mailbox
                            .get(r.room_id().as_str())
                            .is_some_and(|s| s.recontact)
                    })
                    .collect()
            })
            .unwrap_or_default();

        MailboxRoomList {
            title: "Recontact",
            empty_title: "Nothing to recontact",
            empty_subtitle: "Swipe a room and mark it to recontact later",
            rooms,
        }
    }
}
