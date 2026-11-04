use freya::prelude::*;

use crate::utils::avatars::AvatarSource;

use crate::ui::components::Avatar;
use crate::utils::const_values::AppColors;

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

        rect()
            .vertical()
            .width(Size::fill())
            .cross_align(Alignment::Center)
            .padding(Gaps::new(32., 24., 24., 24.))
            .spacing(12.)
            .child(Avatar {
                size: 80.,
                source: Some(AvatarSource::Room(self.room_id.clone())),
                name: room_name.to_string(),
                color: crate::utils::id_color(&self.room_id),
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
