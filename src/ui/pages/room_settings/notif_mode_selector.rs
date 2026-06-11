use freya::prelude::*;
use matrix_sdk::notification_settings::RoomNotificationMode;

use crate::utils::{const_values::AppColors, matrix::CLIENT};

const OPTIONS: &[(Option<u8>, &str, &str)] = &[
    (None, "Default", "Follow the global notification setting"),
    (Some(0), "All messages", "Notify for every message"),
    (
        Some(1),
        "Mentions only",
        "Only notify for @mentions and keywords",
    ),
    (Some(2), "Mute", "No notifications"),
];

pub(super) fn notif_popup_overlay(
    current: Option<u8>,
    room_id: String,
    mut open: State<bool>,
    c: AppColors,
) -> Element {
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
                .content(Content::Flex)
                .corner_radius(20.)
                .background(c.surface)
                .vertical()
                .on_press(|e: Event<PressEventData>| e.stop_propagation())
                .child(
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .cross_align(Alignment::Center)
                        .padding(Gaps::new(16., 16., 4., 16.))
                        .child(
                            label()
                                .text("Notifications")
                                .font_size(16.)
                                .font_weight(FontWeight::BOLD)
                                .color(c.on_surface),
                        ),
                )
                .children(OPTIONS.iter().map(|&(val, name, desc)| {
                    let is_selected = val == current;
                    let room_id = room_id.clone();
                    let bg = if is_selected {
                        c.surface_container_high
                    } else {
                        c.surface
                    };

                    rect()
                        .width(Size::fill())
                        .overflow(Overflow::Clip)
                        .on_press(move |_| {
                            *open.write() = false;
                            let room_id = room_id.clone();
                            spawn(async move {
                                let Some(client) = CLIENT.get().cloned() else {
                                    return;
                                };
                                let Ok(parsed_id) = matrix_sdk::ruma::RoomId::parse(&room_id)
                                else {
                                    return;
                                };
                                tokio::task::spawn(async move {
                                    let ns = client.notification_settings().await;
                                    match val {
                                        None => {
                                            let _ =
                                                ns.delete_user_defined_room_rules(&parsed_id).await;
                                        }
                                        Some(0) => {
                                            let _ = ns
                                                .set_room_notification_mode(
                                                    &parsed_id,
                                                    RoomNotificationMode::AllMessages,
                                                )
                                                .await;
                                        }
                                        Some(1) => {
                                            let _ = ns
                                                .set_room_notification_mode(
                                                    &parsed_id,
                                                    RoomNotificationMode::MentionsAndKeywordsOnly,
                                                )
                                                .await;
                                        }
                                        Some(2) => {
                                            let _ = ns
                                                .set_room_notification_mode(
                                                    &parsed_id,
                                                    RoomNotificationMode::Mute,
                                                )
                                                .await;
                                        }
                                        _ => {}
                                    }
                                });
                            });
                        })
                        .child(
                            rect()
                                .horizontal()
                                .width(Size::fill())
                                .padding(Gaps::new(12., 16., 12., 16.))
                                .spacing(12.)
                                .cross_align(Alignment::Center)
                                .background(bg)
                                .child(
                                    rect()
                                        .vertical()
                                        .width(Size::flex(1.0))
                                        .spacing(2.)
                                        .child(
                                            label()
                                                .text(name)
                                                .font_size(15.)
                                                .color(c.on_surface)
                                                .font_weight(if is_selected {
                                                    FontWeight::MEDIUM
                                                } else {
                                                    FontWeight::NORMAL
                                                }),
                                        )
                                        .child(
                                            label()
                                                .text(desc)
                                                .font_size(13.)
                                                .color(c.on_surface_variant),
                                        ),
                                )
                                .maybe_child(is_selected.then(|| {
                                    svg(freya_icons::lucide::check())
                                        .color(c.primary)
                                        .width(Size::px(20.))
                                        .height(Size::px(20.))
                                })),
                        )
                        .into_element()
                }))
                .child(rect().width(Size::fill()).height(Size::px(16.))),
        )
        .into()
}

pub(super) fn notif_label(current: Option<u8>) -> &'static str {
    match current {
        None => "Default",
        Some(0) => "All messages",
        Some(1) => "Mentions only",
        Some(2) => "Mute",
        _ => "Default",
    }
}
