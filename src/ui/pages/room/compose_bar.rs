use std::cell::RefCell;
use std::rc::Rc;
use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;

use freya::prelude::*;

use crate::ui::components::IconButton;

use crate::ui::components::use_fading;
use freya::text_edit::*;
use tokio::sync::mpsc::UnboundedSender;

use super::compose_touch::{self, EditAction, use_compose_touch};
use crate::utils::ime::{self, ImeEvent};
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
        let touch = use_compose_touch();
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

        #[cfg(not(target_os = "android"))]
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
            if e.key == Key::Named(NamedKey::Enter) && !e.modifiers.shift() && !cfg!(target_os = "android") {
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
        // Measured heights: a long line wraps over several rows.
        let content_h: f32 = (0..line_count)
            .map(|i| line_heights.read().get(i).copied().filter(|h| *h > 0.).unwrap_or(LINE_H))
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
            let height = |i: usize| heights.get(i).copied().filter(|h| *h > 0.).unwrap_or(LINE_H);
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
                    ime_owner.set(ime::show(&text, cursor));
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
            compose_touch::edit_menu(c, has_selection, move |action| {
                finish_composition(&preedit);
                action.apply(editable);
                // Select all keeps the menu up, to copy or cut next.
                touch.show_menu(action == EditAction::SelectAll);
            })
        });

        rect()
            .vertical()
            .width(Size::fill())
            .background(c.surface)
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
                    .maybe_child(edit_menu)
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
                            .on_touch_start(move |e: Event<TouchEventData>| {
                                touch.touch_start(e.global_location, editable)
                            })
                            .on_touch_move(move |e: Event<TouchEventData>| {
                                touch.touch_move(e.global_location)
                            })
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
                                ScrollView::new_controlled(scroll)
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
                                                    touch,
                                                    heights: line_heights,
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

/// Scrolls just enough for the cursor row `top..bottom` (content coordinates,
/// below the top padding) to be visible in a `viewport` tall text area.
/// Converges: the effect calling it re-runs on every scroll write (measured
/// rows can be shorter than `LINE_H`, which used to make it oscillate forever).
fn scroll_cursor_into_view(mut scroll: ScrollController, top: f32, bottom: f32, content: f32, viewport: f32) {
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

/// The soft keyboard's word in progress, as a UTF-16 range of ordinary text.
/// Not the editor's preedit: that keeps its own copy of the range, which goes
/// stale (and panics) when the text changes under it. This one is clamped to
/// the text at every use.
type Composing = Rc<RefCell<Option<(usize, usize)>>>;

/// Applies what the soft keyboard did (see [`ImeEvent`]) to the editor.
fn apply_ime_event(editor: &mut RopeEditor, composing: &RefCell<Option<(usize, usize)>>, event: ImeEvent) {
    let len = editor.len_utf16_cu();
    let clamp = |(a, b): (usize, usize)| (a.min(b).min(len), a.max(b).min(len));
    // The composition, else the selection: what typed text replaces.
    let target = composing
        .borrow()
        .or_else(|| editor.get_selection_range())
        .unwrap_or_else(|| {
            let cursor = editor.cursor_pos();
            (cursor, cursor)
        });
    let (start, end) = clamp(target);
    let mut replace = |text: &str| {
        if end > start {
            editor.remove(start..end);
        }
        editor.insert(text, start);
        let text_end = start + text.encode_utf16().count();
        *editor.selection_mut() = TextSelection::new_cursor(text_end);
        text_end
    };
    match event {
        ImeEvent::Commit(text) => {
            replace(&text);
            *composing.borrow_mut() = None;
        }
        ImeEvent::Preedit(text) => {
            let text_end = replace(&text);
            *composing.borrow_mut() = (!text.is_empty()).then_some((start, text_end));
        }
        ImeEvent::ComposingRegion { start, end } => {
            *composing.borrow_mut() = Some(clamp((start, end))).filter(|(a, b)| b > a);
        }
        ImeEvent::Select { start, end } => {
            let (start, end) = (start.min(len), end.min(len));
            *editor.selection_mut() = if start == end {
                TextSelection::new_cursor(start)
            } else {
                TextSelection::new_range((start, end))
            };
        }
        // Around the selection (Android's `deleteSurroundingText`); the
        // composition shifts with the text.
        ImeEvent::Delete { before, after } => {
            let (sel_start, sel_end) = editor
                .get_selection_range()
                .unwrap_or_else(|| (editor.cursor_pos(), editor.cursor_pos()));
            let (sel_start, sel_end) = clamp((sel_start, sel_end));
            let removed_after = (sel_end, (sel_end + after).min(len));
            let removed_before = (sel_start.saturating_sub(before), sel_start);
            for (a, b) in [removed_after, removed_before] {
                if b > a {
                    editor.remove(a..b);
                    let shift = |pos: usize| if pos <= a { pos } else if pos >= b { pos - (b - a) } else { a };
                    let range = *composing.borrow();
                    *composing.borrow_mut() = range.map(|(s, e)| (shift(s), shift(e))).filter(|(s, e)| e > s);
                }
            }
            let cursor = removed_before.0;
            *editor.selection_mut() = if sel_end > sel_start {
                TextSelection::new_range((cursor, cursor + (sel_end - sel_start)))
            } else {
                TextSelection::new_cursor(cursor)
            };
        }
    }
}

/// Before an edit that doesn't come from the keyboard: the word in progress
/// stays as plain text.
fn finish_composition(composing: &RefCell<Option<(usize, usize)>>) {
    composing.borrow_mut().take();
}

#[cfg(test)]
mod tests {
    use std::time::Duration;

    use super::*;

    fn editor(text: &str, cursor: usize) -> RopeEditor {
        RopeEditor::new(
            text.to_string(),
            TextSelection::new_cursor(cursor),
            0,
            EditorHistory::new(Duration::from_millis(10)),
        )
    }

    fn text(editor: &RopeEditor) -> String {
        editor.rope().to_string()
    }

    #[test]
    fn composition_is_rewritten_in_place_then_committed() {
        let mut e = editor("", 0);
        let composing = RefCell::new(None);
        apply_ime_event(&mut e, &composing, ImeEvent::Preedit("he".into()));
        apply_ime_event(&mut e, &composing, ImeEvent::Preedit("hel".into()));
        apply_ime_event(&mut e, &composing, ImeEvent::Commit("hello ".into()));
        assert_eq!(text(&e), "hello ");
        assert_eq!(e.cursor_pos(), 6);
        assert_eq!(*composing.borrow(), None);
    }

    #[test]
    fn composing_region_re_edits_a_word_without_duplicating_it() {
        let mut e = editor("hel world", 3);
        let composing = RefCell::new(None);
        apply_ime_event(&mut e, &composing, ImeEvent::ComposingRegion { start: 0, end: 3 });
        apply_ime_event(&mut e, &composing, ImeEvent::Preedit("help".into()));
        assert_eq!(text(&e), "help world");
    }

    #[test]
    fn stale_ranges_are_clamped_instead_of_panicking() {
        // The crashes: a range from longer text after select all / cut.
        let mut e = editor("short", 5);
        let composing = RefCell::new(Some((100, 141)));
        apply_ime_event(&mut e, &composing, ImeEvent::ComposingRegion { start: 141, end: 221 });
        apply_ime_event(&mut e, &composing, ImeEvent::Preedit("x".into()));
        apply_ime_event(&mut e, &composing, ImeEvent::Commit("y".into()));
        apply_ime_event(&mut e, &composing, ImeEvent::Delete { before: 50, after: 50 });
        apply_ime_event(&mut e, &composing, ImeEvent::Select { start: 99, end: 300 });
        assert!(text(&e).len() <= "shorty".len());
    }

    #[test]
    fn delete_shifts_the_composition() {
        let mut e = editor("ab cd", 5);
        let composing = RefCell::new(Some((3, 5)));
        *e.selection_mut() = TextSelection::new_cursor(3);
        apply_ime_event(&mut e, &composing, ImeEvent::Delete { before: 1, after: 0 });
        assert_eq!(text(&e), "abcd");
        assert_eq!(*composing.borrow(), Some((2, 4)));
    }

    #[test]
    fn commit_replaces_a_selection() {
        let mut e = editor("hello", 0);
        e.set_selection((0, 5));
        let composing = RefCell::new(None);
        apply_ime_event(&mut e, &composing, ImeEvent::Commit("bye".into()));
        assert_eq!(text(&e), "bye");
    }
}
