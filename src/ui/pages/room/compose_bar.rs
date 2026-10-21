use std::cell::RefCell;
use std::rc::Rc;
use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;

use freya::prelude::*;

use crate::ui::components::{IconButton, ListItem, bottom_sheet};

use crate::ui::components::{use_fade, use_fading};
use freya::text_edit::*;
use tokio::sync::mpsc::UnboundedSender;

use crate::utils::drafts;
use crate::utils::haptics::{self, Haptic};
use crate::utils::ime::{self, ImeKind};
use crate::utils::ime_edit::{Composing, apply_ime_event, finish_composition};
use crate::utils::media::{self, AttachSource};
use crate::utils::on_tokio;
use crate::utils::use_app_colors;

use super::MsgAction;
use super::compose_line::ComposeLine;

const LINE_H: f32 = 24.;
const MAX_LINES: usize = 5;
/// Above and below the text: one line makes a 48px pill.
const V_PAD: f32 = 12.;

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
        let touch = use_touch_edit();
        // The soft keyboard's word in progress (Android): a UTF-16 range of the text.
        let preedit: Composing = use_hook(|| Rc::new(RefCell::new(None)));
        let line_heights: State<Vec<f32>> = use_state(Vec::new);
        let scroll = use_scroll_controller(ScrollConfig::default);
        let mut editable = use_editable(String::new, EditableConfig::new);
        let mut editor_state = *editable.editor();

        // On mount: the message being edited, else the draft, with the cursor
        // at the end to continue typing (positions are UTF-16 code units).
        let room_id_draft = room_id.clone();
        use_hook(move || {
            let text = if initial_text.is_empty() {
                drafts::get(&room_id_draft)
            } else {
                Some(initial_text)
            };
            if let Some(text) = text {
                let end = text.encode_utf16().count();
                *editor_state.write() = RopeEditor::new(
                    text,
                    TextSelection::new_cursor(end),
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
        // Android: the attach sheet (gallery, camera, file).
        let mut attach_sheet = use_state(|| false);

        let room_id_attach = room_id.clone();
        let room_id_send = room_id.clone();
        let draft_gen_send = draft_gen.clone();

        let preedit_send = preedit.clone();
        let mut do_send = move || {
            finish_composition(&preedit_send);
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

        let preedit_keys = preedit.clone();
        let on_key_down = move |e: Event<KeyboardEventData>| {
            finish_composition(&preedit_keys);
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
            touch.show_menu(false);
            // The key only, never the typed text.
            tracing::debug!(
                target: "piaf::composer",
                key = match &e.key {
                    Key::Character(c) => format!("char({} chars)", c.chars().count()),
                    key => format!("{key:?}"),
                },
                "key down",
            );
            // On a touch keyboard Enter starts a new line; the send button sends.
            if e.key == Key::Named(NamedKey::Enter)
                && !e.modifiers.shift()
                && !cfg!(target_os = "android")
            {
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

        let on_global_pointer_up = move |e: Event<PointerEventData>| {
            editable.process_event(EditableEvent::Release);
            if matches!(*e, PointerEventData::Touch(_)) {
                touch.touch_end(editable.editor().peek().has_any_selection());
            }
        };

        let on_cancel = move |_| {
            if edit_info.read().is_some() {
                *edit_info.write() = None;
            } else {
                *reply_info.write() = None;
            }
        };

        // Picks a file from `source` and sends it, the banner showing meanwhile.
        let send_picked = move |source: AttachSource| {
            let room_id = room_id_attach.clone();
            spawn(async move {
                let picked = on_tokio(media::pick_attachment(source)).await.flatten();
                let Some(file) = picked else { return };
                paste_sending.set(true);
                on_tokio(async move {
                    media::send_attachment(&room_id, &file.file_name, &file.mime, file.bytes).await
                })
                .await;
                paste_sending.set(false);
            });
        };
        let send_picked_desktop = send_picked.clone();
        let on_attach = move |_| {
            if cfg!(target_os = "android") {
                // The keyboard would cover the sheet: the composer lets go of it.
                a11y_id.request_unfocus();
                attach_sheet.set(true);
            } else {
                send_picked_desktop(AttachSource::File);
            }
        };

        let line_count = editable.editor().read().len_lines().max(1);
        // Measured heights: a long line wraps over several rows.
        let content_h: f32 = (0..line_count)
            .map(|i| {
                line_heights
                    .read()
                    .get(i)
                    .copied()
                    .filter(|h| *h > 0.)
                    .unwrap_or(LINE_H)
            })
            .sum();
        let inner_h = content_h.min(MAX_LINES as f32 * LINE_H);
        let is_empty = editable.editor().read().rope().len_chars() == 0;
        // Past `MAX_LINES` the text scrolls: keep the cursor in view as it moves.
        use_side_effect(move || {
            let editor = editable.editor().read();
            let heights = line_heights.read();
            let row = editor.cursor_row();
            let row_len = editor.line(row).map(|l| l.utf16_len()).unwrap_or(0);
            let fraction = if row_len == 0 {
                0.
            } else {
                editor.cursor_col() as f32 / row_len as f32
            };
            let height = |i: usize| {
                heights
                    .get(i)
                    .copied()
                    .filter(|h| *h > 0.)
                    .unwrap_or(LINE_H)
            };
            let content: f32 = (0..editor.len_lines().max(1)).map(height).sum();
            let viewport = content.min(MAX_LINES as f32 * LINE_H);
            // The cursor's row inside a wrapped line, estimated from its column.
            let line_top: f32 = (0..row).map(height).sum();
            let top = line_top + fraction * (height(row) - LINE_H).max(0.);
            scroll_cursor_into_view(scroll, top, top + LINE_H, content, viewport);
        });
        let is_focused = focus().is_focused();
        // The soft keyboard (Android): `ime_seen` is the text and cursor it
        // last saw, so only changes made elsewhere (send, cursor tap) re-sync it.
        let ime_seen = use_hook(|| Rc::new(RefCell::new((String::new(), 0usize))));
        // Token of this composer's last `ime::show`: hiding never closes another's keyboard.
        let ime_owner = use_hook(|| Rc::new(std::cell::Cell::new(0u64)));
        // `peek`: callers that must re-run on edits read the editor themselves.
        let editor_snapshot = move || {
            let editor = editable.editor().peek();
            (editor.rope().to_string(), editor.cursor_pos())
        };
        // Both a show and a re-sync restart the keyboard with no word in progress.
        {
            let ime_seen = ime_seen.clone();
            let ime_owner = ime_owner.clone();
            let preedit = preedit.clone();
            use_side_effect_with_deps(&is_focused, move |&focused| {
                tracing::debug!(target: "piaf::composer", focused, "focus changed");
                if focused {
                    finish_composition(&preedit);
                    let (text, cursor) = editor_snapshot();
                    ime_owner.set(ime::show(&text, cursor, ImeKind::Composer));
                    *ime_seen.borrow_mut() = (text, cursor);
                } else {
                    ime::hide(ime_owner.get());
                }
            });
        }
        {
            let ime_seen = ime_seen.clone();
            let preedit = preedit.clone();
            use_side_effect(move || {
                // Subscribes: runs after every edit.
                let _ = editable.editor().read();
                let snapshot = editor_snapshot();
                if focus.peek().is_focused() && *ime_seen.borrow() != snapshot {
                    tracing::debug!(target: "piaf::composer", "text changed outside the keyboard: sync");
                    finish_composition(&preedit);
                    ime::sync(&snapshot.0, snapshot.1);
                    *ime_seen.borrow_mut() = snapshot;
                }
            });
        }
        {
            let ime_owner = ime_owner.clone();
            use_drop(move || ime::hide(ime_owner.get()));
        }
        {
            let ime_seen = ime_seen.clone();
            let preedit = preedit.clone();
            use_hook(move || {
                crate::utils::bridge_watch(&ime::events(), move |_| {
                    // Left queued for the focused composer (another one, mid-swap).
                    if !focus.peek().is_focused() {
                        return;
                    }
                    for event in ime::drain() {
                        apply_ime_event(&mut editable.editor_mut().write(), &preedit, event);
                    }
                    *ime_seen.borrow_mut() = editor_snapshot();
                });
            });
        }
        let edit_menu = (is_focused && touch.is_menu_shown()).then(|| {
            let has_selection = editable.editor().read().has_any_selection();
            let preedit = preedit.clone();
            let on_action = move |action: EditAction| {
                finish_composition(&preedit);
                action.apply(editable);
                // Select all keeps the menu up, to copy or cut next.
                touch.show_menu(action == EditAction::SelectAll);
            };
            rect()
                .position(Position::new_absolute().top(-44.).left(48.))
                // Above the timeline rows (layers grow per nesting level).
                .layer(1000)
                .child(EditMenu::new(
                    EditAction::available(has_selection, true),
                    on_action,
                ))
        });

        // Replying / editing: a card at the top of the pill, above the text.
        let context_card = banner.map(|(preview, opacity)| {
            let (icon, label_text) = match preview {
                None => (freya_icons::lucide::pencil(), "Editing message"),
                Some(_) => (freya_icons::lucide::reply(), "Replying to"),
            };
            let (title, body) = match preview {
                Some((sender, body)) => (format!("{label_text} {sender}"), Some(body)),
                None => (label_text.to_string(), None),
            };
            rect()
                .opacity(opacity)
                .padding(Gaps::new(6., 6., 0., 6.))
                .width(Size::fill())
                .child(
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .content(Content::Flex)
                        .cross_align(Alignment::Center)
                        .corner_radius(18.)
                        .overflow(Overflow::Clip)
                        .background(c.reply_other_bg)
                        .padding(Gaps::new(8., 4., 8., 14.))
                        .spacing(10.)
                        .child(
                            SvgViewer::new(icon)
                                .color(c.reply_other_sender)
                                .width(Size::px(16.))
                                .height(Size::px(16.)),
                        )
                        .child(
                            rect()
                                .vertical()
                                .width(Size::flex(1.))
                                .spacing(2.)
                                .child(
                                    label()
                                        .width(Size::fill())
                                        .text(title)
                                        .font_size(13.)
                                        .font_weight(FontWeight::BOLD)
                                        .color(c.reply_other_sender)
                                        .max_lines(1)
                                        .text_overflow(TextOverflow::Ellipsis),
                                )
                                .maybe_child(body.map(|body| {
                                    label()
                                        .width(Size::fill())
                                        .text(body)
                                        .font_size(13.)
                                        .color(c.reply_other_text)
                                        .max_lines(2)
                                        .text_overflow(TextOverflow::Ellipsis)
                                })),
                        )
                        .child(
                            IconButton::new(
                                freya_icons::lucide::x(),
                                c.on_surface_variant,
                                on_cancel,
                            )
                            .tooltip("Cancel (Esc)")
                            .size(36., 18.),
                        ),
                )
        });
        let attach_sheet_el = attach_sheet().then(|| {
            let option = |icon: bytes::Bytes, text: &'static str, source: AttachSource| {
                let send_picked = send_picked.clone();
                ListItem::new(text)
                    .leading(
                        rect()
                            .width(Size::px(40.))
                            .height(Size::px(40.))
                            .corner_radius(20.)
                            .center()
                            .background(c.primary_container)
                            .child(
                                SvgViewer::new(icon)
                                    .width(Size::px(20.))
                                    .height(Size::px(20.))
                                    .color(c.on_primary_container),
                            ),
                    )
                    .on_press(move |_| {
                        attach_sheet.set(false);
                        send_picked(source);
                    })
            };
            bottom_sheet(c, move || attach_sheet.set(false))
                .title("Attach")
                .child(option(
                    freya_icons::lucide::image(),
                    "Photos & videos",
                    AttachSource::Gallery,
                ))
                .child(option(
                    freya_icons::lucide::camera(),
                    "Camera",
                    AttachSource::Camera,
                ))
                .child(option(
                    freya_icons::lucide::file(),
                    "File",
                    AttachSource::File,
                ))
        });
        // Send (or confirm an edit) once there is something to send.
        let has_paste = paste_pending.read().is_some();
        let send_shown = use_fade(!is_empty || is_editing || has_paste, 150);

        rect()
            .vertical()
            .width(Size::fill())
            .background(c.surface)
            .maybe_child(attach_sheet_el)
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
                                .text("Sending…")
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
            // ── Input row: the pill (card, attach, text) and the send button ─
            .child(
                rect()
                    .maybe_child(edit_menu)
                    .horizontal()
                    .content(Content::Flex)
                    .width(Size::fill())
                    .padding(Gaps::new(6., 8., 8., 8.))
                    // Multi-line text grows upwards; the buttons stay at the bottom.
                    .cross_align(Alignment::End)
                    .spacing(6.)
                    .child(
                        rect()
                            .vertical()
                            .width(Size::flex(1.))
                            .corner_radius(24.)
                            .background(c.surface_container)
                            .maybe_child(context_card)
                            .child(
                                rect()
                                    .horizontal()
                                    .width(Size::fill())
                                    .content(Content::Flex)
                                    .cross_align(Alignment::End)
                                    .child(
                                        IconButton::new(
                                            freya_icons::lucide::paperclip(),
                                            c.on_surface_variant,
                                            on_attach,
                                        )
                                        .tooltip("Attach")
                                        .size(48., 22.),
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
                                            .on_touch_start(move |e: Event<TouchEventData>| {
                                                touch.touch_start(
                                                    e.global_location,
                                                    editable,
                                                    || haptics::play(Haptic::HeavyClick),
                                                )
                                            })
                                            .on_touch_move(move |e: Event<TouchEventData>| {
                                                touch.touch_move(e.global_location)
                                            })
                                            .width(Size::flex(1.0))
                                            .height(Size::px(inner_h + V_PAD * 2.))
                                            .overflow(Overflow::Clip)
                                            .child(
                                                ScrollView::new_controlled(scroll)
                                                    .width(Size::fill())
                                                    .height(Size::fill())
                                                    .child(
                                                        rect()
                                                            .vertical()
                                                            .width(Size::fill())
                                                            .padding(Gaps::new(
                                                                V_PAD, 4., V_PAD, 0.,
                                                            ))
                                                            // Over the empty first line: still shown
                                                            // while focused, the cursor at its start.
                                                            .maybe_child(is_empty.then(|| {
                                                                label()
                                                                    .position(
                                                                        Position::new_absolute()
                                                                            .top(0.)
                                                                            .left(0.),
                                                                    )
                                                                    .text(if is_editing {
                                                                        "Edit message"
                                                                    } else if is_replying {
                                                                        "Reply"
                                                                    } else {
                                                                        "Message"
                                                                    })
                                                                    .font_size(16.)
                                                                    .color(c.on_surface_muted)
                                                                    .into_element()
                                                            }))
                                                            .children((0..line_count).map(|i| {
                                                                ComposeLine {
                                                                    line_index: i,
                                                                    editable,
                                                                    c,
                                                                    is_focused,
                                                                    touch,
                                                                    heights: line_heights,
                                                                }
                                                                .into_element()
                                                            })),
                                                    ),
                                            ),
                                    ),
                            ),
                    )
                    .maybe_child((send_shown > 0.).then(|| {
                        rect()
                            .opacity(send_shown)
                            .scale((0.6 + 0.4 * send_shown, 0.6 + 0.4 * send_shown))
                            .child(
                                IconButton::new(
                                    if is_editing {
                                        freya_icons::lucide::check()
                                    } else {
                                        freya_icons::lucide::send_horizontal()
                                    },
                                    c.on_primary,
                                    move |_| on_submit_btn(),
                                )
                                .background(c.primary)
                                .tooltip(if is_editing { "Save" } else { "Send" })
                                .size(48., 22.),
                            )
                    })),
            )
    }
}

/// Scrolls just enough for the cursor row `top..bottom` (content coordinates,
/// below the top padding) to be visible in a `viewport` tall text area.
/// Converges: the effect calling it re-runs on every scroll write (measured
/// rows can be shorter than `LINE_H`, which used to make it oscillate forever).
fn scroll_cursor_into_view(
    mut scroll: ScrollController,
    top: f32,
    bottom: f32,
    content: f32,
    viewport: f32,
) {
    let (_, y) = Into::<(i32, i32)>::into(scroll);
    let view_top = -y as f32;
    // A row taller than the viewport shows its top.
    let bottom = bottom.min(top + viewport);
    let target = if top < view_top {
        top
    } else if bottom > view_top + viewport {
        bottom - viewport
    } else {
        view_top
    };
    let target = -(target.clamp(0., (content - viewport).max(0.)) as i32);
    if target != y {
        scroll.scroll_to_y(target);
    }
}
