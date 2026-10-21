use std::time::Duration;

use freya::prelude::*;
use freya_query::prelude::*;

use crate::ui::components::{Avatar, StackedAvatar};
use crate::utils::avatars::AvatarSource;
use crate::utils::id_color;
use crate::utils::queries::FetchAvatarMembers;

/// Avatar of a room with neither a picture nor heroes (servers only send
/// heroes for rooms without a name): members with a picture, two stacked or
/// one alone, else the room's initial.
#[derive(PartialEq)]
pub(super) struct MembersAvatar {
    pub room_id: String,
    pub name: String,
    pub size: f32,
    /// Surface behind the row, for the ring between stacked circles.
    pub border_color: (u8, u8, u8),
}

impl Component for MembersAvatar {
    fn render(&self) -> impl IntoElement {
        let members = use_query(
            Query::new(self.room_id.clone(), FetchAvatarMembers)
                .stale_time(Duration::from_secs(600)),
        );
        let members = members.read().state().ok().cloned().unwrap_or_default();
        let size = self.size;
        let source = |avatar: &str| Some(AvatarSource::Mxc(avatar.to_string()));
        match &members[..] {
            [m1, m2, ..] => StackedAvatar {
                size,
                name1: m1.name.clone(),
                color1: id_color(&m1.user_id),
                source1: source(&m1.avatar),
                name2: m2.name.clone(),
                color2: id_color(&m2.user_id),
                source2: source(&m2.avatar),
                border_color: self.border_color,
            }
            .into_element(),
            [m] => Avatar {
                size,
                source: source(&m.avatar),
                name: m.name.clone(),
                color: id_color(&m.user_id),
            }
            .into_element(),
            [] => Avatar {
                size,
                source: None,
                name: self.name.clone(),
                color: id_color(&self.room_id),
            }
            .into_element(),
        }
    }
}
