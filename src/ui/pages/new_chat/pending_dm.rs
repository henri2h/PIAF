use std::sync::Arc;

use freya::prelude::*;
use freya_router::prelude::RouterContext;

use crate::{
    Route,
    ui::components::{Avatar, TopAppBar, TopAppBarTitle, user_color},
    utils::{matrix::CLIENT, use_app_colors},
};

use super::draft::PENDING_DM;

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

        let text: State<String> = use_state(String::new);
        let mut sending: State<bool> = use_state(|| false);
        let mut error: State<Option<String>> = use_state(|| None);

        // Read display info set by the caller before navigating here.
        let (display_name, avatar_mxc) = PENDING_DM
            .lock()
            .ok()
            .and_then(|g| {
                g.as_ref()
                    .map(|u| (u.display_name.clone(), u.avatar_mxc.clone()))
            })
            .unwrap_or_else(|| (user_id.clone(), None));

        let initial = display_name
            .chars()
            .next()
            .map(|c| c.to_uppercase().to_string())
            .unwrap_or_else(|| "?".to_string());
        let color = user_color(&user_id);

        let is_sending = *sending.read();
        let err_msg = error.read().clone();
        let is_empty = text.read().trim().is_empty();
        let uid_for_key = user_id.clone();

        let mut do_send = move || {
            let msg = text.read().trim().to_string();
            if msg.is_empty() || is_sending {
                return;
            }
            *sending.write() = true;
            *error.write() = None;

            let uid = user_id.clone();
            let (tx, rx) = futures::channel::oneshot::channel::<Result<String, String>>();
            tokio::task::spawn(async move {
                let result: Result<String, String> = async {
                    use matrix_sdk::ruma::RoomId;
                    use matrix_sdk::ruma::events::{
                        AnyMessageLikeEventContent, room::message::RoomMessageEventContent,
                    };

                    let room_id = crate::utils::matrix::create_or_get_dm(uid)
                        .await
                        .ok_or_else(|| "Failed to create DM".to_string())?;
                    let parsed = RoomId::parse(&room_id).map_err(|e| e.to_string())?;
                    let client = CLIENT.get().cloned().ok_or("No client")?;
                    let room = client.get_room(&parsed).ok_or("Room not found")?;
                    let content = AnyMessageLikeEventContent::RoomMessage(
                        RoomMessageEventContent::text_plain(msg),
                    );
                    room.send(content).await.map_err(|e| e.to_string())?;
                    Ok(room_id)
                }
                .await;
                let _ = tx.send(result);
            });
            spawn(async move {
                match rx.await {
                    Ok(Ok(room_id)) => {
                        // Clear stale display info so a future PendingDm opened
                        // via back-navigation can't show the wrong name/avatar.
                        if let Ok(mut pending) = PENDING_DM.lock() {
                            *pending = None;
                        }
                        crate::ui::pages::home::navigate_to_room(room_id);
                    }
                    Ok(Err(e)) => {
                        *error.write() = Some(format!("Error: {e}"));
                        *sending.write() = false;
                    }
                    Err(_) => {
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
                title: TopAppBarTitle::Text(display_name.clone()),
                on_back: Some(Arc::new(|| {
                    let _ = RouterContext::get().push(Route::NewChat);
                })),
                actions: vec![],
            })
            // Recipient header
            .child(
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(24., 16., 16., 16.))
                    .center()
                    .vertical()
                    .spacing(8.)
                    .child(Avatar {
                        size: 64.,
                        bytes: None,
                        fetch_key: avatar_mxc,
                        initial,
                        color,
                        image_key: uid_for_key,
                    })
                    .child(
                        label()
                            .text(display_name)
                            .font_size(17.)
                            .font_weight(FontWeight::MEDIUM)
                            .color(c.on_surface),
                    ),
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
                                svg(freya_icons::lucide::send_horizontal())
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
