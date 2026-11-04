use freya::prelude::*;

use super::{Avatar, IconButton};
use crate::utils::const_values::AppColors;
use crate::utils::id_color;
use crate::utils::users::UserInfo;

/// The people picked so far, as removable chips (avatar, name, ×);
/// `on_remove` gets the user ID.
pub fn picked_users(
    users: &[UserInfo],
    on_remove: impl FnMut(String) + Clone + 'static,
    c: AppColors,
) -> Rect {
    rect()
        .horizontal()
        .width(Size::fill())
        .padding(Gaps::new(0., 16., 8., 16.))
        .spacing(8.)
        .children(users.iter().map(|user| {
            let user_id = user.user_id.clone();
            let mut on_remove = on_remove.clone();
            rect()
                .horizontal()
                .corner_radius(20.)
                .background(c.surface_container)
                .padding(Gaps::new(4., 4., 4., 4.))
                .spacing(6.)
                .cross_align(Alignment::Center)
                .child(Avatar {
                    size: 28.,
                    source: user.avatar.clone(),
                    name: user.display_name.clone(),
                    color: id_color(&user.user_id),
                })
                .child(
                    label()
                        .text(user.display_name.chars().take(12).collect::<String>())
                        .font_size(13.)
                        .color(c.on_surface),
                )
                .child(
                    IconButton::new(freya_icons::lucide::x(), c.on_surface_variant, move |_| {
                        on_remove(user_id.clone())
                    })
                    .tooltip("Remove")
                    .size(28., 14.),
                )
                .into_element()
        }))
}
