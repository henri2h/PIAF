use freya::prelude::*;
use freya_router::prelude::RouterContext;
use std::sync::Arc;

use crate::{
    Route,
    ui::components::{Avatar, TopAppBar, TopAppBarTitle, user_color},
    utils::{matrix::CLIENT, use_app_colors},
};

use super::draft::GROUP_DRAFT;

#[derive(PartialEq)]
pub struct NewGroupConfig;

impl Component for NewGroupConfig {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let name: State<String> = use_state(String::new);
        let mut encrypted: State<bool> = use_state(|| true);
        let mut creating: State<bool> = use_state(|| false);
        let mut error: State<Option<String>> = use_state(|| None);

        let is_creating = *creating.read();
        let is_encrypted = *encrypted.read();
        let err_msg = error.read().clone();

        let invitee_previews: Vec<(String, String, Option<String>)> = GROUP_DRAFT
            .lock()
            .map(|d| {
                d.invitees
                    .iter()
                    .map(|u| {
                        (
                            u.user_id.clone(),
                            u.display_name.clone(),
                            u.avatar_mxc.clone(),
                        )
                    })
                    .collect()
            })
            .unwrap_or_default();

        let mut do_create = move || {
            let room_name = name.read().trim().to_string();
            if room_name.is_empty() {
                *error.write() = Some("Please enter a group name.".to_string());
                return;
            }
            let invite_ids: Vec<String> = GROUP_DRAFT
                .lock()
                .map(|d| d.invitees.iter().map(|u| u.user_id.clone()).collect())
                .unwrap_or_default();
            if invite_ids.is_empty() {
                *error.write() = Some("No participants selected.".to_string());
                return;
            }
            *creating.write() = true;
            *error.write() = None;
            spawn(async move {
                let Some(client) = CLIENT.get().cloned() else {
                    return;
                };
                let (tx, rx) = futures::channel::oneshot::channel::<Result<String, String>>();
                tokio::task::spawn(async move {
                    let result = (|| async {
                        use matrix_sdk::ruma::{
                            UserId, api::client::room::create_room,
                            events::room::encryption::RoomEncryptionEventContent,
                        };

                        let mut request = create_room::v3::Request::new();
                        request.name = Some(room_name);
                        request.invite = invite_ids
                            .iter()
                            .filter_map(|id| UserId::parse(id).ok())
                            .collect();
                        if is_encrypted {
                            use matrix_sdk::ruma::events::{EmptyStateKey, InitialStateEvent};
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
                        Ok::<String, String>(room.room_id().to_string())
                    })()
                    .await;
                    let _ = tx.send(result);
                });
                match rx.await {
                    Ok(Ok(room_id)) => {
                        if let Ok(mut draft) = GROUP_DRAFT.lock() {
                            draft.invitees.clear();
                            draft.name.clear();
                        }
                        let _ = RouterContext::get().push(Route::RoomPage { room_id });
                    }
                    Ok(Err(e)) => {
                        *error.write() = Some(format!("Error: {e}"));
                    }
                    Err(_) => {}
                }
                *creating.write() = false;
            });
        };

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Group settings".to_string()),
                on_back: Some(Arc::new(|| {
                    let _ = RouterContext::get().push(Route::NewGroup);
                })),
                actions: vec![],
            })
            // Participants recap
            .child(
                rect()
                    .vertical()
                    .width(Size::fill())
                    .padding(Gaps::new(16., 16., 8., 16.))
                    .spacing(8.)
                    .child(
                        label()
                            .text("Participants")
                            .font_size(13.)
                            .color(c.on_surface_muted),
                    )
                    .child({
                        let mut row = rect().horizontal().width(Size::fill()).spacing(12.);
                        for (uid, display_name, avatar_mxc) in &invitee_previews {
                            let initial = display_name
                                .chars()
                                .next()
                                .map(|ch| ch.to_uppercase().to_string())
                                .unwrap_or_else(|| "?".to_string());
                            let color = user_color(uid);
                            row = row.child(
                                rect()
                                    .vertical()
                                    .spacing(4.)
                                    .cross_align(Alignment::Center)
                                    .child(Avatar {
                                        size: 44.,
                                        bytes: None,
                                        fetch_key: avatar_mxc.clone(),
                                        initial,
                                        color,
                                        image_key: uid.clone(),
                                    })
                                    .child(
                                        label()
                                            .text(display_name.chars().take(8).collect::<String>())
                                            .font_size(11.)
                                            .color(c.on_surface_variant),
                                    ),
                            );
                        }
                        row
                    }),
            )
            // Group name
            .child(
                rect()
                    .vertical()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 16., 8., 16.))
                    .spacing(8.)
                    .child(
                        label()
                            .text("Group name")
                            .font_size(13.)
                            .color(c.on_surface_muted),
                    )
                    .child(
                        rect()
                            .width(Size::fill())
                            .corner_radius(8.)
                            .background(c.surface_container)
                            .padding(Gaps::new(0., 4., 0., 12.))
                            .child(
                                Input::new(name)
                                    .flat()
                                    .placeholder("Enter group name…")
                                    .width(Size::fill())
                                    .on_submit(move |_: String| do_create()),
                            ),
                    ),
            )
            // Encryption toggle
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 16., 8., 16.))
                    .content(Content::Flex)
                    .cross_align(Alignment::Center)
                    .child(
                        rect()
                            .vertical()
                            .width(Size::flex(1.0))
                            .spacing(2.)
                            .child(
                                label()
                                    .text("Enable encryption")
                                    .font_size(15.)
                                    .color(c.on_surface),
                            )
                            .child(
                                label()
                                    .text("Messages will be end-to-end encrypted")
                                    .font_size(12.)
                                    .color(c.on_surface_muted),
                            ),
                    )
                    .child(Switch::new().toggled(is_encrypted).on_toggle(move |_| {
                        *encrypted.write() = !*encrypted.read();
                    })),
            )
            // Error message
            .maybe_child(err_msg.map(|msg| {
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(0., 16., 4., 16.))
                    .child(label().text(msg).font_size(13.).color(c.error))
            }))
            // Create button
            .child(
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 16., 16., 16.))
                    .child(
                        Button::new()
                            .on_press(move |_| do_create())
                            .child(if is_creating {
                                "Creating…"
                            } else {
                                "Create group"
                            }),
                    ),
            )
    }
}
