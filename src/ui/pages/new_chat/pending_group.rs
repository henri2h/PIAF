use std::sync::Arc;

use freya::prelude::*;

use crate::{
    ui::components::{TopAppBar, TopAppBarTitle},
    utils::{matrix::CLIENT, use_app_colors},
};

use super::draft::GROUP_DRAFT;

#[derive(PartialEq)]
pub struct PendingGroup;

impl Component for PendingGroup {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let text: State<String> = use_state(String::new);
        let mut sending: State<bool> = use_state(|| false);
        let mut error: State<Option<String>> = use_state(|| None);

        let group_name = GROUP_DRAFT
            .lock()
            .map(|d| d.name.clone())
            .unwrap_or_default();
        let invitees = super::draft::invitees();

        let is_sending = *sending.read();
        let err_msg = error.read().clone();
        let is_empty = text.read().trim().is_empty();

        let mut do_send = move || {
            let msg = text.read().trim().to_string();
            if msg.is_empty() || is_sending {
                return;
            }
            *sending.write() = true;
            *error.write() = None;

            let (room_name, invite_ids, is_encrypted) = GROUP_DRAFT
                .lock()
                .map(|d| {
                    let name = d.name.clone();
                    let ids: Vec<String> = d.invitees.iter().map(|u| u.user_id.clone()).collect();
                    (name, ids, d.encrypted)
                })
                .unwrap_or_else(|_| (String::new(), vec![], true));

            let rx = crate::utils::on_tokio::<Result<String, String>, _>(async move {
                let result: Result<String, String> = async {
                    use matrix_sdk::ruma::events::{
                        AnyMessageLikeEventContent, room::message::RoomMessageEventContent,
                    };
                    use matrix_sdk::ruma::{
                        UserId, api::client::room::create_room,
                        events::room::encryption::RoomEncryptionEventContent,
                    };

                    let client = CLIENT.get().cloned().ok_or("No client")?;

                    // Build room creation request
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
                    let room_id = room.room_id().to_string();

                    // Clear the draft as soon as the room is created so back-navigation
                    // can never trigger a duplicate room creation.
                    if let Ok(mut draft) = GROUP_DRAFT.lock() {
                        draft.invitees.clear();
                        draft.name.clear();
                    }

                    // Send the first message. If send fails we still navigate to the
                    // room — it exists and the user can resend from there.
                    let content = AnyMessageLikeEventContent::RoomMessage(
                        RoomMessageEventContent::text_plain(msg),
                    );
                    let _ = room.send(content).await;
                    Ok(room_id)
                }
                .await;
                result
            });
            spawn(async move {
                match rx.await {
                    Some(Ok(room_id)) => {
                        crate::app::navigation::navigate_to_room(room_id);
                    }
                    Some(Err(e)) => {
                        *error.write() = Some(format!("Error: {e}"));
                        *sending.write() = false;
                    }
                    None => {
                        *sending.write() = false;
                    }
                }
            });
        };

        let mut on_submit = do_send.clone();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text(if group_name.is_empty() {
                    "New group".to_string()
                } else {
                    group_name.clone()
                }),
                on_back: Some(Arc::new(crate::app::navigation::go_back_or_home)),
                actions: vec![],
            })
            // Group info header
            .child(
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(24., 16., 16., 16.))
                    .vertical()
                    .spacing(12.)
                    .child(
                        label()
                            .text(if group_name.is_empty() {
                                "New group".to_string()
                            } else {
                                group_name.clone()
                            })
                            .font_size(20.)
                            .font_weight(FontWeight::MEDIUM)
                            .color(c.on_surface),
                    )
                    .child(super::draft::invitee_strip(&invitees, 36., c)),
            )
            // Body hint
            .child(
                rect().expanded().center().child(
                    label()
                        .text("No messages yet")
                        .font_size(14.)
                        .color(c.on_surface_muted),
                ),
            )
            // Error
            .maybe_child(err_msg.map(|msg| {
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(0., 16., 4., 16.))
                    .child(label().text(msg).font_size(13.).color(c.error))
            }))
            // Compose row
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 8., 8., 8.))
                    .content(Content::Flex)
                    .cross_align(Alignment::Center)
                    .spacing(8.)
                    .background(c.surface)
                    .child(
                        rect()
                            .width(Size::flex(1.0))
                            .corner_radius(20.)
                            .background(c.surface_container)
                            .padding(Gaps::new(0., 4., 0., 12.))
                            .child(
                                Input::new(text)
                                    .flat()
                                    .auto_focus(true)
                                    .placeholder("Message")
                                    .width(Size::fill())
                                    .on_submit(move |_: String| on_submit()),
                            ),
                    )
                    .child(
                        Button::new()
                            .on_press(move |_| do_send())
                            .child(if is_sending {
                                rect()
                                    .center()
                                    .width(Size::px(18.))
                                    .height(Size::px(18.))
                                    .child(CircularLoader::new().size(16.))
                                    .into_element()
                            } else {
                                SvgViewer::new(freya_icons::lucide::send_horizontal())
                                    .color(if is_empty {
                                        c.on_surface_muted
                                    } else {
                                        c.primary
                                    })
                                    .width(Size::px(18.))
                                    .height(Size::px(18.))
                                    .into_element()
                            }),
                    ),
            )
    }
}
