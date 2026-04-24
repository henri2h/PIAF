use freya::prelude::*;
use matrix_sdk::room::edit::EditedContent;
use matrix_sdk::ruma::OwnedEventId;
use matrix_sdk::ruma::events::room::message::{
    RoomMessageEventContent, RoomMessageEventContentWithoutRelation,
};
use matrix_sdk_ui::timeline::TimelineEventItemId;

use crate::utils::use_app_colors;

use super::TimelineHandle;

#[derive(Clone)]
pub struct ComposeBar {
    pub compose_text: State<String>,
    pub edit_info: State<Option<(String, String)>>,
    /// (event_id, sender_name, body_preview)
    pub reply_info: State<Option<(String, String, String)>>,
    pub room_id: String,
    pub timeline: Option<TimelineHandle>,
}

impl PartialEq for ComposeBar {
    fn eq(&self, other: &Self) -> bool {
        self.timeline == other.timeline && self.room_id == other.room_id
    }
}

impl Component for ComposeBar {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let mut compose_text = self.compose_text;
        let mut edit_info = self.edit_info;
        let mut reply_info = self.reply_info;
        let tl = self.timeline.clone();
        let room_id = self.room_id.clone();

        let is_editing = edit_info.read().is_some();
        let is_replying = reply_info.read().is_some();

        let tl_send = tl.clone();
        let tl_edit = tl.clone();
        let room_id_attach = room_id.clone();

        let mut do_send = move || {
            let text = compose_text.read().clone();
            if text.is_empty() {
                return;
            }
            let edit = edit_info.read().clone();
            let reply = reply_info.read().clone();

            if let Some((event_id, _)) = edit {
                // Edit mode
                if let Some(TimelineHandle(timeline)) = tl_edit.clone() {
                    tokio::task::spawn(async move {
                        if let Ok(eid) = OwnedEventId::try_from(event_id.as_str()) {
                            let item_id = TimelineEventItemId::EventId(eid);
                            let content = EditedContent::RoomMessage(
                                RoomMessageEventContent::text_plain(text).into(),
                            );
                            let _ = timeline.edit(&item_id, content).await;
                            let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
                        }
                    });
                }
                *edit_info.write() = None;
            } else if let Some((reply_event_id, _, _)) = reply {
                // Reply mode
                if let Some(TimelineHandle(timeline)) = tl_send.clone() {
                    tokio::task::spawn(async move {
                        if let Ok(eid) = OwnedEventId::try_from(reply_event_id.as_str()) {
                            let content = RoomMessageEventContentWithoutRelation::text_plain(text);
                            let _ = timeline.send_reply(content, eid).await;
                            let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
                        }
                    });
                }
                *reply_info.write() = None;
            } else {
                // New message
                if let Some(TimelineHandle(timeline)) = tl_send.clone() {
                    tokio::task::spawn(async move {
                        use matrix_sdk::ruma::events::AnyMessageLikeEventContent;
                        let content = AnyMessageLikeEventContent::RoomMessage(
                            RoomMessageEventContent::text_plain(text),
                        );
                        let _ = timeline.send(content).await;
                        let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
                    });
                }
            }
            *compose_text.write() = String::new();
        };

        let mut on_submit_btn = do_send.clone();
        let on_submit_enter = move |_| do_send();

        let on_cancel = move |_| {
            if edit_info.read().is_some() {
                *edit_info.write() = None;
                *compose_text.write() = String::new();
            } else {
                *reply_info.write() = None;
            }
        };

        let on_attach = move |_| {
            #[cfg(not(target_os = "android"))]
            {
                let room_id = room_id_attach.clone();
                tokio::task::spawn(async move {
                    use crate::utils::matrix::CLIENT;
                    use matrix_sdk::attachment::AttachmentConfig;
                    use matrix_sdk::ruma::RoomId;

                    let Some(path) = rfd::AsyncFileDialog::new()
                        .add_filter("Images", &["png", "jpg", "jpeg", "gif", "webp"])
                        .pick_file()
                        .await
                    else {
                        return;
                    };

                    let filename = path.file_name();
                    let bytes = path.read().await;
                    let mime: mime::Mime = match std::path::Path::new(&filename)
                        .extension()
                        .and_then(|e| e.to_str())
                        .map(|e| e.to_lowercase())
                        .as_deref()
                    {
                        Some("jpg") | Some("jpeg") => mime::IMAGE_JPEG,
                        Some("png") => mime::IMAGE_PNG,
                        Some("gif") => mime::IMAGE_GIF,
                        Some("webp") => "image/webp"
                            .parse()
                            .unwrap_or(mime::APPLICATION_OCTET_STREAM),
                        _ => mime::APPLICATION_OCTET_STREAM,
                    };

                    let Ok(parsed_id) = RoomId::parse(&room_id) else {
                        return;
                    };
                    let Some(client) = CLIENT.get() else {
                        return;
                    };
                    let Some(room) = client.get_room(&parsed_id) else {
                        return;
                    };

                    let _ = room
                        .send_attachment(&filename, &mime, bytes, AttachmentConfig::default())
                        .await;
                    let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
                });
            } // cfg(not(target_os = "android"))
        };

        let bar = rect().vertical().width(Size::fill()).background(c.surface);
        #[cfg(target_os = "android")]
        let bar = bar.padding(Gaps::new(0., 0., 34., 0.));
        bar
            // ── Context banner: editing or replying ───────────────────────
            .child(if is_editing || is_replying {
                let (icon, label_text, label_color, preview) = if is_editing {
                    (
                        freya_icons::lucide::pencil(),
                        "Editing message",
                        c.primary,
                        None,
                    )
                } else {
                    let (_, sender, body) = reply_info.read().clone().unwrap();
                    (
                        freya_icons::lucide::reply(),
                        "Replying to",
                        c.primary,
                        Some((sender, body)),
                    )
                };
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .padding(Gaps::new(4., 12., 0., 12.))
                    .cross_align(Alignment::Center)
                    .spacing(8.)
                    .child(
                        svg(icon)
                            .color(label_color)
                            .width(Size::px(14.))
                            .height(Size::px(14.)),
                    )
                    .child(if let Some((sender, body)) = preview {
                        rect()
                            .horizontal()
                            .width(Size::fill_minimum())
                            .corner_radius(6.)
                            .background(c.reply_other_bg)
                            .padding(Gaps::new(3., 8., 3., 8.))
                            .spacing(6.)
                            .child(
                                label()
                                    .text(sender)
                                    .font_size(11.)
                                    .font_weight(FontWeight::BOLD)
                                    .color(c.reply_other_sender),
                            )
                            .child(
                                label()
                                    .text(body)
                                    .font_size(11.)
                                    .color(c.reply_other_text)
                                    .max_lines(1),
                            )
                            .into_element()
                    } else {
                        label()
                            .text(label_text)
                            .font_size(12.)
                            .color(label_color)
                            .width(Size::fill_minimum())
                            .into_element()
                    })
                    .child(
                        rect()
                            .center()
                            .width(Size::px(20.))
                            .height(Size::px(20.))
                            .corner_radius(10.)
                            .on_press(on_cancel)
                            .child(
                                svg(freya_icons::lucide::x())
                                    .color(c.on_surface_muted)
                                    .width(Size::px(14.))
                                    .height(Size::px(14.)),
                            ),
                    )
                    .into_element()
            } else {
                rect().into_element()
            })
            // ── Input row ─────────────────────────────────────────────────
            .child(
                rect()
                    .horizontal()
                    .content(Content::Flex)
                    .width(Size::fill())
                    .padding(Gaps::new_all(8.))
                    .spacing(8.)
                    .child(
                        Button::new().on_press(on_attach).child(
                            svg(freya_icons::lucide::paperclip())
                                .color(c.compose_edit_text)
                                .width(Size::px(18.))
                                .height(Size::px(18.)),
                        ),
                    )
                    .child(
                        rect()
                            .width(Size::flex(1.0))
                            .corner_radius(20.)
                            .background(c.surface_container)
                            .padding(Gaps::new(0., 4., 0., 12.))
                            .child(
                                Input::new(compose_text)
                                    .flat()
                                    .placeholder(if is_editing {
                                        "Edit message…"
                                    } else if is_replying {
                                        "Reply…"
                                    } else {
                                        "Message…"
                                    })
                                    .width(Size::fill())
                                    .on_submit(on_submit_enter),
                            ),
                    )
                    .child(
                        Button::new().on_press(move |_| on_submit_btn()).child(
                            svg(if is_editing {
                                freya_icons::lucide::check()
                            } else {
                                freya_icons::lucide::send_horizontal()
                            })
                            .color(if is_editing {
                                c.primary
                            } else {
                                c.compose_text
                            })
                            .width(Size::px(18.))
                            .height(Size::px(18.)),
                        ),
                    ),
            )
    }
}
