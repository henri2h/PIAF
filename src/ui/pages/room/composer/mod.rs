mod attachments;
mod compose_line;
mod context_card;
mod ime;
mod mentions;

use std::cell::{Cell, RefCell};
use std::rc::Rc;
use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;

use freya::prelude::*;
use freya::text_edit::*;
use tokio::sync::mpsc::UnboundedSender;

use crate::ui::components::{IconButton, use_fade, use_fading};
use crate::utils::drafts;
use crate::utils::haptics::{self, Haptic};
use crate::utils::ime_edit::{Composing, finish_composition};
use crate::utils::matrix::my_user_id;
use crate::utils::media::AttachSource;
use crate::utils::members::MemberItem;
use crate::utils::{on_tokio, use_app_colors};

use super::MsgAction;
use super::outgoing::{Draft, Mention};
use super::ui_ctx::use_room_ui_ctx;
use attachments::{attach_sheet, attachment_banner, send_pasted, send_picked};
use compose_line::ComposeLine;
use context_card::{Context, context_card};
use mentions::{insert_mention, mention_query, suggestion_list, suggestions};

const LINE_H: f32 = 24.;
const MAX_LINES: usize = 5;
/// Above and below the text: one line makes a 48px pill.
const V_PAD: f32 = 12.;
/// The draft is saved this long after the last edit.
const DRAFT_DELAY: Duration = Duration::from_millis(500);

/// The message composer. Reply / edit state comes from the room's
/// `RoomUiCtx`; it is keyed on the edited event, so an edit gets a fresh one.
#[derive(Clone)]
pub struct ComposeBar {
    pub room_id: String,
    pub action_tx: Arc<UnboundedSender<MsgAction>>,
}

impl PartialEq for ComposeBar {
    fn eq(&self, other: &Self) -> bool {
        Arc::ptr_eq(&self.action_tx, &other.action_tx) && self.room_id == other.room_id
    }
}

/// Replaces the composer's text, the cursor at `cursor` (UTF-16 units).
fn set_text(mut editable: UseEditable, text: String, cursor: usize) {
    *editable.editor_mut().write() = RopeEditor::new(
        text,
        TextSelection::new_cursor(cursor),
        0,
        EditorHistory::new(Duration::from_millis(10)),
    );
}

impl Component for ComposeBar {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let ui = use_room_ui_ctx();
        let (mut editing, mut reply_to) = (ui.editing, ui.reply_to);
        let action_tx = self.action_tx.clone();
        let room_id = self.room_id.clone();

        let a11y_id = use_a11y();
        let focus = use_focus(a11y_id);
        let touch = use_touch_edit();
        // The soft keyboard's word in progress (Android): a UTF-16 range of the text.
        let preedit: Composing = use_hook(|| Rc::new(RefCell::new(None)));
        let line_heights: State<Vec<f32>> = use_state(Vec::new);
        let scroll = use_scroll_controller(ScrollConfig::default);
        let editable = use_editable(String::new, EditableConfig::new);
        // People picked from the `@` suggestions; members loaded on the first `@`.
        let mut mentions: State<Vec<Mention>> = use_state(Vec::new);
        let mut members: State<Option<Vec<MemberItem>>> = use_state(|| None);
        // Pasted image waiting to be sent; a send in progress.
        let mut paste_pending: State<Option<Vec<u8>>> = use_state(|| None);
        let sending: State<bool> = use_state(|| false);
        // Android: the attach sheet (gallery, camera, file).
        let mut attach_sheet_open = use_state(|| false);

        // On mount: the message being edited, else the draft, with the cursor
        // at the end to continue typing.
        {
            let room_id = room_id.clone();
            use_hook(move || {
                let text = match editing.peek().clone() {
                    Some(edit) => Some(edit.body),
                    None => drafts::get(&room_id),
                };
                if let Some(text) = text {
                    let end = text.encode_utf16().count();
                    set_text(editable, text, end);
                }
            });
        }
        // Bumped on every edit and on send; a pending save only runs if still current.
        let draft_gen = use_hook(|| Arc::new(AtomicU64::new(0)));

        let is_editing = editing.read().is_some();
        let is_replying = reply_to.read().is_some();
        // Kept while it fades out.
        let context = use_fading(
            if is_editing {
                Some(Context::Editing)
            } else {
                reply_to.read().clone().map(|r| Context::Replying {
                    sender: r.sender,
                    body: r.body,
                })
            },
            150,
        );

        // `i` (keyboard navigation), a reply or an edit focus the composer.
        let compose_focus = *ui.compose_focus.read();
        use_side_effect_with_deps(&compose_focus, move |&requests| {
            if requests > 0 {
                a11y_id.request_focus();
            }
        });
        let focus_trigger = is_replying || is_editing;
        use_side_effect_with_deps(&focus_trigger, move |&active| {
            if active {
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
        // The media viewer covers the composer: let go of the keyboard.
        let viewer_open = ui.image_viewer.read().is_some();
        use_side_effect_with_deps(&viewer_open, move |&open| {
            if open {
                a11y_id.request_unfocus();
            }
        });

        // Save the draft a moment after the last edit.
        {
            let room_id = room_id.clone();
            let draft_gen = draft_gen.clone();
            use_side_effect(move || {
                if is_editing {
                    return;
                }
                let text = editable.editor().read().rope().to_string();
                let room_id = room_id.clone();
                let draft_gen = draft_gen.clone();
                let generation = draft_gen.fetch_add(1, Ordering::Relaxed) + 1;
                tokio::task::spawn(async move {
                    tokio::time::sleep(DRAFT_DELAY).await;
                    if draft_gen.load(Ordering::Relaxed) == generation {
                        drafts::set(&room_id, &text);
                    }
                });
            });
        }

        // "Typing…" for the others while there is text (the SDK throttles
        // the requests); not for a draft restored on mount.
        {
            let action_tx = action_tx.clone();
            let typing_sent = use_hook(|| Rc::new(Cell::new(None::<bool>)));
            use_side_effect(move || {
                let typing = editable.editor().read().rope().len_chars() > 0;
                let before = typing_sent.replace(Some(typing));
                if before.is_some() && (typing || before == Some(true)) {
                    let _ = action_tx.send(MsgAction::Typing(typing));
                }
            });
        }

        // ── Mentions ───────────────────────────────────────────────────────
        let query = {
            let editor = editable.editor().read();
            mention_query(&editor.rope().to_string(), editor.cursor_pos())
        };
        {
            let room_id = room_id.clone();
            use_side_effect_with_deps(&query.is_some(), move |&typing_mention| {
                if !typing_mention || members.peek().is_some() {
                    return;
                }
                members.set(Some(vec![]));
                let room_id = room_id.clone();
                spawn(async move {
                    let loaded = on_tokio(async move {
                        let room = crate::utils::matrix::get_room(&room_id)?;
                        Some(crate::utils::members::joined(&room).await)
                    })
                    .await
                    .flatten();
                    members.set(Some(loaded.unwrap_or_default()));
                });
            });
        }
        let me = my_user_id();
        let suggested: Vec<MemberItem> = match (&query, members.read().as_ref()) {
            (Some((_, q)), Some(all)) => suggestions(all, q, me.as_deref())
                .into_iter()
                .cloned()
                .collect(),
            _ => vec![],
        };
        let pick_mention = {
            let query = query.clone();
            move |member: MemberItem| {
                let Some((start, _)) = query.clone() else {
                    return;
                };
                let (text, cursor) = {
                    let editor = editable.editor().peek();
                    insert_mention(
                        &editor.rope().to_string(),
                        start,
                        editor.cursor_pos(),
                        &member.display_name,
                    )
                };
                set_text(editable, text, cursor);
                let mut mentions = mentions;
                mentions.write().push(Mention {
                    user_id: member.user_id,
                    name: member.display_name,
                });
                a11y_id.request_focus();
            }
        };

        // ── Send ───────────────────────────────────────────────────────────
        let preedit_send = preedit.clone();
        let room_id_send = room_id.clone();
        let draft_gen_send = draft_gen.clone();
        let do_send = move || {
            finish_composition(&preedit_send);
            let text = editable
                .editor()
                .peek()
                .rope()
                .to_string()
                .trim()
                .to_string();
            let paste = paste_pending.peek().clone();
            if text.is_empty() && paste.is_none() {
                return;
            }
            if !text.is_empty() {
                let draft = Draft {
                    text,
                    mentions: mentions.peek().clone(),
                };
                let edit = editing.peek().clone();
                let reply = reply_to.peek().clone();
                let action = if let Some(edit) = edit {
                    editing.set(None);
                    MsgAction::Edit {
                        event_id: edit.event_id,
                        draft,
                    }
                } else if let Some(reply) = reply {
                    reply_to.set(None);
                    MsgAction::Reply {
                        reply_event_id: reply.event_id,
                        draft,
                    }
                } else {
                    MsgAction::Send { draft }
                };
                // An edit leaves the draft of the normal composer alone.
                if !matches!(action, MsgAction::Edit { .. }) {
                    draft_gen_send.fetch_add(1, Ordering::Relaxed);
                    drafts::clear(&room_id_send);
                }
                let _ = action_tx.send(action);
                set_text(editable, String::new(), 0);
                mentions.set(vec![]);
            }
            if let Some(png) = paste {
                paste_pending.set(None);
                send_pasted(room_id_send.clone(), png, sending);
            }
        };

        // ── Keys and pointer ───────────────────────────────────────────────
        let preedit_keys = preedit.clone();
        let mut send_on_enter = do_send.clone();
        let first_suggestion = suggested.first().cloned();
        let pick_first = pick_mention.clone();
        let on_key_down = move |e: Event<KeyboardEventData>| {
            finish_composition(&preedit_keys);
            // Esc cancels a reply or edit first, then leaves the composer
            // so keyboard navigation works again.
            if e.key == Key::Named(NamedKey::Escape) {
                if editing.peek().is_some() {
                    editing.set(None);
                } else if reply_to.peek().is_some() {
                    reply_to.set(None);
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
            let enter = e.key == Key::Named(NamedKey::Enter) && !e.modifiers.shift();
            // Tab or Enter take the first `@` suggestion.
            if let Some(member) = first_suggestion.clone()
                && (enter || e.key == Key::Named(NamedKey::Tab))
            {
                pick_first(member);
                return;
            }
            // On a touch keyboard Enter starts a new line; the send button sends.
            if enter && !cfg!(target_os = "android") {
                send_on_enter();
                return;
            }
            let mut editable = editable;
            editable.process_event(EditableEvent::KeyDown {
                key: &e.key,
                modifiers: e.modifiers,
                editor_line: None,
                holder: None,
            });
            // Ctrl+V: an image on the clipboard is staged for sending.
            #[cfg(not(target_os = "android"))]
            if e.key == Key::Character("v".into())
                && e.modifiers.ctrl()
                && let Some(png) = crate::utils::clipboard::read_image()
            {
                paste_pending.set(Some(png));
            }
        };
        let on_key_up = move |e: Event<KeyboardEventData>| {
            let mut editable = editable;
            editable.process_event(EditableEvent::KeyUp { key: &e.key });
        };
        let on_global_pointer_up = move |e: Event<PointerEventData>| {
            let mut editable = editable;
            editable.process_event(EditableEvent::Release);
            if matches!(*e, PointerEventData::Touch(_)) {
                touch.touch_end(editable.editor().peek().has_any_selection());
            }
        };
        let on_cancel = move |_| {
            if editing.peek().is_some() {
                editing.set(None);
            } else {
                reply_to.set(None);
            }
        };
        let room_id_attach = room_id.clone();
        let on_attach = move |_| {
            if cfg!(target_os = "android") {
                // The keyboard would cover the sheet: the composer lets go of it.
                a11y_id.request_unfocus();
                attach_sheet_open.set(true);
            } else {
                send_picked(room_id_attach.clone(), AttachSource::File, sending);
            }
        };

        // ── Height and scrolling ───────────────────────────────────────────
        let line_count = editable.editor().read().len_lines().max(1);
        let height = move |heights: &[f32], i: usize| {
            heights
                .get(i)
                .copied()
                .filter(|h| *h > 0.)
                .unwrap_or(LINE_H)
        };
        // Measured heights: a long line wraps over several rows.
        let content_h: f32 = (0..line_count)
            .map(|i| height(&line_heights.read(), i))
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
            let content: f32 = (0..editor.len_lines().max(1))
                .map(|i| height(&heights, i))
                .sum();
            let viewport = content.min(MAX_LINES as f32 * LINE_H);
            // The cursor's row inside a wrapped line, estimated from its column.
            let line_top: f32 = (0..row).map(|i| height(&heights, i)).sum();
            let top = line_top + fraction * (height(&heights, row) - LINE_H).max(0.);
            scroll_cursor_into_view(scroll, top, top + LINE_H, content, viewport);
        });

        ime::use_composer_ime(editable, focus, preedit.clone());
        let is_focused = focus().is_focused();

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

        // Send (or confirm an edit) once there is something to send.
        let has_paste = paste_pending.read().is_some();
        let send_shown = use_fade(!is_empty || is_editing || has_paste, 150);
        let placeholder = if is_editing {
            "Edit message"
        } else if is_replying {
            "Reply"
        } else {
            "Message"
        };

        let text_area = rect()
            .a11y_id(a11y_id)
            .a11y_focusable(true)
            .a11y_role(AccessibilityRole::TextInput)
            .on_key_down(on_key_down)
            .on_key_up(on_key_up)
            .on_global_pointer_up(on_global_pointer_up)
            .on_pointer_down(move |_| a11y_id.request_focus())
            .on_touch_start(move |e: Event<TouchEventData>| {
                touch.touch_start(e.global_location, editable, || {
                    haptics::play(Haptic::HeavyClick)
                })
            })
            .on_touch_move(move |e: Event<TouchEventData>| touch.touch_move(e.global_location))
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
                            .padding(Gaps::new(V_PAD, 4., V_PAD, 0.))
                            // Over the empty first line: still shown while
                            // focused, the cursor at its start.
                            .maybe_child(is_empty.then(|| {
                                label()
                                    .position(Position::new_absolute().top(0.).left(0.))
                                    .text(placeholder)
                                    .font_size(16.)
                                    .color(c.on_surface_muted)
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
            );

        let mut on_submit = do_send;
        rect()
            .vertical()
            .width(Size::fill())
            .background(c.surface)
            .maybe_child(
                attach_sheet_open()
                    .then(|| attach_sheet(room_id.clone(), attach_sheet_open, sending, c)),
            )
            .maybe_child(attachment_banner(
                &room_id,
                *sending.read(),
                paste_pending,
                c,
            ))
            // ── Input row: the pill (suggestions, card, attach, text) and send ─
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
                            .overflow(Overflow::Clip)
                            .background(c.surface_container)
                            .maybe_child(
                                (!suggested.is_empty())
                                    .then(|| suggestion_list(suggested, &room_id, pick_mention, c)),
                            )
                            .maybe_child(context.map(|(context, opacity)| {
                                context_card(context, opacity, on_cancel, c)
                            }))
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
                                    .child(text_area),
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
                                    move |_| on_submit(),
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
