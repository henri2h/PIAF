use freya::prelude::*;

use crate::ROOM_MAILBOX_RX;
use crate::ui::pages::room_mailbox::MailboxRoomList;
use crate::utils::matrix::CLIENT;

#[derive(PartialEq)]
pub struct RecontactPage {}

impl Component for RecontactPage {
    fn render(&self) -> impl IntoElement {
        let tick: State<u64> = use_state(|| 0u64);
        crate::utils::use_tokio_track_watcher(
            ROOM_MAILBOX_RX
                .get()
                .expect("ROOM_MAILBOX_RX not initialized"),
            tick,
        );

        let mailbox = ROOM_MAILBOX_RX
            .get()
            .expect("ROOM_MAILBOX_RX not initialized")
            .borrow()
            .clone();

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
