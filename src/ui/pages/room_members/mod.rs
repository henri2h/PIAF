use std::sync::Arc;

use freya::prelude::*;
use freya_material_design::prelude::Ripple;
use freya_router::prelude::RouterContext;
use matrix_sdk::RoomMemberships;
use matrix_sdk::ruma::events::room::power_levels::UserPowerLevel;

use crate::ui::components::{Avatar, TopAppBar, TopAppBarTitle, UserPopupInfo, UserPopupOverlay};
use crate::utils::{sender_color, use_app_colors};
use crate::{Route, utils::matrix::CLIENT};

fn power_to_i64(pl: UserPowerLevel) -> i64 {
    match pl {
        UserPowerLevel::Int(i) => i64::from(i),
        _ => i64::MAX,
    }
}

const ADMIN_THRESHOLD: i64 = 50;

#[derive(Clone, PartialEq)]
struct MemberItem {
    user_id: String,
    display_name: String,
    initial: char,
    color: (u8, u8, u8),
    power_level: i64,
    avatar_url: Option<String>,
}

#[derive(PartialEq)]
pub struct RoomMembers {
    pub room_id: String,
}

impl Component for RoomMembers {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let room_id = self.room_id.clone();
        let room_id_nav = room_id.clone();

        let mut members: State<Vec<MemberItem>> = use_state(|| vec![]);
        let mut my_power: State<i64> = use_state(|| 0i64);
        let mut loading: State<bool> = use_state(|| true);
        let mut confirm_remove: State<Option<MemberItem>> = use_state(|| None);
        let search: State<String> = use_state(String::new);
        let mut user_popup: State<Option<UserPopupInfo>> = use_state(|| None);

        use_hook(|| {
            let room_id = room_id.clone();
            spawn(async move {
                let Some(client) = CLIENT.get().cloned() else {
                    return;
                };
                let (tx, rx) = tokio::sync::oneshot::channel::<(Vec<MemberItem>, i64)>();
                tokio::task::spawn(async move {
                    let Ok(parsed_id) = matrix_sdk::ruma::RoomId::parse(&room_id) else {
                        let _ = tx.send((vec![], 0));
                        return;
                    };
                    let Some(room) = client.get_room(&parsed_id) else {
                        let _ = tx.send((vec![], 0));
                        return;
                    };

                    let my_id = client.user_id().map(|u| u.to_string()).unwrap_or_default();

                    let mut member_list: Vec<MemberItem> = room
                        .members(RoomMemberships::JOIN)
                        .await
                        .unwrap_or_default()
                        .into_iter()
                        .map(|m| {
                            let uid = m.user_id().to_string();
                            let dn = m
                                .display_name()
                                .map(|s| s.to_string())
                                .unwrap_or_else(|| uid.clone());
                            let initial = dn
                                .chars()
                                .next()
                                .unwrap_or('?')
                                .to_uppercase()
                                .next()
                                .unwrap_or('?');
                            let color = sender_color(&uid);
                            let power_level = power_to_i64(m.power_level());
                            let avatar_url = m.avatar_url().map(|u| u.to_string());
                            MemberItem {
                                user_id: uid,
                                display_name: dn,
                                initial,
                                color,
                                power_level,
                                avatar_url,
                            }
                        })
                        .collect();

                    member_list.sort_by(|a, b| {
                        b.power_level
                            .cmp(&a.power_level)
                            .then(a.display_name.cmp(&b.display_name))
                    });

                    let my_power = member_list
                        .iter()
                        .find(|m| m.user_id == my_id)
                        .map(|m| m.power_level)
                        .unwrap_or(0);

                    let _ = tx.send((member_list, my_power));
                });
                if let Ok((list, mp)) = rx.await {
                    *members.write() = list;
                    *my_power.write() = mp;
                }
                *loading.write() = false;
            });
        });

        let member_list = members.read().clone();
        let can_kick = *my_power.read() >= 50;
        let my_pl = *my_power.read();
        let is_loading = *loading.read();
        let search_text = search.read().clone();

        let filtered: Vec<MemberItem> = member_list
            .iter()
            .filter(|m| {
                search_text.is_empty()
                    || m.display_name
                        .to_lowercase()
                        .contains(&search_text.to_lowercase())
                    || m.user_id
                        .to_lowercase()
                        .contains(&search_text.to_lowercase())
            })
            .cloned()
            .collect();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text(format!("Members ({})", member_list.len())),
                on_back: Some(Arc::new(move || {
                    let _ = RouterContext::get().push(Route::RoomSettings {
                        room_id: room_id_nav.clone(),
                    });
                })),
                actions: vec![],
            })
            .child(if is_loading {
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
                            .horizontal()
                            .width(Size::fill())
                            .padding(Gaps::new(8., 16., 8., 16.))
                            .spacing(8.)
                            .cross_align(Alignment::Center)
                            .background(c.surface_container)
                            .child(
                                svg(freya_icons::lucide::search())
                                    .color(c.on_surface_variant)
                                    .width(Size::px(18.))
                                    .height(Size::px(18.)),
                            )
                            .child(
                                Input::new(search.into_writable())
                                    .placeholder("Search members…")
                                    .width(Size::flex(1.0)),
                            ),
                    )
                    .child(
                        ScrollView::new()
                            .width(Size::fill())
                            .height(Size::flex(1.0))
                            .child(
                                rect()
                                    .vertical()
                                    .width(Size::fill())
                                    .children(filtered.into_iter().map(|m| {
                                        let is_admin = m.power_level >= ADMIN_THRESHOLD;
                                        let can_remove = can_kick && m.power_level < my_pl;
                                        let m_for_remove = m.clone();
                                        let fetch_key = m.avatar_url.as_ref().map(|u| format!("mxc:{u}"));
                                        let popup_info = UserPopupInfo {
                                            user_id: m.user_id.clone(),
                                            display_name: m.display_name.clone(),
                                            initial: m.initial.to_string(),
                                            color: m.color,
                                            avatar_url: m.avatar_url.clone(),
                                        };

                                        rect()
                                            .width(Size::fill())
                                            .overflow(Overflow::Clip)
                                            .on_press(move |_| {
                                                *user_popup.write() = Some(popup_info.clone());
                                            })
                                            .child(
                                                Ripple::new()
                                                    .color(c.primary)
                                                    .width(Size::fill())
                                                    .child(
                                                        rect()
                                                            .horizontal()
                                                            .width(Size::fill())
                                                            .padding(Gaps::new(10., 16., 10., 16.))
                                                            .spacing(12.)
                                                            .cross_align(Alignment::Center)
                                                            .child(Avatar {
                                                                size: 40.,
                                                                bytes: None,
                                                                initial: m.initial.to_string(),
                                                                color: m.color,
                                                                image_key: m.user_id.clone(),
                                                                fetch_key,
                                                            })
                                                            .child(
                                                                rect()
                                                                    .vertical()
                                                                    .width(Size::flex(1.0))
                                                                    .spacing(2.)
                                                                    .child(
                                                                        rect()
                                                                            .horizontal()
                                                                            .spacing(6.)
                                                                            .cross_align(Alignment::Center)
                                                                            .child(
                                                                                label()
                                                                                    .text(m.display_name.clone())
                                                                                    .font_size(15.)
                                                                                    .font_weight(FontWeight::MEDIUM)
                                                                                    .color(c.on_surface),
                                                                            )
                                                                            .maybe_child(is_admin.then(|| {
                                                                                rect()
                                                                                    .padding(Gaps::new(2., 6., 2., 6.))
                                                                                    .corner_radius(8.)
                                                                                    .background(c.primary)
                                                                                    .child(
                                                                                        label()
                                                                                            .text("Admin")
                                                                                            .font_size(10.)
                                                                                            .color(c.on_primary),
                                                                                    )
                                                                            })),
                                                                    )
                                                                    .child(
                                                                        label()
                                                                            .text(m.user_id.clone())
                                                                            .font_size(13.)
                                                                            .color(c.on_surface_variant),
                                                                    ),
                                                            )
                                                            .maybe_child(can_remove.then(|| {
                                                                rect()
                                                                    .padding(Gaps::new(4., 4., 4., 4.))
                                                                    .overflow(Overflow::Clip)
                                                                    .corner_radius(20.)
                                                                    .on_press(move |_| {
                                                                        *confirm_remove.write() = Some(m_for_remove.clone());
                                                                    })
                                                                    .child(
                                                                        svg(freya_icons::lucide::user_minus())
                                                                            .color(c.error)
                                                                            .width(Size::px(20.))
                                                                            .height(Size::px(20.)),
                                                                    )
                                                            })),
                                                    ),
                                            )
                                            .into_element()
                                    })),
                            ),
                    )
                    .into_element()
            })
            .maybe_child(confirm_remove.read().clone().map(|target| {
                let target_name = target.display_name.clone();
                let target_id = target.user_id.clone();
                let room_id_kick = room_id.clone();
                rect()
                    .position(Position::new_global().top(0.).left(0.))
                    .layer(Layer::Overlay)
                    .width(Size::window_percent(100.))
                    .height(Size::window_percent(100.))
                    .background((0u8, 0u8, 0u8, 160u8))
                    .on_press(move |_| *confirm_remove.write() = None)
                    .child(
                        rect()
                            .position(Position::new_absolute().bottom(0.).left(0.))
                            .width(Size::fill())
                            .background(c.surface)
                            .vertical()
                            .corner_radius(20.)
                            .padding(Gaps::new(24., 24., 32., 24.))
                            .spacing(16.)
                            .on_press(|_| {})
                            .child(
                                label()
                                    .text(format!("Remove {target_name}?"))
                                    .font_size(18.)
                                    .font_weight(FontWeight::BOLD)
                                    .color(c.on_surface),
                            )
                            .child(
                                label()
                                    .text("This will kick them from the room.")
                                    .font_size(14.)
                                    .color(c.on_surface_variant),
                            )
                            .child(
                                rect()
                                    .horizontal()
                                    .width(Size::fill())
                                    .spacing(12.)
                                    .child(
                                        rect()
                                            .width(Size::flex(1.0))
                                            .padding(Gaps::new(12., 0., 12., 0.))
                                            .corner_radius(8.)
                                            .background(c.surface_container)
                                            .overflow(Overflow::Clip)
                                            .center()
                                            .on_press(move |_| *confirm_remove.write() = None)
                                            .child(label().text("Cancel").font_size(14.).color(c.on_surface)),
                                    )
                                    .child(
                                        rect()
                                            .width(Size::flex(1.0))
                                            .padding(Gaps::new(12., 0., 12., 0.))
                                            .corner_radius(8.)
                                            .background(c.error)
                                            .overflow(Overflow::Clip)
                                            .center()
                                            .on_press(move |_| {
                                                *confirm_remove.write() = None;
                                                let room_id = room_id_kick.clone();
                                                let user_id = target_id.clone();
                                                spawn(async move {
                                                    let Some(client) = CLIENT.get().cloned() else { return };
                                                    tokio::task::spawn(async move {
                                                        let Ok(parsed_room) = matrix_sdk::ruma::RoomId::parse(&room_id) else { return };
                                                        let Ok(parsed_user) = matrix_sdk::ruma::UserId::parse(&user_id) else { return };
                                                        if let Some(room) = client.get_room(&parsed_room) {
                                                            let _ = room.kick_user(&parsed_user, None).await;
                                                        }
                                                    });
                                                });
                                            })
                                            .child(label().text("Remove").font_size(14.).color(c.on_primary)),
                                    ),
                            ),
                    )
                    .into_element()
            }))
            .maybe_child(user_popup.read().clone().map(|info| {
                UserPopupOverlay { info, open: user_popup }.into_element()
            }))
    }
}
