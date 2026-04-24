use freya::prelude::*;
use freya_query::prelude::{Query, use_query};
use std::time::Duration;

use crate::ui::components::Avatar;
use crate::utils::const_values::AppColors;
use crate::utils::queries::FetchRoomAvatar;

#[derive(PartialEq)]
pub(super) struct RoomStartBanner {
    pub room_id: String,
    pub room_name: String,
    pub c: AppColors,
}

impl Component for RoomStartBanner {
    fn render(&self) -> impl IntoElement {
        let c = self.c;
        let room_name = self.room_name.clone();
        let initial = room_name
            .chars()
            .next()
            .map(|ch| ch.to_uppercase().to_string())
            .unwrap_or_else(|| "?".to_string());

        let avatar_query = use_query(
            Query::new(self.room_id.clone(), FetchRoomAvatar).stale_time(Duration::from_secs(3600)),
        );
        let avatar_bytes = avatar_query.read().state().ok().cloned();

        rect()
            .vertical()
            .width(Size::fill())
            .cross_align(Alignment::Center)
            .padding(Gaps::new(32., 24., 24., 24.))
            .spacing(12.)
            .child(Avatar {
                size: 80.,
                bytes: avatar_bytes,
                initial,
                color: c.primary,
                image_key: format!("room-start-{}", self.room_id),
            })
            .child(
                label()
                    .text(room_name)
                    .font_size(20.)
                    .font_weight(FontWeight::BOLD)
                    .color(c.on_surface),
            )
            .child(
                label()
                    .text("This is the beginning of this conversation.")
                    .font_size(13.)
                    .color(c.on_surface_muted),
            )
    }
}
