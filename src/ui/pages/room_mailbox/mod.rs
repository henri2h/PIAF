use std::sync::Arc;

use freya::prelude::*;
use freya_router::prelude::RouterContext;
use matrix_sdk::Room;

use crate::ui::components::{TopAppBar, TopAppBarTitle};
use crate::ui::pages::home::room_list_item::RoomListItem;
use crate::utils::use_app_colors;

/// Shared list view for the Recontact and Archived pages: a title, back
/// button, and the matching rooms rendered with the normal room-row
/// component.
pub struct MailboxRoomList {
    pub title: &'static str,
    pub empty_title: &'static str,
    pub empty_subtitle: &'static str,
    pub rooms: Vec<Room>,
}

impl PartialEq for MailboxRoomList {
    fn eq(&self, other: &Self) -> bool {
        self.title == other.title
            && self.rooms.len() == other.rooms.len()
            && self
                .rooms
                .iter()
                .zip(other.rooms.iter())
                .all(|(a, b)| a.room_id() == b.room_id())
    }
}

impl Component for MailboxRoomList {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        rect()
            .vertical()
            .expanded()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text(self.title.to_string()),
                on_back: Some(Arc::new(|| {
                    RouterContext::get().go_back();
                })),
                actions: vec![],
            })
            .child(if self.rooms.is_empty() {
                rect()
                    .expanded()
                    .center()
                    .vertical()
                    .spacing(12.)
                    .child(
                        label()
                            .text(self.empty_title)
                            .font_size(16.)
                            .color(c.on_surface_muted),
                    )
                    .child(
                        label()
                            .text(self.empty_subtitle)
                            .font_size(13.)
                            .color(c.on_surface_faint),
                    )
                    .into_element()
            } else {
                let mut scroll = ScrollView::new()
                    .width(Size::fill())
                    .height(Size::flex(1.0));
                for room in self.rooms.clone() {
                    scroll = scroll.child(RoomListItem { room });
                }
                scroll.into_element()
            })
    }
}
