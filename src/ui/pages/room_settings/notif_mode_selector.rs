use freya::prelude::*;
use matrix_sdk::notification_settings::RoomNotificationMode as Mode;
use matrix_sdk::ruma::RoomId;

use crate::ui::components::{HoverableExt, bottom_sheet};
use crate::utils::{const_values::AppColors, matrix::CLIENT, on_tokio};

/// `None`: follow the account's default setting.
const OPTIONS: [(Option<Mode>, &str, &str); 4] = [
    (None, "Default", "Follow the global notification setting"),
    (
        Some(Mode::AllMessages),
        "All messages",
        "Notify for every message",
    ),
    (
        Some(Mode::MentionsAndKeywordsOnly),
        "Mentions only",
        "Only notify for @mentions and keywords",
    ),
    (Some(Mode::Mute), "Mute", "No notifications"),
];

/// The mode's icon (sheet options and the settings row).
pub(super) fn notif_icon(mode: Option<Mode>) -> bytes::Bytes {
    use freya_icons::lucide;
    match mode {
        None => lucide::bell_dot(),
        Some(Mode::AllMessages) => lucide::bell_ring(),
        Some(Mode::MentionsAndKeywordsOnly) => lucide::at_sign(),
        Some(Mode::Mute) => lucide::bell_off(),
    }
}

pub(super) fn notif_label(mode: Option<Mode>) -> &'static str {
    OPTIONS
        .iter()
        .find(|(m, ..)| *m == mode)
        .map_or("Default", |(_, name, _)| name)
}

/// The room's own notification mode; `None` when it follows the default.
pub(super) async fn load_notif_mode(room_id: String) -> Option<Mode> {
    on_tokio(async move {
        let client = CLIENT.get().cloned()?;
        let room_id = RoomId::parse(&room_id).ok()?;
        let settings = client.notification_settings().await;
        settings
            .get_user_defined_room_notification_mode(&room_id)
            .await
    })
    .await
    .flatten()
}

fn save_notif_mode(room_id: String, mode: Option<Mode>) {
    tokio::spawn(async move {
        let (Some(client), Ok(room_id)) = (CLIENT.get().cloned(), RoomId::parse(&room_id)) else {
            return;
        };
        let settings = client.notification_settings().await;
        let _ = match mode {
            None => settings.delete_user_defined_room_rules(&room_id).await,
            Some(mode) => settings.set_room_notification_mode(&room_id, mode).await,
        };
    });
}

/// Sheet to pick the room's notification mode; updates `mode` right away.
pub(super) fn notif_sheet(
    mut mode: State<Option<Mode>>,
    room_id: String,
    mut open: State<bool>,
    c: AppColors,
) -> Element {
    let current = *mode.read();
    bottom_sheet(c, move || open.set(false))
        .title("Notifications")
        .children(OPTIONS.into_iter().map(|(option, name, desc)| {
            let selected = option == current;
            let room_id = room_id.clone();
            rect()
                .horizontal()
                .width(Size::fill())
                .content(Content::Flex)
                .padding(Gaps::new(12., 24., 12., 24.))
                .cross_align(Alignment::Center)
                .spacing(16.)
                .on_press(move |_| {
                    open.set(false);
                    mode.set(option);
                    save_notif_mode(room_id.clone(), option);
                })
                .child(
                    SvgViewer::new(notif_icon(option))
                        .color(if selected {
                            c.primary
                        } else {
                            c.on_surface_variant
                        })
                        .width(Size::px(22.))
                        .height(Size::px(22.)),
                )
                .child(
                    rect()
                        .vertical()
                        .width(Size::flex(1.))
                        .spacing(2.)
                        .child(
                            label()
                                .text(name)
                                .font_size(15.)
                                .color(c.on_surface)
                                .font_weight(if selected {
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
                .maybe_child(selected.then(|| {
                    SvgViewer::new(freya_icons::lucide::check())
                        .color(c.primary)
                        .width(Size::px(20.))
                        .height(Size::px(20.))
                }))
                .hoverable(Size::fill(), Size::auto(), 0.)
        }))
        .into_element()
}
