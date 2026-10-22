use freya::prelude::*;

use crate::ui::components::{
    IconButton, PersonRow, SearchBox, TopAppBar, UserPopupInfo, UserPopupOverlay, badge,
    confirm_dialog,
};
use crate::utils::const_values::AppColors;
use crate::utils::members::{self, ADMIN_LEVEL, MemberItem};
use crate::utils::{on_tokio, use_app_colors};

/// A member: opens the user popup on press, "Admin" badge for admins.
pub(crate) fn member_row(
    m: &MemberItem,
    room_id: &str,
    mut user_popup: State<Option<UserPopupInfo>>,
    c: AppColors,
) -> PersonRow {
    let avatar = m.avatar(room_id);
    let popup = UserPopupInfo {
        user_id: m.user_id.clone(),
        display_name: m.display_name.clone(),
        avatar: Some(avatar.clone()),
    };
    let row = PersonRow::new(&m.user_id, &m.display_name, Some(avatar))
        .on_press(move |_| user_popup.set(Some(popup.clone())));
    if m.is_admin() {
        row.badge(badge("Admin", c))
    } else {
        row
    }
}

#[derive(PartialEq)]
pub struct RoomMembers {
    pub room_id: String,
}

impl Component for RoomMembers {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let room_id = self.room_id.clone();

        let mut members: State<Vec<MemberItem>> = use_state(Vec::new);
        let mut my_power: State<i64> = use_state(|| 0);
        let mut loading = use_state(|| true);
        let mut confirm_remove: State<Option<MemberItem>> = use_state(|| None);
        let search: State<String> = use_state(String::new);
        let user_popup: State<Option<UserPopupInfo>> = use_state(|| None);

        use_hook(|| {
            let room_id = room_id.clone();
            spawn(async move {
                let loaded = on_tokio(async move {
                    let room = crate::utils::matrix::get_room(&room_id)?;
                    let list = members::joined(&room).await;
                    let me = crate::utils::matrix::my_user_id().unwrap_or_default();
                    let power = list
                        .iter()
                        .find(|m| m.user_id == me)
                        .map_or(0, |m| m.power_level);
                    Some((list, power))
                });
                if let Some(Some((list, power))) = loaded.await {
                    members.set(list);
                    my_power.set(power);
                }
                loading.set(false);
            });
        });

        let my_power = *my_power.read();
        let can_kick = my_power >= ADMIN_LEVEL;
        let query = search.read().clone();
        let count = members.read().len();
        let shown: Vec<MemberItem> = members
            .read()
            .iter()
            .filter(|m| query.is_empty() || m.matches(&query))
            .cloned()
            .collect();

        let body = if *loading.read() {
            rect()
                .width(Size::fill())
                .height(Size::flex(1.0))
                .center()
                .child(CircularLoader::new())
                .into_element()
        } else {
            rect()
                .vertical()
                .width(Size::fill())
                .height(Size::flex(1.0))
                .content(Content::Flex)
                .child(
                    rect()
                        .width(Size::fill())
                        .padding(Gaps::new(8., 16., 8., 16.))
                        .child(SearchBox {
                            value: search,
                            placeholder: "Search members…",
                            auto_focus: false,
                        }),
                )
                .child(
                    ScrollView::new()
                        .width(Size::fill())
                        .height(Size::flex(1.0))
                        .children(shown.into_iter().map(|m| {
                            let can_remove = can_kick && m.power_level < my_power;
                            let target = m.clone();
                            let mut row = member_row(&m, &room_id, user_popup, c);
                            if can_remove {
                                row = row.trailing(
                                    IconButton::new(
                                        freya_icons::lucide::user_minus(),
                                        c.error,
                                        move |_| confirm_remove.set(Some(target.clone())),
                                    )
                                    .tooltip("Remove from room")
                                    .size(36., 20.),
                                );
                            }
                            // Keyed by user: unkeyed rows are matched by position.
                            rect()
                                .key(&m.user_id)
                                .width(Size::fill())
                                .child(row)
                                .into_element()
                        })),
                )
                .into_element()
        };

        let remove_sheet = confirm_remove.read().clone().map(|target| {
            let room_id = room_id.clone();
            confirm_dialog(
                format!("Remove {}?", target.display_name),
                "This will kick them from the room.",
                "Remove",
                move || confirm_remove.set(None),
                move || {
                    confirm_remove.set(None);
                    // Gone from the list right away; the kick runs in the background.
                    members.write().retain(|m| m.user_id != target.user_id);
                    let (room_id, user_id) = (room_id.clone(), target.user_id.clone());
                    tokio::spawn(async move {
                        let Ok(user) = matrix_sdk::ruma::UserId::parse(&user_id) else {
                            return;
                        };
                        if let Some(room) = crate::utils::matrix::get_room(&room_id) {
                            let _ = room.kick_user(&user, None).await;
                        }
                    });
                },
            )
        });

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar::new(format!("Members ({count})")))
            .child(body)
            .maybe_child(remove_sheet)
            .child(UserPopupOverlay { open: user_popup })
    }
}
