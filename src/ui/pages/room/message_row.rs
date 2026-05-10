use std::sync::Arc;

use freya::prelude::*;
use matrix_sdk::ruma::events::room::message::MessageType;
use matrix_sdk_ui::timeline::{
    MembershipChange, TimelineDetails, TimelineItem, TimelineItemContent, VirtualTimelineItem,
};
use tokio::sync::mpsc::UnboundedSender;

use super::{MsgAction, Reaction, ReactionSender};
use crate::ui::components::{
    Avatar, MediaThumbnail, UserPopupInfo, UserPopupOverlay, ViewerSource,
};
use crate::utils::{format_timestamp, sender_color, use_app_colors};

pub struct MessageRow {
    pub room_id: String,
    pub item: Arc<TimelineItem>,
    pub date_label: Option<String>,
    pub my_user_id: Option<String>,
    pub action_tx: Arc<UnboundedSender<MsgAction>>,
    pub image_viewer: State<Option<String>>,
    pub action_popup: State<Option<Arc<TimelineItem>>>,
    pub detail_modal: State<Option<Arc<TimelineItem>>>,
    pub is_dm: bool,
}

impl PartialEq for MessageRow {
    fn eq(&self, other: &Self) -> bool {
        Arc::ptr_eq(&self.item, &other.item)
            && self.date_label == other.date_label
            && self.is_dm == other.is_dm
            && Arc::ptr_eq(&self.action_tx, &other.action_tx)
    }
}

impl Component for MessageRow {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let item = self.item.clone();
        let action_tx = self.action_tx.clone();
        let mut image_viewer = self.image_viewer;
        let is_dm = self.is_dm;
        let my_user_id = self.my_user_id.clone();
        let mut action_popup = self.action_popup;
        let mut detail_modal = self.detail_modal;
        let date_label = self.date_label.clone();

        let mut user_popup: State<Option<UserPopupInfo>> = use_state(|| None);
        #[cfg(target_os = "android")]
        let mut press_gen: State<u32> = use_state(|| 0u32);

        // ── Date separator ────────────────────────────────────────────────
        let date_separator = if let Some(lbl) = &date_label {
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
                        .child(label().text(lbl.clone()).font_size(12.).color(c.on_surface)),
                )
                .into_element()
        } else {
            rect().into_element()
        };

        // ── Read marker ───────────────────────────────────────────────────
        if let Some(VirtualTimelineItem::ReadMarker) = item.as_virtual() {
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
                .child(label().text("New messages").font_size(12.).color(c.primary))
                .child(
                    rect()
                        .width(Size::flex(1.0))
                        .height(Size::px(1.))
                        .background(c.primary),
                );
        }

        let Some(event) = item.as_event() else {
            return rect();
        };

        // ── Membership notice ─────────────────────────────────────────────
        if let TimelineItemContent::MembershipChange(m) = event.content() {
            let name = m
                .display_name()
                .unwrap_or_else(|| m.user_id().localpart().to_string());
            let text = match m.change() {
                Some(MembershipChange::Joined) | Some(MembershipChange::InvitationAccepted) => {
                    format!("{name} joined the room")
                }
                Some(MembershipChange::Left) => format!("{name} left the room"),
                Some(MembershipChange::Banned) | Some(MembershipChange::KickedAndBanned) => {
                    format!("{name} was banned")
                }
                Some(MembershipChange::Kicked) => format!("{name} was removed from the room"),
                Some(MembershipChange::Invited) => format!("{name} was invited"),
                _ => return rect(),
            };
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
                                .child(label().text(text).font_size(12.).color(c.on_surface_muted)),
                        ),
                );
        }

        // ── Require a message-like event ──────────────────────────────────
        let TimelineItemContent::MsgLike(msg_like) = event.content() else {
            return rect();
        };
        let Some(message) = msg_like.as_message() else {
            return rect();
        };

        // ── Derived fields ────────────────────────────────────────────────
        let sender_str = event.sender().to_string();
        let is_me = my_user_id.as_deref() == Some(sender_str.as_str());
        let event_id = event.event_id().map(|id| id.to_string());
        let timestamp = format_timestamp(event.timestamp());

        let (sender_name, sender_initial) = match event.sender_profile() {
            TimelineDetails::Ready(profile) => {
                let name = profile
                    .display_name
                    .clone()
                    .unwrap_or_else(|| sender_str.clone());
                let initial = name
                    .chars()
                    .next()
                    .unwrap_or('?')
                    .to_uppercase()
                    .next()
                    .unwrap_or('?');
                (name, initial)
            }
            _ => {
                let initial = sender_str
                    .chars()
                    .nth(1)
                    .unwrap_or('?')
                    .to_uppercase()
                    .next()
                    .unwrap_or('?');
                (sender_str.clone(), initial)
            }
        };
        let sender_color_val = sender_color(&sender_str);

        let read_receipts: Vec<(String, String)> = event
            .read_receipts()
            .iter()
            .filter(|(uid, _)| uid.as_str() != sender_str.as_str())
            .map(|(uid, receipt)| {
                let ts = receipt.ts.map(format_timestamp).unwrap_or_default();
                (uid.to_string(), ts)
            })
            .collect();
        let fully_read = !read_receipts.is_empty();

        let reactions: Vec<Reaction> = msg_like
            .reactions
            .iter()
            .map(|(key, senders)| {
                let count = senders.len();
                let reacted_by_me = my_user_id
                    .as_deref()
                    .map(|me| senders.iter().any(|(uid, _)| uid.as_str() == me))
                    .unwrap_or(false);
                let sender_list = senders
                    .iter()
                    .map(|(uid, info)| ReactionSender {
                        display: uid.localpart().to_string(),
                        user_id: uid.to_string(),
                        timestamp: format_timestamp(info.timestamp),
                    })
                    .collect();
                Reaction {
                    key: key.clone(),
                    count,
                    reacted_by_me,
                    senders: sender_list,
                }
            })
            .collect();

        let reply_to: Option<(String, String)> = if let Some(reply) = &msg_like.in_reply_to {
            if let TimelineDetails::Ready(embedded) = &reply.event {
                let sname = match &embedded.sender_profile {
                    TimelineDetails::Ready(p) => p
                        .display_name
                        .clone()
                        .unwrap_or_else(|| embedded.sender.to_string()),
                    _ => embedded.sender.to_string(),
                };
                let body = match &embedded.content {
                    TimelineItemContent::MsgLike(m) => m
                        .as_message()
                        .map(|msg| {
                            let b = msg.body();
                            if b.len() > 120 {
                                format!("{}…", &b[..120])
                            } else {
                                b.to_string()
                            }
                        })
                        .unwrap_or_else(|| "[message]".to_string()),
                    _ => "[message]".to_string(),
                };
                Some((sname, body))
            } else {
                Some((reply.event_id.to_string(), "[Loading…]".to_string()))
            }
        } else {
            None
        };

        let bubble_bg: (u8, u8, u8) = if is_me {
            c.primary
        } else {
            c.surface_container
        };

        // ── Reply quote ───────────────────────────────────────────────────
        let reply_el =
            if let Some((reply_sender, reply_body)) = &reply_to {
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

        // ── Content ───────────────────────────────────────────────────────
        let content_el = match message.msgtype() {
            MessageType::Text(t) => {
                let text_color = if is_me {
                    c.bubble_me_text
                } else {
                    c.bubble_other_text
                };
                rect()
                    .color(text_color)
                    .child(MarkdownViewer::new(t.body.clone()).color(text_color))
                    .into_element()
            }
            MessageType::Image(img) => {
                let key = event_id
                    .clone()
                    .unwrap_or_else(|| "img-unknown".to_string());
                let key_view = key.clone();
                let source = img.source.clone();
                let caption = {
                    let b = &img.body;
                    if b.starts_with("image")
                        || b.ends_with(".jpg")
                        || b.ends_with(".jpeg")
                        || b.ends_with(".png")
                        || b.ends_with(".gif")
                        || b.ends_with(".webp")
                    {
                        None
                    } else {
                        Some(b.clone()).filter(|s| !s.is_empty())
                    }
                };
                let blurhash = img.info.as_ref().and_then(|i| i.blurhash.clone());
                let thumbnail_source = img.info.as_ref().and_then(|i| i.thumbnail_source.clone());
                let text_color = if is_me {
                    c.bubble_me_text
                } else {
                    c.bubble_other_text
                };
                rect()
                    .vertical()
                    .spacing(6.)
                    .child(
                        rect()
                            .key(key.clone())
                            .width(Size::px(200.))
                            .height(Size::px(150.))
                            .corner_radius(8.)
                            .overflow(Overflow::Clip)
                            .on_press(move |_| {
                                *image_viewer.write() = Some(key_view.clone());
                            })
                            .child(MediaThumbnail {
                                item_key: key,
                                blurhash,
                                thumbnail_source: thumbnail_source
                                    .as_ref()
                                    .map(|s| ViewerSource::Remote(s.clone())),
                                fallback_source: Some(ViewerSource::Remote(source)),
                                thumb_size: Some((400, 300)),
                            }),
                    )
                    .maybe_child(
                        caption.map(|cap| label().text(cap).color(text_color).into_element()),
                    )
                    .into_element()
            }
            _ => return rect(),
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
                            .text(sender_name.clone())
                            .font_size(12.)
                            .font_weight(FontWeight::BOLD)
                            .color(sender_color_val),
                    )
                })
                .child(reply_el)
                .child(content_el)
                .child(
                    label()
                        .text(timestamp.clone())
                        .font_size(11.)
                        .color(c.on_surface_faint),
                )
        } else {
            let receipt_icon = if fully_read {
                freya_icons::lucide::check_check()
            } else {
                freya_icons::lucide::check()
            };
            let receipt_color: (u8, u8, u8) = if fully_read {
                c.receipt_read
            } else {
                c.receipt_default
            };
            bubble_inner.child(reply_el).child(content_el).child(
                rect()
                    .horizontal()
                    .cross_align(Alignment::Center)
                    .spacing(4.)
                    .child(label().text(timestamp).font_size(11.).color(c.timestamp_me))
                    .child(
                        svg(receipt_icon)
                            .color(receipt_color)
                            .width(Size::px(13.))
                            .height(Size::px(13.)),
                    ),
            )
        };

        // ── Reactions pills ───────────────────────────────────────────────
        let reactions_section = {
            let msg_eid = event_id.clone();
            let action_tx_r = action_tx.clone();
            let mut pills_row = rect()
                .horizontal()
                .spacing(4.)
                .padding(Gaps::new(4., 0., 0., 0.))
                .cross_align(Alignment::Center);
            for reaction in &reactions {
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

        // ── Bubble column ─────────────────────────────────────────────────
        let item_for_popup = item.clone();
        let item_for_detail = item.clone();
        let bubble_col = rect()
            .vertical()
            .on_secondary_down(move |_| {
                *action_popup.write() = Some(item_for_popup.clone());
            })
            .child(bubble_inner)
            .child(reactions_section);

        // ── Row with avatar ───────────────────────────────────────────────
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

        let room_id = self.room_id.clone();
        let row = if !is_me && !is_dm {
            let avatar_key = format!("{}\x00{}", room_id, sender_str);
            let sender_name_c = sender_name.clone();
            let sender_uid = sender_str.clone();
            let s_color = sender_color_val;
            let s_initial = sender_initial.to_string();
            row.child(
                rect()
                    .overflow(Overflow::Clip)
                    .corner_radius(18.)
                    .on_press(move |_| {
                        *user_popup.write() = Some(UserPopupInfo {
                            user_id: sender_uid.clone(),
                            display_name: sender_name_c.clone(),
                            initial: s_initial.clone(),
                            color: s_color,
                            avatar_url: None,
                        });
                    })
                    .child(Avatar {
                        size: 36.,
                        bytes: None,
                        initial: sender_initial.to_string(),
                        color: sender_color_val,
                        image_key: avatar_key.clone(),
                        fetch_key: Some(avatar_key),
                    }),
            )
        } else {
            row
        };

        // ── Read receipt avatars ──────────────────────────────────────────
        let read_receipt_row = if !read_receipts.is_empty() {
            let item_modal = item_for_detail.clone();
            let mut r = rect()
                .horizontal()
                .width(Size::fill())
                .main_align(Alignment::End)
                .padding(Gaps::new(1., 12., 1., 12.))
                .spacing(2.)
                .on_press(move |_| {
                    *detail_modal.write() = Some(item_modal.clone());
                });
            for (uid, _ts) in read_receipts.iter().take(5) {
                let initial = uid
                    .chars()
                    .nth(1)
                    .unwrap_or('?')
                    .to_uppercase()
                    .next()
                    .unwrap_or('?');
                let color = sender_color(uid);
                r = r.child(Avatar {
                    size: 16.,
                    bytes: None,
                    initial: initial.to_string(),
                    color,
                    image_key: uid.clone(),
                    fetch_key: None,
                });
            }
            if read_receipts.len() > 5 {
                r = r.child(
                    rect()
                        .center()
                        .width(Size::px(16.))
                        .height(Size::px(16.))
                        .corner_radius(8.)
                        .background(c.overflow_badge_bg)
                        .child(
                            label()
                                .text(format!("+{}", read_receipts.len() - 5))
                                .font_size(8.)
                                .color(c.on_primary),
                        ),
                );
            }
            r.into_element()
        } else {
            rect().into_element()
        };

        let popup_overlay = user_popup.read().clone().map(|info| {
            UserPopupOverlay {
                info,
                open: user_popup,
            }
            .into_element()
        });

        #[cfg(not(target_os = "android"))]
        return rect()
            .vertical()
            .width(Size::fill())
            .child(date_separator)
            .child(row.child(bubble_col))
            .child(read_receipt_row)
            .maybe_child(popup_overlay);

        #[cfg(target_os = "android")]
        return rect()
            .vertical()
            .width(Size::fill())
            .on_touch_start(move |_: Event<TouchEventData>| {
                let next_gen = *press_gen.read() + 1;
                *press_gen.write() = next_gen;
                let item_p = item.clone();
                spawn(async move {
                    tokio::time::sleep(std::time::Duration::from_millis(350)).await;
                    if *press_gen.read() == next_gen {
                        *action_popup.write() = Some(item_p);
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
            .child(read_receipt_row)
            .maybe_child(popup_overlay);
    }
}
