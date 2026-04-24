use std::sync::Arc;

use freya::prelude::*;
use freya_material_design::prelude::Ripple;
use freya_router::prelude::RouterContext;
use matrix_sdk::{RoomMemberships, media::MediaFormat};

use crate::ui::components::Avatar;
use crate::ui::components::{TopAppBar, TopAppBarTitle};
use crate::utils::{sender_color, use_app_colors};
use crate::{Route, utils::matrix::CLIENT};

mod m3_list_item;
mod notif_mode_selector;
use m3_list_item::{extract_urls, m3_list_item};
use notif_mode_selector::notif_mode_selector;

#[derive(Clone, PartialEq)]
struct MemberItem {
    user_id: String,
    display_name: String,
    initial: char,
    color: (u8, u8, u8),
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

        let mut avatar: State<Option<Vec<u8>>> = use_state(|| None);
        let mut room_name: State<String> = use_state(String::new);
        let mut member_count: State<u64> = use_state(|| 0u64);
        let mut members: State<Vec<MemberItem>> = use_state(|| vec![]);
        let mut leaving: State<bool> = use_state(|| false);
        let mut room_topic: State<Option<String>> = use_state(|| None);
        let notif_mode: State<Option<u8>> = use_state(|| None);

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
                    Option<Vec<u8>>,
                    u64,
                    Vec<MemberItem>,
                    Option<String>,
                )>();
                tokio::task::spawn(async move {
                    let Ok(parsed_id) = matrix_sdk::ruma::RoomId::parse(&room_id) else {
                        let _ = tx.send((room_id, None, 0, vec![], None));
                        return;
                    };
                    let Some(room) = client.get_room(&parsed_id) else {
                        let _ = tx.send((String::new(), None, 0, vec![], None));
                        return;
                    };
                    let name = room
                        .display_name()
                        .await
                        .map(|n| n.to_string())
                        .unwrap_or_default();
                    let av = room.avatar(MediaFormat::File).await.ok().flatten();
                    let count = room.joined_members_count();
                    let topic = room.topic();

                    let member_list = room
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
                            MemberItem {
                                user_id: uid,
                                display_name: dn,
                                initial,
                                color,
                            }
                        })
                        .collect();

                    let _ = tx.send((name, av, count, member_list, topic));
                });
                if let Ok((name, av, count, member_list, topic)) = rx.await {
                    *room_name.write() = name;
                    *avatar.write() = av;
                    *member_count.write() = count;
                    *members.write() = member_list;
                    *room_topic.write() = topic;
                }
            });
        });

        let avatar_bytes = avatar.read().clone();
        let name = room_name.read().clone();
        let count = *member_count.read();
        let member_list = members.read().clone();
        let topic = room_topic.read().clone();
        let is_leaving = *leaving.read();
        let current_notif = *notif_mode.read();
        let initial = name
            .chars()
            .next()
            .map(|c| c.to_uppercase().to_string())
            .unwrap_or_else(|| "?".to_string());
        let room_id_media = room_id.clone();

        let is_wide = crate::WIDE_MODE.load(std::sync::atomic::Ordering::Relaxed);

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
                            .spacing(0.)
                            .child(
                                rect()
                                    .vertical()
                                    .cross_align(Alignment::Center)
                                    .spacing(8.)
                                    .width(Size::fill())
                                    .padding(Gaps::new(24., 16., 16., 16.))
                                    .child(Avatar {
                                        size: 80.,
                                        bytes: avatar_bytes,
                                        initial,
                                        color: c.primary,
                                        image_key: "room-settings-avatar".to_string(),
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
                            .child({
                                let room_id_copy = room_id.clone();
                                let mut copied: State<bool> = use_state(|| false);
                                rect()
                                    .vertical()
                                    .spacing(2.)
                                    .width(Size::fill())
                                    .padding(Gaps::new(8., 16., 12., 16.))
                                    .on_press(move |_| {
                                        use freya::prelude::Clipboard;
                                        let _ = Clipboard::set(room_id_copy.clone());
                                        *copied.write() = true;
                                        spawn(async move {
                                            tokio::time::sleep(std::time::Duration::from_secs(2))
                                                .await;
                                            *copied.write() = false;
                                        });
                                    })
                                    .child(
                                        rect()
                                            .horizontal()
                                            .spacing(4.)
                                            .cross_align(Alignment::Center)
                                            .child(
                                                label()
                                                    .text("Room ID")
                                                    .font_size(12.)
                                                    .font_weight(FontWeight::MEDIUM)
                                                    .color(c.primary),
                                            )
                                            .child(
                                                svg(if *copied.read() {
                                                    freya_icons::lucide::check()
                                                } else {
                                                    freya_icons::lucide::copy()
                                                })
                                                .color(c.primary)
                                                .width(Size::px(11.))
                                                .height(Size::px(11.)),
                                            ),
                                    )
                                    .child(
                                        label()
                                            .text(room_id.clone())
                                            .font_size(13.)
                                            .color(c.on_surface_variant),
                                    )
                            })
                            .child(
                                rect()
                                    .width(Size::fill())
                                    .height(Size::px(1.))
                                    .background(c.outline_variant),
                            )
                            .child(m3_list_item(
                                freya_icons::lucide::image(),
                                "Media",
                                None,
                                c.on_surface_variant,
                                false,
                                rect()
                                    .width(Size::fill())
                                    .overflow(Overflow::Clip)
                                    .on_press(move |_| {
                                        let _ = RouterContext::get().push(Route::RoomMediaPage {
                                            room_id: room_id_media.clone(),
                                        });
                                    }),
                            ))
                            .child(
                                rect()
                                    .width(Size::fill())
                                    .height(Size::px(1.))
                                    .background(c.outline_variant)
                                    .padding(Gaps::new(0., 16., 0., 72.)),
                            )
                            .child(
                                rect()
                                    .vertical()
                                    .width(Size::fill())
                                    .padding(Gaps::new(12., 16., 4., 16.))
                                    .child(
                                        label()
                                            .text("Notifications")
                                            .font_size(12.)
                                            .font_weight(FontWeight::MEDIUM)
                                            .color(c.primary),
                                    ),
                            )
                            .child(notif_mode_selector(current_notif, room_id.clone(), c))
                            .child(
                                rect()
                                    .width(Size::fill())
                                    .height(Size::px(1.))
                                    .background(c.outline_variant),
                            )
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
                                rect()
                                    .width(Size::fill())
                                    .min_height(Size::px(56.))
                                    .overflow(Overflow::Clip)
                                    .on_press(move |_| {
                                        if is_leaving {
                                            return;
                                        }
                                        let room_id = room_id.clone();
                                        *leaving.write() = true;
                                        spawn(async move {
                                            let Some(client) = CLIENT.get().cloned() else {
                                                return;
                                            };
                                            let (tx, rx) = tokio::sync::oneshot::channel::<bool>();
                                            tokio::task::spawn(async move {
                                                let ok = matrix_sdk::ruma::RoomId::parse(&room_id)
                                                    .ok()
                                                    .and_then(|id| client.get_room(&id))
                                                    .map(|room| async move {
                                                        room.leave().await.is_ok()
                                                    });
                                                let success = if let Some(fut) = ok {
                                                    fut.await
                                                } else {
                                                    false
                                                };
                                                let _ = tx.send(success);
                                            });
                                            if rx.await.unwrap_or(false) {
                                                let _ = RouterContext::get().push(Route::HomePage);
                                            }
                                            *leaving.write() = false;
                                        });
                                    }),
                            ))
                            .child(
                                rect()
                                    .width(Size::fill())
                                    .height(Size::px(1.))
                                    .background(c.outline_variant),
                            )
                            .child(
                                rect()
                                    .vertical()
                                    .width(Size::fill())
                                    .padding(Gaps::new(12., 16., 4., 16.))
                                    .child(
                                        label()
                                            .text("Members")
                                            .font_size(12.)
                                            .font_weight(FontWeight::MEDIUM)
                                            .color(c.primary),
                                    ),
                            )
                            .children(member_list.into_iter().map(|m| {
                                rect()
                                    .width(Size::fill())
                                    .overflow(Overflow::Clip)
                                    .child(
                                        Ripple::new().color(c.primary).width(Size::fill()).child(
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
                                                })
                                                .child(
                                                    rect()
                                                        .vertical()
                                                        .spacing(2.)
                                                        .child(
                                                            label()
                                                                .text(m.display_name)
                                                                .font_size(15.)
                                                                .font_weight(FontWeight::MEDIUM)
                                                                .color(c.on_surface),
                                                        )
                                                        .child(
                                                            label()
                                                                .text(m.user_id)
                                                                .font_size(13.)
                                                                .color(c.on_surface_variant),
                                                        ),
                                                ),
                                        ),
                                    )
                                    .into_element()
                            })),
                    ),
            )
    }
}
