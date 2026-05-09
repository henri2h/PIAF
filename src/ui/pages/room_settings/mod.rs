use std::sync::Arc;

use freya::prelude::*;
use freya_router::prelude::RouterContext;
use matrix_sdk::RoomMemberships;
use matrix_sdk::ruma::events::room::power_levels::UserPowerLevel;

use crate::ui::components::{Avatar, TopAppBar, TopAppBarTitle, UserPopupInfo, UserPopupOverlay};
use crate::utils::{sender_color, use_app_colors};
use crate::{Route, utils::matrix::CLIENT};

mod notif_mode_selector;
use crate::ui::components::m3_list_item;
use crate::utils::extract_urls;
use notif_mode_selector::{notif_label, notif_popup_overlay};

const MEMBER_PREVIEW: usize = 5;
const ADMIN_THRESHOLD: i64 = 50;

fn power_to_i64(pl: UserPowerLevel) -> i64 {
    match pl {
        UserPowerLevel::Int(i) => i64::from(i),
        _ => i64::MAX,
    }
}

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
pub struct RoomSettings {
    pub room_id: String,
}

impl Component for RoomSettings {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let room_id = self.room_id.clone();
        let room_id_nav = room_id.clone();

        let mut room_name: State<String> = use_state(String::new);
        let mut member_count: State<u64> = use_state(|| 0u64);
        let mut members: State<Vec<MemberItem>> = use_state(|| vec![]);
        let mut room_topic: State<Option<String>> = use_state(|| None);
        let mut room_version: State<Option<String>> = use_state(|| None);
        let notif_mode: State<Option<u8>> = use_state(|| None);
        let mut notif_open: State<bool> = use_state(|| false);
        let mut confirm_leave: State<bool> = use_state(|| false);
        let mut user_popup: State<Option<UserPopupInfo>> = use_state(|| None);
        let leaving: State<bool> = use_state(|| false);
        let mut copied: State<bool> = use_state(|| false);

        use_hook(|| {
            let room_id_notif = room_id.clone();
            let mut notif_mode = notif_mode;
            spawn(async move {
                let Some(client) = CLIENT.get().cloned() else {
                    return;
                };
                let (tx, rx) = tokio::sync::oneshot::channel::<Option<u8>>();
                tokio::task::spawn(async move {
                    let Ok(parsed_id) = matrix_sdk::ruma::RoomId::parse(&room_id_notif) else {
                        let _ = tx.send(None);
                        return;
                    };
                    let ns = client.notification_settings().await;
                    let mode = ns.get_user_defined_room_notification_mode(&parsed_id).await;
                    use matrix_sdk::notification_settings::RoomNotificationMode;
                    let v = mode.map(|m| match m {
                        RoomNotificationMode::AllMessages => 0,
                        RoomNotificationMode::MentionsAndKeywordsOnly => 1,
                        RoomNotificationMode::Mute => 2,
                    });
                    let _ = tx.send(v);
                });
                if let Ok(mode) = rx.await {
                    *notif_mode.write() = mode;
                }
            });
        });

        use_hook(|| {
            let room_id = room_id.clone();
            spawn(async move {
                let Some(client) = CLIENT.get().cloned() else {
                    return;
                };
                let (tx, rx) = tokio::sync::oneshot::channel::<(
                    String,
                    u64,
                    Vec<MemberItem>,
                    Option<String>,
                    Option<String>,
                )>();
                tokio::task::spawn(async move {
                    let Ok(parsed_id) = matrix_sdk::ruma::RoomId::parse(&room_id) else {
                        let _ = tx.send((room_id, 0, vec![], None, None));
                        return;
                    };
                    let Some(room) = client.get_room(&parsed_id) else {
                        let _ = tx.send((String::new(), 0, vec![], None, None));
                        return;
                    };
                    let name = room
                        .display_name()
                        .await
                        .map(|n| n.to_string())
                        .unwrap_or_default();
                    let count = room.joined_members_count();
                    let topic = room.topic();
                    let version = room.version().map(|v| v.as_str().to_string());

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

                    let _ = tx.send((name, count, member_list, topic, version));
                });
                if let Ok((name, count, member_list, topic, version)) = rx.await {
                    *room_name.write() = name;
                    *member_count.write() = count;
                    *members.write() = member_list;
                    *room_topic.write() = topic;
                    *room_version.write() = version;
                }
            });
        });

        let name = room_name.read().clone();
        let count = *member_count.read();
        let member_list = members.read().clone();
        let topic = room_topic.read().clone();
        let version = room_version.read().clone();
        let is_leaving = *leaving.read();
        let current_notif = *notif_mode.read();
        let adm_level = ADMIN_THRESHOLD;
        let initial = name
            .chars()
            .next()
            .map(|ch| ch.to_uppercase().to_string())
            .unwrap_or_else(|| "?".to_string());

        let room_id_media = room_id.clone();
        let room_id_members = room_id.clone();
        let room_id_copy = room_id.clone();
        let room_id_leave = room_id.clone();
        let is_wide = crate::WIDE_MODE.load(std::sync::atomic::Ordering::Relaxed);

        let preview_members: Vec<&MemberItem> = member_list.iter().take(MEMBER_PREVIEW).collect();
        let remaining = member_list.len().saturating_sub(MEMBER_PREVIEW);

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Room info".to_string()),
                on_back: Some(Arc::new(move || {
                    if is_wide {
                        let _ = RouterContext::get().push(Route::HomePage);
                    } else {
                        let _ = RouterContext::get().push(Route::RoomPage {
                            room_id: room_id_nav.clone(),
                        });
                    }
                })),
                actions: vec![],
            })
            .child(
                ScrollView::new()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .child(
                        rect()
                            .vertical()
                            .width(Size::fill())
                            // ── Header ────────────────────────────────────────
                            .child(
                                rect()
                                    .vertical()
                                    .cross_align(Alignment::Center)
                                    .spacing(8.)
                                    .width(Size::fill())
                                    .padding(Gaps::new(24., 16., 16., 16.))
                                    .child(Avatar {
                                        size: 80.,
                                        bytes: None,
                                        initial,
                                        color: c.primary,
                                        image_key: room_id.clone(),
                                        fetch_key: Some(room_id.clone()),
                                    })
                                    .child(
                                        label()
                                            .text(name)
                                            .font_size(22.)
                                            .font_weight(FontWeight::MEDIUM)
                                            .color(c.on_surface),
                                    )
                                    .child(
                                        label()
                                            .text(format!("{count} members"))
                                            .font_size(14.)
                                            .color(c.on_surface_variant),
                                    )
                                    .child(if let Some(ref desc) = topic {
                                        let urls = extract_urls(desc);
                                        rect()
                                            .vertical()
                                            .width(Size::fill())
                                            .padding(Gaps::new(4., 0., 0., 0.))
                                            .spacing(4.)
                                            .cross_align(Alignment::Center)
                                            .child(
                                                label()
                                                    .text(desc.clone())
                                                    .font_size(14.)
                                                    .color(c.on_surface_variant)
                                                    .text_align(TextAlign::Center),
                                            )
                                            .children(urls.into_iter().map(|url| {
                                                let url_open = url.clone();
                                                rect()
                                                    .horizontal()
                                                    .spacing(4.)
                                                    .cross_align(Alignment::Center)
                                                    .on_press(move |_| {
                                                        std::process::Command::new("xdg-open")
                                                            .arg(url_open.clone())
                                                            .spawn()
                                                            .ok();
                                                    })
                                                    .child(
                                                        svg(freya_icons::lucide::external_link())
                                                            .color(c.primary)
                                                            .width(Size::px(12.))
                                                            .height(Size::px(12.)),
                                                    )
                                                    .child(
                                                        label()
                                                            .text(url)
                                                            .font_size(13.)
                                                            .color(c.primary),
                                                    )
                                                    .into_element()
                                            }))
                                            .into_element()
                                    } else {
                                        rect().into_element()
                                    }),
                            )
                            // ── Room ID list item ─────────────────────────────
                            .child(m3_list_item(
                                freya_icons::lucide::hash(),
                                "Room ID",
                                Some(room_id.clone()),
                                c.on_surface_variant,
                                false,
                                move |_| {
                                    use freya::prelude::Clipboard;
                                    let _ = Clipboard::set(room_id_copy.clone());
                                    *copied.write() = true;
                                    spawn(async move {
                                        tokio::time::sleep(std::time::Duration::from_secs(2)).await;
                                        *copied.write() = false;
                                    });
                                },
                            ))
                            .child(divider(c))
                            // ── Room version list item ────────────────────────
                            .child(m3_list_item(
                                freya_icons::lucide::info(),
                                "Room version",
                                version,
                                c.on_surface_variant,
                                false,
                                |_| {},
                            ))
                            .child(divider(c))
                            // ── Media ─────────────────────────────────────────
                            .child(m3_list_item(
                                freya_icons::lucide::image(),
                                "Media",
                                None,
                                c.on_surface_variant,
                                false,
                                move |_| {
                                    let _ = RouterContext::get().push(Route::RoomMediaPage {
                                        room_id: room_id_media.clone(),
                                    });
                                },
                            ))
                            .child(divider(c))
                            // ── Notifications ─────────────────────────────────
                            .child(m3_list_item(
                                freya_icons::lucide::bell(),
                                "Notifications",
                                Some(notif_label(current_notif).to_string()),
                                c.on_surface_variant,
                                false,
                                move |_| *notif_open.write() = true,
                            ))
                            .child(divider(c))
                            // ── Members section ───────────────────────────────
                            .child(
                                rect()
                                    .vertical()
                                    .width(Size::fill())
                                    .padding(Gaps::new(16., 16., 4., 16.))
                                    .child(
                                        label()
                                            .text("Members")
                                            .font_size(12.)
                                            .font_weight(FontWeight::MEDIUM)
                                            .color(c.primary),
                                    ),
                            )
                            .children(preview_members.into_iter().map(|m| {
                                let is_admin = m.power_level >= adm_level;
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
                                        *user_popup.write() = Some(popup_info.clone())
                                    })
                                    .child(
                                        rect()
                                            .horizontal()
                                            .width(Size::fill())
                                            .padding(Gaps::new(8., 16., 8., 16.))
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
                                                                    .padding(Gaps::new(
                                                                        2., 6., 2., 6.,
                                                                    ))
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
                                            ),
                                    )
                                    .into_element()
                            }))
                            .child(m3_list_item(
                                freya_icons::lucide::users(),
                                if remaining > 0 {
                                    format!("See all {count} members")
                                } else {
                                    "See all members".to_string()
                                },
                                None,
                                c.on_surface_variant,
                                false,
                                move |_| {
                                    let _ = RouterContext::get().push(Route::RoomMembers {
                                        room_id: room_id_members.clone(),
                                    });
                                },
                            ))
                            .child(divider(c))
                            // ── Leave room ────────────────────────────────────
                            .child(m3_list_item(
                                freya_icons::lucide::log_out(),
                                if is_leaving {
                                    "Leaving…"
                                } else {
                                    "Leave room"
                                },
                                None,
                                c.error,
                                true,
                                move |_| {
                                    if !is_leaving {
                                        *confirm_leave.write() = true;
                                    }
                                },
                            ))
                            .child(rect().width(Size::fill()).height(Size::px(16.))),
                    ),
            )
            // ── Overlays ──────────────────────────────────────────────────────
            .maybe_child(
                (*notif_open.read())
                    .then(|| notif_popup_overlay(current_notif, room_id.clone(), notif_open, c)),
            )
            .maybe_child(
                (*confirm_leave.read()).then(|| {
                    leave_confirm_overlay(room_id_leave.clone(), confirm_leave, leaving, c)
                }),
            )
            .maybe_child(user_popup.read().clone().map(|info| {
                UserPopupOverlay {
                    info,
                    open: user_popup,
                }
                .into_element()
            }))
    }
}

fn divider(c: crate::utils::const_values::AppColors) -> Element {
    rect()
        .width(Size::fill())
        .height(Size::px(1.))
        .background(c.outline_variant)
        .into_element()
}

fn leave_confirm_overlay(
    room_id: String,
    mut open: State<bool>,
    mut leaving: State<bool>,
    c: crate::utils::const_values::AppColors,
) -> Element {
    let room_id_leave = room_id.clone();
    rect()
        .position(Position::new_global().top(0.).left(0.))
        .layer(Layer::Overlay)
        .width(Size::window_percent(100.))
        .height(Size::window_percent(100.))
        .background((0u8, 0u8, 0u8, 160u8))
        .on_press(move |_| *open.write() = false)
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
                        .text("Leave room?")
                        .font_size(18.)
                        .font_weight(FontWeight::BOLD)
                        .color(c.on_surface),
                )
                .child(
                    label()
                        .text("You will leave this room. You can rejoin later if it is public or if you get an invite.")
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
                                .on_press(move |_| *open.write() = false)
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
                                    *open.write() = false;
                                    *leaving.write() = true;
                                    let room_id = room_id_leave.clone();
                                    spawn(async move {
                                        let Some(client) = CLIENT.get().cloned() else { return };
                                        let (tx, rx) = tokio::sync::oneshot::channel::<bool>();
                                        tokio::task::spawn(async move {
                                            let ok = matrix_sdk::ruma::RoomId::parse(&room_id)
                                                .ok()
                                                .and_then(|id| client.get_room(&id))
                                                .map(|room| async move { room.leave().await.is_ok() });
                                            let success = if let Some(fut) = ok { fut.await } else { false };
                                            let _ = tx.send(success);
                                        });
                                        if rx.await.unwrap_or(false) {
                                            let _ = RouterContext::get().push(Route::HomePage);
                                        }
                                        *leaving.write() = false;
                                    });
                                })
                                .child(label().text("Leave").font_size(14.).color(c.on_primary)),
                        ),
                ),
        )
        .into()
}
