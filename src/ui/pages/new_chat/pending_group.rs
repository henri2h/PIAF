use std::sync::Arc;

use freya::prelude::*;
use matrix_sdk::ruma::events::room::message::RoomMessageEventContent;

use super::draft::GROUP_DRAFT;
use super::pending_chat::PendingChat;
use crate::utils::{matrix::CLIENT, use_app_colors};

#[derive(PartialEq)]
pub struct PendingGroup;

impl Component for PendingGroup {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let group_name = GROUP_DRAFT
            .lock()
            .map(|d| d.name.clone())
            .unwrap_or_default();
        let title = if group_name.is_empty() {
            "New group".to_string()
        } else {
            group_name
        };
        let invitees = super::draft::invitees();

        let header = rect()
            .width(Size::fill())
            .padding(Gaps::new(24., 16., 16., 16.))
            .vertical()
            .spacing(12.)
            .child(
                label()
                    .text(title.clone())
                    .font_size(20.)
                    .font_weight(FontWeight::MEDIUM)
                    .color(c.on_surface),
            )
            .child(super::draft::invitee_strip(&invitees, 36., c))
            .into_element();

        PendingChat {
            title,
            header,
            create: Arc::new(|msg| {
                let (room_name, invite_ids, is_encrypted) = GROUP_DRAFT
                    .lock()
                    .map(|d| {
                        let ids: Vec<String> =
                            d.invitees.iter().map(|u| u.user_id.clone()).collect();
                        (d.name.clone(), ids, d.encrypted)
                    })
                    .unwrap_or_else(|_| (String::new(), vec![], true));
                Box::pin(async move {
                    use matrix_sdk::ruma::{
                        UserId,
                        api::client::room::create_room,
                        events::room::encryption::RoomEncryptionEventContent,
                        events::{EmptyStateKey, InitialStateEvent},
                    };

                    let client = CLIENT.get().cloned().ok_or("No client")?;
                    let mut request = create_room::v3::Request::new();
                    request.name = Some(room_name);
                    request.invite = invite_ids
                        .iter()
                        .filter_map(|id| UserId::parse(id).ok())
                        .collect();
                    if is_encrypted {
                        let ev = InitialStateEvent::new(
                            EmptyStateKey,
                            RoomEncryptionEventContent::with_recommended_defaults(),
                        );
                        request.initial_state = vec![ev.to_raw_any()];
                    }
                    let room = client
                        .create_room(request)
                        .await
                        .map_err(|e| e.to_string())?;

                    // Cleared as soon as the room exists: back-navigation can
                    // never create it twice.
                    if let Ok(mut draft) = GROUP_DRAFT.lock() {
                        draft.invitees.clear();
                        draft.name.clear();
                    }

                    // The room exists even if this fails: it can be resent there.
                    let _ = room.send(RoomMessageEventContent::text_plain(msg)).await;
                    Ok(room.room_id().to_string())
                })
            }),
        }
    }
}
