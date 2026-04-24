use freya::prelude::*;
use matrix_sdk::notification_settings::RoomNotificationMode;

use crate::utils::{const_values::AppColors, matrix::CLIENT};

pub(super) fn notif_mode_selector(current: Option<u8>, room_id: String, c: AppColors) -> Element {
    const OPTIONS: &[(Option<u8>, &str)] = &[
        (None, "Default"),
        (Some(0), "All"),
        (Some(1), "Mentions"),
        (Some(2), "Mute"),
    ];
    let mut row = rect()
        .horizontal()
        .width(Size::fill())
        .padding(Gaps::new(4., 16., 12., 16.))
        .spacing(8.);
    for &(val, name) in OPTIONS {
        let is_selected = val == current;
        let bg = if is_selected {
            c.primary
        } else {
            c.surface_container
        };
        let text_col = if is_selected {
            c.on_primary
        } else {
            c.on_surface
        };
        let room_id = room_id.clone();
        row = row.child(
            rect()
                .padding(Gaps::new(7., 14., 7., 14.))
                .corner_radius(16.)
                .background(bg)
                .overflow(Overflow::Clip)
                .on_press(move |_| {
                    let room_id = room_id.clone();
                    spawn(async move {
                        let Some(client) = CLIENT.get().cloned() else {
                            return;
                        };
                        let Ok(parsed_id) = matrix_sdk::ruma::RoomId::parse(&room_id) else {
                            return;
                        };
                        tokio::task::spawn(async move {
                            let ns = client.notification_settings().await;
                            match val {
                                None => {
                                    let _ = ns.delete_user_defined_room_rules(&parsed_id).await;
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
                .child(label().text(name).font_size(13.).color(text_col))
                .into_element(),
        );
    }
    row.into_element()
}
