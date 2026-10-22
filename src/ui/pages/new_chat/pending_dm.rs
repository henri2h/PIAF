use std::sync::Arc;

use freya::prelude::*;
use matrix_sdk::ruma::events::room::message::RoomMessageEventContent;

use super::draft::PENDING_DM;
use super::pending_chat::PendingChat;
use crate::ui::components::Avatar;
use crate::utils::{id_color, use_app_colors};

/// Compose-first DM page: the room is created only when the first message is sent.
/// Display info (name, avatar) is read from PENDING_DM which is set before navigation.
#[derive(Clone, PartialEq)]
pub struct PendingDm {
    pub user_id: String,
}

impl Component for PendingDm {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let user_id = self.user_id.clone();

        // Read display info set by the caller before navigating here.
        let (display_name, avatar) = PENDING_DM
            .lock()
            .ok()
            .and_then(|g| {
                g.as_ref()
                    .map(|u| (u.display_name.clone(), u.avatar.clone()))
            })
            .unwrap_or_else(|| (user_id.clone(), None));

        let header = rect()
            .width(Size::fill())
            .padding(Gaps::new(24., 16., 16., 16.))
            .center()
            .vertical()
            .spacing(8.)
            .child(Avatar {
                size: 64.,
                source: avatar,
                name: display_name.clone(),
                color: id_color(&user_id),
            })
            .child(
                label()
                    .text(display_name.clone())
                    .font_size(17.)
                    .font_weight(FontWeight::MEDIUM)
                    .color(c.on_surface),
            )
            .into_element();

        PendingChat {
            title: display_name,
            header,
            create: Arc::new(move |msg| {
                let user_id = user_id.clone();
                Box::pin(async move {
                    let room_id = crate::utils::matrix::create_or_get_dm(user_id)
                        .await
                        .ok_or("Failed to create DM")?;
                    let room = crate::utils::matrix::get_room(&room_id).ok_or("Room not found")?;
                    room.send(RoomMessageEventContent::text_plain(msg))
                        .await
                        .map_err(|e| e.to_string())?;
                    // A PendingDm reopened by back-navigation can't show stale info.
                    if let Ok(mut pending) = PENDING_DM.lock() {
                        *pending = None;
                    }
                    Ok(room_id)
                })
            }),
        }
    }
}
