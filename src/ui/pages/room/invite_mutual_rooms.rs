use freya::prelude::*;
use freya_query::prelude::*;
use matrix_sdk::RoomState;

use crate::ui::components::{Avatar, ListItem};
use crate::utils::avatars::AvatarSource;
use crate::utils::matrix::get_room;
use crate::utils::queries::FetchMutualRooms;
use crate::utils::{id_color, use_app_colors};

/// Rooms we already share with the person inviting us to a DM, so the invite
/// can be told apart from spam. Nothing when there are none.
#[derive(PartialEq)]
pub(super) struct InviteMutualRooms {
    /// The DM we're invited to (it's left out).
    pub room_id: String,
    pub user_id: String,
}

impl Component for InviteMutualRooms {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let query = use_query(Query::new(self.user_id.clone(), FetchMutualRooms));
        let ids = query.read().state().ok().cloned().unwrap_or_default();

        let rooms: Vec<_> = ids
            .iter()
            .filter(|id| **id != self.room_id)
            .filter_map(|id| get_room(id))
            .filter(|room| room.state() == RoomState::Joined)
            .collect();
        if rooms.is_empty() {
            return rect().into_element();
        }

        let title = if rooms.len() == 1 {
            "1 room in common".to_string()
        } else {
            format!("{} rooms in common", rooms.len())
        };
        rect()
            .vertical()
            .width(Size::fill())
            .margin(Gaps::new(8., 0., 0., 0.))
            .child(
                label()
                    .text(title)
                    .font_size(13.)
                    .font_weight(FontWeight::MEDIUM)
                    .color(c.on_surface_variant)
                    .margin(Gaps::new(0., 0., 4., 4.)),
            )
            .children(rooms.into_iter().map(|room| {
                let room_id = room.room_id().to_string();
                let name = room
                    .cached_display_name()
                    .map(|n| n.to_string())
                    .unwrap_or_else(|| room_id.clone());
                let members = room.joined_members_count();
                rect()
                    .key(&room_id)
                    .width(Size::fill())
                    .child(
                        ListItem::new(name.clone())
                            .supporting(if members == 1 {
                                "1 member".to_string()
                            } else {
                                format!("{members} members")
                            })
                            .leading(Avatar {
                                size: 40.,
                                source: Some(AvatarSource::Room(room_id.clone())),
                                name,
                                color: id_color(&room_id),
                            }),
                    )
                    .into_element()
            }))
            .into_element()
    }
}
