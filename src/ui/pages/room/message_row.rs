use std::sync::Arc;

use freya::prelude::*;
use tokio::sync::mpsc::UnboundedSender;

use super::{MessageContent, MessageItem, MsgAction};
use crate::ui::components::Avatar;
use crate::utils::use_app_colors;

pub struct MessageRow {
    pub room_id: String,
    pub msg: MessageItem,
    pub action_tx: Arc<UnboundedSender<MsgAction>>,
    pub image_viewer: State<Option<String>>,
    pub action_popup: State<Option<(Area, MessageItem)>>,
    pub detail_modal: State<Option<MessageItem>>,
    pub is_dm: bool,
}

impl PartialEq for MessageRow {
    fn eq(&self, other: &Self) -> bool {
        self.room_id == other.room_id
            && self.msg == other.msg
            && self.is_dm == other.is_dm
            && Arc::ptr_eq(&self.action_tx, &other.action_tx)
            && self.detail_modal == other.detail_modal
    }
}

impl Component for MessageRow {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let room_id = self.room_id.clone();
        let msg = self.msg.clone();
        let action_tx = self.action_tx.clone();
        let mut image_viewer = self.image_viewer;
        let is_me = msg.is_me;
        let is_dm = self.is_dm;
        let mut action_popup = self.action_popup;
        let mut detail_modal = self.detail_modal;

        // Tracks this row's screen position so the popup can be positioned near it.
        let mut row_area: State<Option<Area>> = use_state(|| None);
        // Long-press detection for Android (generation counter aborts in-flight timers).
        #[cfg(target_os = "android")]
        let mut press_gen: State<u32> = use_state(|| 0u32);

        let bubble_bg: (u8, u8, u8) = if is_me {
            c.primary
        } else {
            c.surface_container
        };

        // ── Date separator ────────────────────────────────────────────────
        // Computed before the notice early-return so both paths can include it.
        let date_separator = if let Some(date_lbl) = &msg.date_label {
            rect()
                .horizontal()
                .width(Size::fill())
                .main_align(Alignment::Center)
                .cross_align(Alignment::Center)
                .padding(Gaps::new(8., 0., 4., 0.))
                .child(
                    rect()
                        .padding(Gaps::new(3., 12., 3., 12.))
                        .corner_radius(12.)
                        .background(c.date_separator_bg)
                        .child(
                            label()
                                .text(date_lbl.clone())
                                .font_size(12.)
                                .color(c.on_surface),
                        ),
                )
                .into_element()
        } else {
            rect().into_element()
        };

        // ── Read marker divider ───────────────────────────────────────────
        if let super::MessageContent::ReadMarker = &msg.content {
            return rect()
                .horizontal()
                .width(Size::fill())
                .content(Content::Flex)
                .cross_align(Alignment::Center)
                .padding(Gaps::new(8., 16., 8., 16.))
                .spacing(8.)
                .child(
                    rect()
                        .width(Size::flex(1.0))
                        .height(Size::px(1.))
                        .background(c.primary),
                )
                .child(
                    label()
                        .text("New messages")
                        .font_size(12.)
                        .color(c.primary),
                )
                .child(
                    rect()
                        .width(Size::flex(1.0))
                        .height(Size::px(1.))
                        .background(c.primary),
                );
        }

        // ── Notice (state events: join, leave, ban, etc.) ─────────────────
        if let super::MessageContent::Notice(text) = &msg.content {
            return rect()
                .vertical()
                .width(Size::fill())
                .child(date_separator)
                .child(
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .main_align(Alignment::Center)
                        .padding(Gaps::new(2., 12., 2., 12.))
                        .child(
                            rect()
                                .padding(Gaps::new(4., 12., 4., 12.))
                                .corner_radius(12.)
                                .background(c.surface_container)
                                .child(
                                    label()
                                        .text(text.clone())
                                        .font_size(12.)
                                        .color(c.on_surface_muted),
                                ),
                        ),
                );
        }

        // ── Reply quote ───────────────────────────────────────────────────
        let reply_el =
            if let Some((reply_sender, reply_body)) = &msg.reply_to {
                rect()
                    .vertical()
                    .padding(Gaps::new(0., 0., 6., 0.))
                    .child(
                        rect()
                            .vertical()
                            .padding(Gaps::new(4., 8., 4., 8.))
                            .corner_radius(8.)
                            .background(if is_me {
                                c.reply_me_bg
                            } else {
                                c.reply_other_bg
                            })
                            .spacing(2.)
                            .child(
                                label()
                                    .text(reply_sender.clone())
                                    .font_size(11.)
                                    .font_weight(FontWeight::BOLD)
                                    .color(if is_me {
                                        c.reply_me_sender
                                    } else {
                                        c.reply_other_sender
                                    }),
                            )
                            .child(label().text(reply_body.clone()).font_size(12.).color(
                                if is_me {
                                    c.reply_me_text
                                } else {
                                    c.reply_other_text
                                },
                            )),
                    )
                    .into_element()
            } else {
                rect().into_element()
            };

        // ── Main content ──────────────────────────────────────────────────
        let _is_image = matches!(&msg.content, MessageContent::Image { .. });
        let content_el = match &msg.content {
            MessageContent::Notice(_) | MessageContent::ReadMarker => {
                unreachable!("handled above")
            }
            MessageContent::Text(body) => label()
                .text(body.clone())
                .color(if is_me {
                    c.bubble_me_text
                } else {
                    c.bubble_other_text
                })
                .into_element(),
            MessageContent::Image { key, bytes, caption } => {
                let key_view = key.clone();
                let caption_text = caption.clone();
                let text_color = if is_me { c.bubble_me_text } else { c.bubble_other_text };
                rect()
                    .vertical()
                    .spacing(6.)
                    .child(
                        rect()
                            .width(Size::px(200.))
                            .height(Size::px(150.))
                            .corner_radius(8.)
                            .on_press(move |_| {
                                *image_viewer.write() = Some(key_view.clone());
                            })
                            .child(
                                ImageViewer::new((key.clone(), Bytes::from(bytes.clone())))
                                    .width(Size::fill())
                                    .height(Size::fill())
                                    .corner_radius(8.)
                                    .image_cover(ImageCover::Center),
                            ),
                    )
                    .maybe_child(caption_text.map(|cap| {
                        label()
                            .text(cap)
                            .color(text_color)
                            .into_element()
                    }))
                    .into_element()
            }
        };

        // ── Bubble ────────────────────────────────────────────────────────
        let bubble_inner = rect()
            .vertical()
            .max_width(Size::percent(82.))
            .padding(Gaps::new_all(12.))
            .corner_radius(18.)
            .background(bubble_bg)
            .spacing(4.);

        let bubble_inner = if !is_me {
            bubble_inner
                .maybe(!is_dm, |b| {
                    b.child(
                        label()
                            .text(msg.sender_name.clone())
                            .font_size(12.)
                            .font_weight(FontWeight::BOLD)
                            .color(msg.sender_color),
                    )
                })
                .child(reply_el)
                .child(content_el)
                .child(
                    label()
                        .text(msg.timestamp.clone())
                        .font_size(11.)
                        .color(c.on_surface_faint),
                )
        } else {
            let receipt_icon = if !msg.read_receipts.is_empty() || msg.fully_read {
                freya_icons::lucide::check_check()
            } else {
                freya_icons::lucide::check()
            };
            let receipt_color: (u8, u8, u8) = if msg.fully_read {
                c.receipt_read
            } else {
                c.receipt_default
            };
            bubble_inner.child(reply_el).child(content_el).child(
                rect()
                    .horizontal()
                    .cross_align(Alignment::Center)
                    .spacing(4.)
                    .child(
                        label()
                            .text(msg.timestamp.clone())
                            .font_size(11.)
                            .color(c.timestamp_me),
                    )
                    .child(
                        svg(receipt_icon)
                            .color(receipt_color)
                            .width(Size::px(13.))
                            .height(Size::px(13.)),
                    ),
            )
        };

        // The action popup is rendered at the room-page level (outside the
        // VirtualScrollView) to avoid scroll-clipping the overlay.
        // MessageRow only records which row was triggered and its screen area.

        // ── Reactions pills (persistent, below bubble) ────────────────────
        let reactions_section = {
            let msg_eid = msg.event_id.clone();
            let action_tx_r = action_tx.clone();
            let mut pills_row = rect()
                .horizontal()
                .spacing(4.)
                .padding(Gaps::new(4., 0., 0., 0.))
                .cross_align(Alignment::Center);
            for reaction in &msg.reactions {
                let key = reaction.key.clone();
                let count = reaction.count;
                let reacted = reaction.reacted_by_me;
                let eid = msg_eid.clone();
                let tx = action_tx_r.clone();
                let pill_bg: (u8, u8, u8) = if reacted {
                    c.reaction_active_bg
                } else {
                    c.reaction_default_bg
                };
                let pill_text_color: (u8, u8, u8) = if reacted {
                    c.reaction_active_text
                } else {
                    c.reaction_default_text
                };
                pills_row = pills_row.child(
                    rect()
                        .horizontal()
                        .cross_align(Alignment::Center)
                        .padding(Gaps::new(4., 10., 4., 10.))
                        .corner_radius(12.)
                        .background(pill_bg)
                        .on_press({
                            let key = key.clone();
                            move |_| {
                                if let Some(event_id) = eid.clone() {
                                    let _ = tx.send(MsgAction::React {
                                        event_id,
                                        key: key.clone(),
                                    });
                                }
                            }
                        })
                        .child(
                            label()
                                .text(format!("{} {}", key, count))
                                .font_size(13.)
                                .color(pill_text_color),
                        ),
                );
            }
            pills_row
        };

        // ── Bubble column ──────────────────────────────────────────────────
        // Right-click (desktop) / long-press (Android, handled on outer row)
        // writes to the shared action_popup state; the room page renders the overlay.
        let bubble_col = rect()
            .vertical()
            .on_secondary_down({
                let msg = msg.clone();
                move |_| {
                    if let Some(area) = *row_area.read() {
                        *action_popup.write() = Some((area, msg.clone()));
                    }
                }
            })
            .child(bubble_inner)
            .child(reactions_section);

        // ── Row (with avatar for others) ──────────────────────────────────
        let row = rect()
            .horizontal()
            .width(Size::fill())
            .padding(Gaps::new(2., 12., 2., 12.))
            .spacing(10.)
            .cross_align(Alignment::End)
            .main_align(if is_me {
                Alignment::End
            } else {
                Alignment::Start
            });

        let row = if !is_me && !is_dm {
            let avatar_key = format!("{}\x00{}", room_id, msg.sender);
            row.child(Avatar {
                size: 36.,
                bytes: None,
                initial: msg.sender_initial.to_string(),
                color: msg.sender_color,
                image_key: avatar_key.clone(),
                fetch_key: Some(avatar_key),
            })
        } else {
            row
        };

        // ── Read receipt avatars ──────────────────────────────────────────
        let read_receipt_row = if !msg.read_receipts.is_empty() {
            let msg_for_modal = msg.clone();
            let mut row = rect()
                .horizontal()
                .width(Size::fill())
                .main_align(Alignment::End)
                .padding(Gaps::new(1., 12., 1., 12.))
                .spacing(2.)
                .on_press(move |_| {
                    *detail_modal.write() = Some(msg_for_modal.clone());
                });
            for (uid, _ts) in msg.read_receipts.iter().take(5) {
                let initial = uid
                    .chars()
                    .nth(1)
                    .unwrap_or('?')
                    .to_uppercase()
                    .next()
                    .unwrap_or('?');
                let color = crate::utils::sender_color(uid);
                row = row.child(Avatar {
                    size: 16.,
                    bytes: None,
                    initial: initial.to_string(),
                    color,
                    image_key: uid.clone(),
                    fetch_key: None,
                });
            }
            if msg.read_receipts.len() > 5 {
                row = row.child(
                    rect()
                        .center()
                        .width(Size::px(16.))
                        .height(Size::px(16.))
                        .corner_radius(8.)
                        .background(c.overflow_badge_bg)
                        .child(
                            label()
                                .text(format!("+{}", msg.read_receipts.len() - 5))
                                .font_size(8.)
                                .color(c.on_primary),
                        ),
                );
            }
            row.into_element()
        } else {
            rect().into_element()
        };

        #[cfg(not(target_os = "android"))]
        return rect()
            .vertical()
            .width(Size::fill())
            .on_sized(move |e: Event<SizedEventData>| {
                *row_area.write() = Some(e.area);
            })
            .child(date_separator)
            .child(row.child(bubble_col))
            .child(read_receipt_row);

        #[cfg(target_os = "android")]
        return rect()
            .vertical()
            .width(Size::fill())
            .on_sized(move |e: Event<SizedEventData>| {
                *row_area.write() = Some(e.area);
            })
            .on_touch_start(move |_: Event<TouchEventData>| {
                let next_gen = *press_gen.read() + 1;
                *press_gen.write() = next_gen;
                let msg = msg.clone();
                spawn(async move {
                    tokio::time::sleep(std::time::Duration::from_millis(350)).await;
                    if *press_gen.read() == next_gen {
                        if let Some(area) = *row_area.read() {
                            *action_popup.write() = Some((area, msg));
                        }
                    }
                });
            })
            .on_touch_move(move |_: Event<TouchEventData>| {
                *press_gen.write() += 1;
            })
            .on_touch_end(move |_: Event<TouchEventData>| {
                *press_gen.write() += 1;
            })
            .on_touch_cancel(move |_: Event<TouchEventData>| {
                *press_gen.write() += 1;
            })
            .child(date_separator)
            .child(row.child(bubble_col))
            .child(read_receipt_row);
    }
}
