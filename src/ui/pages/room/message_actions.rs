//! A message's actions (long press, right click, "more"): quick reactions on
//! top, then reply, copy, edit… A bottom sheet on Android, a popup elsewhere.

use std::sync::Arc;

use freya::prelude::*;
use matrix_sdk::ruma::events::room::message::MessageType;
use matrix_sdk_ui::timeline::TimelineItem;
use tokio::sync::mpsc::UnboundedSender;

use crate::ui::components::{HoverableExt, ListItem};
use crate::utils::bookmarks::BookmarkEntry;
use crate::utils::const_values::AppColors;
use crate::utils::haptics::{self, Haptic};
use crate::utils::room_preview::{reply_preview, sender_name};

use super::message_row::reply_target;
use super::ui_ctx::{Editing, RoomUiCtx};
use super::{MsgAction, reactions};

const QUICK_REACTIONS: &[&str] = &["👍", "❤️", "😂", "😮", "😢", "🎉"];
/// At most this many emojis in the row (the message's own reactions first).
const MAX_REACTIONS: usize = 7;
const EMOJI_BUTTON: f32 = 46.;

struct Action {
    icon: Bytes,
    label: &'static str,
    destructive: bool,
    run: Box<dyn FnMut()>,
}

/// The open menu, if any (`ui.action_popup`).
pub(super) fn message_actions(
    ui: RoomUiCtx,
    room_id: &str,
    room_name: &str,
    my_user_id: Option<&str>,
    action_tx: Arc<UnboundedSender<MsgAction>>,
    c: AppColors,
) -> Option<Element> {
    let item: Arc<TimelineItem> = ui.action_popup.read().clone()?;
    let event = item.as_event()?;
    let message = event.content().as_message()?.clone();
    let mut open = ui.action_popup;
    let event_id = event.event_id().map(|id| id.to_string());
    let is_me = my_user_id == Some(event.sender().as_str());
    let reactions = event
        .content()
        .as_msglike()
        .map(|m| reactions(&m.reactions, my_user_id))
        .unwrap_or_default();

    // ── Emoji row: the message's reactions, then the quick ones ────────────
    let mut emojis: Vec<(String, bool)> = reactions
        .iter()
        .map(|r| (r.key.clone(), r.reacted_by_me))
        .collect();
    for quick in QUICK_REACTIONS {
        if !emojis.iter().any(|(key, _)| key == quick) {
            emojis.push((quick.to_string(), false));
        }
    }
    emojis.truncate(MAX_REACTIONS);
    let emoji_row = {
        let event_id = event_id.clone();
        let tx = action_tx.clone();
        rect()
            .horizontal()
            .width(Size::fill())
            .content(Content::Flex)
            .padding(Gaps::new(4., 12., 12., 12.))
            .children(emojis.into_iter().map(move |(key, mine)| {
                let (event_id, tx, shown) = (event_id.clone(), tx.clone(), key.clone());
                rect()
                    .width(Size::flex(1.))
                    .center()
                    .child(
                        rect()
                            .center()
                            .width(Size::px(EMOJI_BUTTON))
                            .height(Size::px(EMOJI_BUTTON))
                            .corner_radius(EMOJI_BUTTON / 2.)
                            .background(if mine {
                                c.primary_container
                            } else {
                                c.surface_container
                            })
                            .maybe(mine, |r| r.border(Border::new().fill(c.primary).width(2.)))
                            .on_press(move |_| {
                                haptics::play(Haptic::Click);
                                if let Some(event_id) = event_id.clone() {
                                    let _ = tx.send(MsgAction::React {
                                        event_id,
                                        key: key.clone(),
                                    });
                                }
                                open.set(None);
                            })
                            .child(label().text(shown).font_size(22.))
                            .hoverable(
                                Size::px(EMOJI_BUTTON),
                                Size::px(EMOJI_BUTTON),
                                EMOJI_BUTTON / 2.,
                            ),
                    )
                    .into_element()
            }))
    };

    // ── Actions ─────────────────────────────────────────────────────────────
    let mut actions = vec![];
    if let Some(reply_to) = reply_target(event, &message) {
        actions.push(Action {
            icon: freya_icons::lucide::reply(),
            label: "Reply",
            destructive: false,
            run: Box::new(move || ui.reply(reply_to.clone())),
        });
    }
    let text = match message.msgtype() {
        MessageType::Text(t) => Some(t.body.clone()),
        MessageType::Notice(n) => Some(n.body.clone()),
        MessageType::Emote(e) => Some(e.body.clone()),
        _ => None,
    };
    if let Some(text) = text.clone() {
        actions.push(Action {
            icon: freya_icons::lucide::copy(),
            label: "Copy text",
            destructive: false,
            run: Box::new(move || {
                let _ = Clipboard::set(text.clone());
            }),
        });
    }
    if is_me
        && let (Some(event_id), Some(MessageType::Text(t))) =
            (event_id.clone(), Some(message.msgtype()))
    {
        let mut editing = ui.editing;
        let body = t.body.clone();
        actions.push(Action {
            icon: freya_icons::lucide::pencil(),
            label: "Edit",
            destructive: false,
            run: Box::new(move || {
                editing.set(Some(Editing {
                    event_id: event_id.clone(),
                    body: body.clone(),
                }))
            }),
        });
    }
    if let Some(event_id) = event_id.clone() {
        let mut bookmark_picker = ui.bookmark_picker;
        let (room_id, room_name) = (room_id.to_string(), room_name.to_string());
        let (sender, preview) = (sender_name(event), reply_preview(message.msgtype()));
        actions.push(Action {
            icon: freya_icons::lucide::bookmark(),
            label: "Bookmark",
            destructive: false,
            run: Box::new(move || {
                let added_ts_ms = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_millis() as u64;
                bookmark_picker.set(Some(BookmarkEntry {
                    room_id: room_id.clone(),
                    event_id: event_id.clone(),
                    room_name: room_name.clone(),
                    sender_display: sender.clone(),
                    message_preview: preview.clone(),
                    added_ts_ms,
                }));
            }),
        });
    }
    {
        let mut detail_modal = ui.detail_modal;
        let item = item.clone();
        actions.push(Action {
            icon: freya_icons::lucide::info(),
            label: "Details",
            destructive: false,
            run: Box::new(move || detail_modal.set(Some(item.clone()))),
        });
    }
    if is_me && let Some(event_id) = event_id {
        let mut confirm_delete = ui.confirm_delete;
        actions.push(Action {
            icon: freya_icons::lucide::trash_2(),
            label: "Delete",
            destructive: true,
            run: Box::new(move || confirm_delete.set(Some(event_id.clone()))),
        });
    }

    let rows = actions.into_iter().map(move |mut action| {
        let color = if action.destructive {
            c.error
        } else {
            c.on_surface
        };
        ListItem::with_headline(
            label()
                .width(Size::fill())
                .text(action.label)
                .font_size(15.)
                .color(color),
        )
        .leading(
            SvgViewer::new(action.icon)
                .color(if action.destructive {
                    c.error
                } else {
                    c.on_surface_variant
                })
                .width(Size::px(22.))
                .height(Size::px(22.)),
        )
        .on_press(move |_| {
            // Closed first: an action may open another overlay.
            open.set(None);
            (action.run)();
        })
        .into_element()
    });

    #[cfg(target_os = "android")]
    let menu = crate::ui::components::bottom_sheet(c, move || open.set(None))
        .child(emoji_row)
        .children(rows)
        .into_element();
    #[cfg(not(target_os = "android"))]
    let menu = Popup::new()
        .on_close_request(move |_| open.set(None))
        .child(emoji_row)
        .children(rows)
        .into_element();
    Some(menu)
}
