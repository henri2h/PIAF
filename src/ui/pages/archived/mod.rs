use freya::prelude::*;

use crate::ROOM_MAILBOX_RX;
use crate::ui::pages::room_mailbox::MailboxRoomList;
use crate::utils::matrix::CLIENT;
use crate::utils::room_mailbox::is_archived_hidden;

#[derive(PartialEq)]
pub struct ArchivedPage {}

impl Component for ArchivedPage {
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
                        let archived_until_ts = mailbox
                            .get(r.room_id().as_str())
                            .and_then(|s| s.archived_until_ts);
                        let latest_ts = r.latest_event().timestamp().map(|ts| ts.get().into());
                        archived_until_ts.is_some()
                            && is_archived_hidden(latest_ts, archived_until_ts)
                    })
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
