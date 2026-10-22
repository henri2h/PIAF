use freya::prelude::*;

use super::MailboxRooms;
use crate::ui::pages::home::Mailbox;

/// Rooms in the Recontact mailbox.
#[derive(PartialEq)]
pub struct RecontactPage;

impl Component for RecontactPage {
    fn render(&self) -> impl IntoElement {
        MailboxRooms {
            mailbox: Mailbox::Recontact,
        }
    }
}
