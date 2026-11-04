use freya::prelude::*;

use super::MailboxRooms;
use crate::ui::pages::home::Mailbox;

/// Rooms in the Archived mailbox.
#[derive(PartialEq)]
pub struct ArchivedPage;

impl Component for ArchivedPage {
    fn render(&self) -> impl IntoElement {
        MailboxRooms {
            mailbox: Mailbox::Archived,
        }
    }
}
