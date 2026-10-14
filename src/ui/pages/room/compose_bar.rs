use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;

use freya::prelude::*;

use crate::ui::components::IconButton;

use crate::ui::components::use_fading;
use freya::text_edit::*;
use tokio::sync::mpsc::UnboundedSender;

use crate::utils::drafts;
use crate::utils::use_app_colors;

use super::MsgAction;
use super::compose_line::ComposeLine;

const LINE_H: f32 = 22.;
const MAX_LINES: usize = 5;
const V_PAD: f32 = 10.;

#[derive(Clone)]
pub struct ComposeBar {
    pub initial_text: String,
    pub edit_info: State<Option<(String, String)>>,
    pub reply_info: State<Option<(String, String, String)>>,
    pub room_id: String,
    pub action_tx: Arc<UnboundedSender<MsgAction>>,
}

impl PartialEq for ComposeBar {
    fn eq(&self, other: &Self) -> bool {
        Arc::ptr_eq(&self.action_tx, &other.action_tx) && self.room_id == other.room_id
    }
}

impl Component for ComposeBar {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let initial_text = self.initial_text.clone();
        let mut edit_info = self.edit_info;
        let mut reply_info = self.reply_info;
        let action_tx = self.action_tx.clone();
        let room_id = self.room_id.clone();

        let a11y_id = use_a11y();
        let focus = use_focus(a11y_id);
        let mut editable = use_editable(|| initial_text.clone(), EditableConfig::new);
        let mut editor_state = *editable.editor();

        // Restore the draft on mount (not in edit mode, which pre-fills the text).
        let room_id_draft = room_id.clone();
        use_hook(move || {
            if initial_text.is_empty()
                && let Some(text) = drafts::get(&room_id_draft)
            {
                *editor_state.write() = RopeEditor::new(
                    text,
                    TextSelection::new_cursor(0),
                    0,
                    EditorHistory::new(Duration::from_millis(10)),
                );
            }
        });
        // Bumped on every edit and on send; a pending save only runs if still current.
        let draft_gen = use_hook(|| Arc::new(AtomicU64::new(0)));

        let is_editing = edit_info.read().is_some();
        let is_replying = reply_info.read().is_some();
        // Banner above the input: `None` inside while editing, else the reply
        // preview (sender, body). Kept while it fades out.
        let banner = use_fading(
            if is_editing {
                Some(None)
            } else {
                reply_info
                    .read()
                    .clone()
                    .map(|(_, sender, body)| Some((sender, body)))
            },
            150,
        );

        // `i` (keyboard navigation) focuses the composer.
        let compose_focus = *super::ui_ctx::use_room_ui_ctx().compose_focus.read();
        use_side_effect_with_deps(&compose_focus, move |&requests| {
            if requests > 0 {
                a11y_id.request_focus();
            }
        });

        // Opening the room with Enter from the list focuses the composer.
        let key_nav = crate::app::keys::use_key_nav();
        use_side_effect(move || {
            let Some(nav) = key_nav else { return };
            let mut pending = nav.focus_composer;
            if *pending.read() {
                pending.set(false);
                a11y_id.request_focus();
            }
        });

        // Auto-focus the compose bar when reply or edit mode is activated.
        let focus_trigger = is_replying || is_editing;
        use_side_effect_with_deps(&focus_trigger, move |&active| {
            if active {
                a11y_id.request_focus();
            }
        });

        // Paste-image state: pending holds the PNG bytes awaiting send.
        let mut paste_pending: State<Option<Vec<u8>>> = use_state(|| None);
        let mut paste_sending: State<bool> = use_state(|| false);

        #[cfg(not(target_os = "android"))]
        let room_id_attach = room_id.clone();
        let room_id_send = room_id.clone();
        let draft_gen_send = draft_gen.clone();

        let mut do_send = move || {
            let text = editable.editor().read().rope().to_string();
            let text = text.trim().to_string();
            let paste = paste_pending.read().clone();

            if text.is_empty() && paste.is_none() {
                return;
            }

            // Send text message if there is any.
            if !text.is_empty() {
                let edit = edit_info.read().clone();
                let reply = reply_info.read().clone();

                if let Some((event_id, _)) = edit {
                    let _ = action_tx.send(MsgAction::Edit { event_id, text });
                    *edit_info.write() = None;
                } else if let Some((reply_event_id, _, _)) = reply {
                    let _ = action_tx.send(MsgAction::Reply {
                        reply_event_id,
                        text,
                    });
                    *reply_info.write() = None;
                } else {
                    let _ = action_tx.send(MsgAction::Send { text });
                    draft_gen_send.fetch_add(1, Ordering::Relaxed);
                    drafts::clear(&room_id_send);
                }

                editable.process_event(EditableEvent::KeyDown {
                    key: &Key::Character("a".into()),
                    modifiers: Modifiers::CONTROL,
                    editor_line: None,
                    holder: None,
                });
                editable.process_event(EditableEvent::KeyDown {
                    key: &Key::Named(NamedKey::Delete),
                    modifiers: Modifiers::empty(),
                    editor_line: None,
                    holder: None,
                });
            }

            // Upload pasted image if there is one.
            if let Some(png_bytes) = paste {
                *paste_pending.write() = None;
                *paste_sending.write() = true;
                let room_id = room_id_send.clone();
                let done = crate::utils::on_tokio(async move {
                    crate::utils::media::send_attachment(
                        &room_id,
                        "paste.png",
                        &mime::IMAGE_PNG,
                        png_bytes,
                    )
                    .await;
                });
                spawn(async move {
                    done.await;
                    *paste_sending.write() = false;
                });
            }
        };

        let room_id_banner = room_id.clone();

        // Save the draft 500ms after the last edit.
        use_side_effect(move || {
            if is_editing {
                return;
            }
            let text = editable.editor().read().rope().to_string();
            let room_id = room_id.clone();
            let draft_gen = draft_gen.clone();
            let generation = draft_gen.fetch_add(1, Ordering::Relaxed) + 1;
            tokio::task::spawn(async move {
                tokio::time::sleep(Duration::from_millis(500)).await;
                if draft_gen.load(Ordering::Relaxed) == generation {
                    drafts::set(&room_id, &text);
                }
            });
        });

        let mut on_submit_btn = do_send.clone();

        let on_key_down = move |e: Event<KeyboardEventData>| {
            // Esc cancels a reply or edit first, then leaves the composer
            // so keyboard navigation works again.
            if e.key == Key::Named(NamedKey::Escape) {
                if edit_info.peek().is_some() {
                    edit_info.set(None);
                } else if reply_info.peek().is_some() {
                    reply_info.set(None);
                } else {
                    a11y_id.request_unfocus();
                }
                return;
            }
            if e.key == Key::Named(NamedKey::Enter) && !e.modifiers.shift() {
                do_send();
            } else {
                // Let the editable handle the key normally (text paste, etc.).
                editable.process_event(EditableEvent::KeyDown {
                    key: &e.key,
                    modifiers: e.modifiers,
                    editor_line: None,
                    holder: None,
                });
                // On Ctrl+V, check clipboard for an image and stage it for sending.
                #[cfg(not(target_os = "android"))]
                if e.key == Key::Character("v".into()) && e.modifiers.ctrl() {
                    if let Some(png) = crate::utils::clipboard::read_image() {
                        *paste_pending.write() = Some(png);
                    }
                }
            }
        };

        let on_key_up = move |e: Event<KeyboardEventData>| {
            editable.process_event(EditableEvent::KeyUp { key: &e.key });
        };

        let on_global_pointer_up = move |_: Event<PointerEventData>| {
            editable.process_event(EditableEvent::Release);
        };

        let on_cancel = move |_| {
            if edit_info.read().is_some() {
                *edit_info.write() = None;
            } else {
                *reply_info.write() = None;
            }
        };

        let on_attach = move |_| {
            #[cfg(not(target_os = "android"))]
            {
                let room_id = room_id_attach.clone();
                tokio::spawn(async move {
                    use crate::utils::media;
                    if let Some(image) = media::pick_image("Send an image").await {
                        media::send_attachment(
                            &room_id,
                            &image.file_name,
                            &image.mime,
                            image.bytes,
                        )
                        .await;
                    }
                });
            }
        };

        let line_count = editable.editor().read().len_lines().max(1);
        let inner_h = (line_count as f32 * LINE_H).min(MAX_LINES as f32 * LINE_H);
        let is_empty = editable.editor().read().rope().len_chars() == 0;
        let is_focused = focus().is_focused();

        let bar = rect().vertical().width(Size::fill()).background(c.surface);
        #[cfg(target_os = "android")]
        let bar = bar.padding(Gaps::new(0., 0., 34., 0.));
        bar
            // ── Context banner: editing or replying ───────────────────────
            .child(if let Some((preview, opacity)) = banner {
                let (icon, label_text, label_color) = match preview {
                    None => (freya_icons::lucide::pencil(), "Editing message", c.primary),
                    Some(_) => (freya_icons::lucide::reply(), "Replying to", c.primary),
                };
                rect()
                    .opacity(opacity)
                    .horizontal()
                    .width(Size::fill())
                    .content(Content::Flex)
                    .padding(Gaps::new(8., 12., 0., 12.))
                    .cross_align(Alignment::Center)
                    .spacing(10.)
                    .child(
                        SvgViewer::new(icon)
                            .color(label_color)
                            .width(Size::px(18.))
                            .height(Size::px(18.)),
                    )
                    .child(if let Some((sender, body)) = preview {
                        rect()
                            .horizontal()
                            .width(Size::flex(1.))
                            .content(Content::Flex)
                            .corner_radius(8.)
                            .overflow(Overflow::Clip)
                            .background(c.reply_other_bg)
                            .border(
                                Border::new()
                                    .fill(c.reply_other_sender)
                                    .width(BorderWidth {
                                        top: 0.,
                                        right: 0.,
                                        bottom: 0.,
                                        left: 3.,
                                    })
                                    .alignment(BorderAlignment::Inner),
                            )
                            .child(
                                rect()
                                    .vertical()
                                    .width(Size::flex(1.))
                                    .padding(Gaps::new(6., 10., 6., 10.))
                                    .spacing(2.)
                                    .child(
                                        label()
                                            .text(format!("{label_text} {sender}"))
                                            .font_size(12.)
                                            .font_weight(FontWeight::BOLD)
                                            .color(c.reply_other_sender)
                                            .max_lines(1),
                                    )
                                    .child(
                                        label()
                                            .width(Size::fill())
                                            .text(body)
                                            .font_size(13.)
                                            .color(c.reply_other_text)
                                            .max_lines(2)
                                            .text_overflow(TextOverflow::Ellipsis),
                                    ),
                            )
                            .into_element()
                    } else {
                        label()
                            .text(label_text)
                            .font_size(13.)
                            .color(label_color)
                            .width(Size::flex(1.))
                            .into_element()
                    })
                    .child(
                        IconButton::new(freya_icons::lucide::x(), c.on_surface_variant, on_cancel)
                            .tooltip("Cancel (Esc)")
                            .size(32., 18.),
                    )
                    .into_element()
            } else {
                rect().into_element()
            })
            // ── Paste-image banner: pending preview or sending spinner ─────
            .child({
                let is_sending = *paste_sending.read();
                let pending = paste_pending.read().clone();
                let room_key = room_id_banner.clone();
                if is_sending {
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .padding(Gaps::new(4., 12., 0., 12.))
                        .cross_align(Alignment::Center)
                        .spacing(8.)
                        .child(CircularLoader::new().size(16.))
                        .child(
                            label()
                                .text("Sending image…")
                                .font_size(12.)
                                .color(c.on_surface_muted),
                        )
                        .into_element()
                } else if let Some(png_bytes) = pending {
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .padding(Gaps::new(4., 12., 0., 12.))
                        .cross_align(Alignment::Center)
                        .spacing(8.)
                        .child(
                            rect()
                                .width(Size::px(44.))
                                .height(Size::px(44.))
                                .corner_radius(4.)
                                .overflow(Overflow::Clip)
                                .child(
                                    ImageViewer::new((
                                        format!("paste-{room_key}"),
                                        bytes::Bytes::from(png_bytes),
                                    ))
                                    .width(Size::fill())
                                    .height(Size::fill())
                                    .aspect_ratio(AspectRatio::Max)
                                    .image_cover(ImageCover::Center),
                                ),
                        )
                        .child(
                            label()
                                .text("Image ready to send")
                                .font_size(12.)
                                .color(c.on_surface_muted)
                                .width(Size::fill_minimum()),
                        )
                        .child(
                            IconButton::new(
                                freya_icons::lucide::x(),
                                c.on_surface_muted,
                                move |_| {
                                    *paste_pending.write() = None;
                                },
                            )
                            .size(20., 14.)
                            .into_element(),
                        )
                        .into_element()
                } else {
                    rect().into_element()
                }
            })
            // ── Input row ─────────────────────────────────────────────────
            .child(
                rect()
                    .horizontal()
                    .content(Content::Flex)
                    .width(Size::fill())
                    .padding(Gaps::new_all(8.))
                    .cross_align(Alignment::Center)
                    .spacing(8.)
                    .child(
                        Button::new().on_press(on_attach).child(
                            SvgViewer::new(freya_icons::lucide::paperclip())
                                .color(c.compose_edit_text)
                                .width(Size::px(18.))
                                .height(Size::px(18.)),
                        ),
                    )
                    .child(
                        rect()
                            .a11y_id(a11y_id)
                            .a11y_focusable(true)
                            .a11y_role(AccessibilityRole::TextInput)
                            .on_key_down(on_key_down)
                            .on_key_up(on_key_up)
                            .on_global_pointer_up(on_global_pointer_up)
                            .on_pointer_down(move |_| a11y_id.request_focus())
                            .width(Size::flex(1.0))
                            .height(Size::px(inner_h + V_PAD * 2.))
                            .corner_radius(20.)
                            .background(c.surface_container)
                            .maybe(is_focused, |el| {
                                el.border(
                                    Border::new()
                                        .fill(c.primary)
                                        .width(2.)
                                        .alignment(BorderAlignment::Outer),
                                )
                            })
                            .overflow(Overflow::Clip)
                            .child(
                                ScrollView::new()
                                    .width(Size::fill())
                                    .height(Size::fill())
                                    .child(
                                        rect()
                                            .vertical()
                                            .width(Size::fill())
                                            .padding(Gaps::new(V_PAD, 16., V_PAD, 16.))
                                            // Placeholder is hidden once the bar is focused
                                            // so the cursor and placeholder never overlap.
                                            .maybe_child((is_empty && !is_focused).then(|| {
                                                label()
                                                    .text(if is_editing {
                                                        "Edit message"
                                                    } else if is_replying {
                                                        "Reply"
                                                    } else {
                                                        "Message"
                                                    })
                                                    .font_size(14.)
                                                    .color(c.on_surface_muted)
                                                    .into_element()
                                            }))
                                            .children((0..line_count).map(|i| {
                                                ComposeLine {
                                                    line_index: i,
                                                    editable,
                                                    c,
                                                    is_focused,
                                                }
                                                .into_element()
                                            })),
                                    ),
                            ),
                    )
                    .child(
                        Button::new().on_press(move |_| on_submit_btn()).child(
                            SvgViewer::new(if is_editing {
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
