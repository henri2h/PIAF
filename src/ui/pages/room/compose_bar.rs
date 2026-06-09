use std::sync::Arc;
use std::time::Duration;

use freya::prelude::*;
use freya::text_edit::*;
use freya_components::cursor_blink::use_cursor_blink;
use tokio::sync::mpsc::UnboundedSender;

use crate::utils::const_values::AppColors;
use crate::utils::matrix::{clear_draft, load_draft, save_draft};
use crate::utils::use_app_colors;

use super::MsgAction;

#[derive(PartialEq)]
struct ComposeLine {
    line_index: usize,
    editable: UseEditable,
    c: AppColors,
    is_focused: bool,
}

impl Component for ComposeLine {
    fn render_key(&self) -> DiffKey {
        (&self.line_index).into()
    }

    fn render(&self) -> impl IntoElement {
        let line_index = self.line_index;
        let mut editable = self.editable;
        let c = self.c;
        let holder = use_state(ParagraphHolder::default);

        let (text, is_active, cursor_index, highlights) = {
            let editor = editable.editor().read();
            let text = editor
                .line(line_index)
                .map(|l| l.text.to_string())
                .unwrap_or_default();
            let is_active = editor.cursor_row() == line_index;
            let cursor_index = if is_active { Some(editor.cursor_col()) } else { None };
            let highlights = editor.get_visible_selection(EditorLine::Paragraph(line_index));
            (text, is_active, cursor_index, highlights)
        };

        // Blink when this line is active and the composer has keyboard focus.
        let (_, cursor_color) =
            use_cursor_blink(is_active && self.is_focused, Color::from(c.compose_edit_text));

        let on_mouse_down = move |e: Event<MouseEventData>| {
            editable.process_event(EditableEvent::Down {
                location: e.element_location,
                editor_line: EditorLine::Paragraph(line_index),
                holder: &holder.read(),
            });
        };

        let on_mouse_move = move |e: Event<MouseEventData>| {
            editable.process_event(EditableEvent::Move {
                location: e.element_location,
                editor_line: EditorLine::Paragraph(line_index),
                holder: &holder.read(),
            });
        };

        paragraph()
            .holder(holder.read().clone())
            .on_mouse_down(on_mouse_down)
            .on_mouse_move(on_mouse_move)
            .cursor_index(cursor_index)
            .cursor_color(cursor_color)
            .highlights(highlights.map(|h| vec![h]))
            .width(Size::fill())
            .font_size(14.)
            .color(c.compose_edit_text)
            .max_lines(1)
            .span(text)
    }
}

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

        // Load draft on mount (skip if we're in edit mode with pre-filled text).
        let room_id_draft = room_id.clone();
        use_hook(move || {
            if initial_text.is_empty() {
                spawn(async move {
                    if let Some(text) = load_draft(&room_id_draft).await {
                        *editor_state.write() = RopeEditor::new(
                            text,
                            TextSelection::new_cursor(0),
                            0,
                            EditorHistory::new(Duration::from_millis(10)),
                        );
                    }
                });
            }
        });

        let is_editing = edit_info.read().is_some();
        let is_replying = reply_info.read().is_some();

        let room_id_attach = room_id.clone();
        let room_id_send = room_id.clone();

        let mut do_send = move || {
            let text = editable.editor().read().rope().to_string();
            let text = text.trim().to_string();
            if text.is_empty() {
                return;
            }
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
                let room_id_clear = room_id_send.clone();
                tokio::task::spawn(async move {
                    clear_draft(&room_id_clear).await;
                });
            }

            // Clear the editable content.
            editable.process_event(EditableEvent::KeyDown {
                key: &Key::Character("a".into()),
                modifiers: Modifiers::CONTROL,
            });
            editable.process_event(EditableEvent::KeyDown {
                key: &Key::Named(NamedKey::Delete),
                modifiers: Modifiers::empty(),
            });
        };

        // Save draft on each content change (debounced).
        use_side_effect(move || {
            if is_editing {
                return;
            }
            let text = editable.editor().read().rope().to_string();
            let room_id = room_id.clone();
            tokio::task::spawn(async move {
                tokio::time::sleep(Duration::from_millis(500)).await;
                save_draft(&room_id, &text).await;
            });
        });

        let mut on_submit_btn = do_send.clone();

        let on_key_down = move |e: Event<KeyboardEventData>| {
            if e.key == Key::Named(NamedKey::Enter) && !e.modifiers.shift() {
                do_send();
            } else {
                editable.process_event(EditableEvent::KeyDown {
                    key: &e.key,
                    modifiers: e.modifiers,
                });
            }
        };

        let on_key_up = move |e: Event<KeyboardEventData>| {
            editable.process_event(EditableEvent::KeyUp { key: &e.key });
        };

        let on_global_pointer_press = move |_: Event<PointerEventData>| {
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
                    .cross_align(Alignment::Center)
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
                            .a11y_id(a11y_id)
                            .a11y_focusable(true)
                            .a11y_role(AccessibilityRole::TextInput)
                            .on_key_down(on_key_down)
                            .on_key_up(on_key_up)
                            .on_global_pointer_press(on_global_pointer_press)
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
                                            .maybe_child(is_empty.then(|| {
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
                                                .into()
                                            })),
                                    ),
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
