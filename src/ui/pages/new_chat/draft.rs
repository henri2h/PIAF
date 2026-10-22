use std::sync::Mutex;

use crate::utils::users::UserInfo;

pub struct GroupDraft {
    pub invitees: Vec<UserInfo>,
    pub name: String,
    pub encrypted: bool,
}

pub static GROUP_DRAFT: Mutex<GroupDraft> = Mutex::new(GroupDraft {
    invitees: Vec::new(),
    name: String::new(),
    encrypted: true,
});

/// Holds the display info for a pending DM (set before navigating to PendingDm).
pub static PENDING_DM: Mutex<Option<UserInfo>> = Mutex::new(None);

/// People picked for the group being created.
pub fn invitees() -> Vec<UserInfo> {
    GROUP_DRAFT
        .lock()
        .map(|d| d.invitees.clone())
        .unwrap_or_default()
}

/// Row of the picked people: avatar over a short name.
pub fn invitee_strip(
    invitees: &[UserInfo],
    avatar_size: f32,
    c: crate::utils::const_values::AppColors,
) -> freya::prelude::Rect {
    use freya::prelude::*;
    rect()
        .horizontal()
        .width(Size::fill())
        .spacing(12.)
        .children(invitees.iter().map(|user| {
            rect()
                .vertical()
                .spacing(4.)
                .cross_align(Alignment::Center)
                .child(crate::ui::components::Avatar {
                    size: avatar_size,
                    source: user.avatar.clone(),
                    name: user.display_name.clone(),
                    color: crate::utils::id_color(&user.user_id),
                })
                .child(
                    label()
                        .text(user.display_name.chars().take(8).collect::<String>())
                        .font_size(11.)
                        .color(c.on_surface_variant),
                )
                .into_element()
        }))
}
