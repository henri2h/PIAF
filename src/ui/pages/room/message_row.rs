use std::sync::Arc;

use freya::prelude::*;

use crate::utils::avatars::AvatarSource;

use crate::ui::components::HoverableExt;
#[cfg(not(target_os = "android"))]
use crate::ui::components::use_fading;
use matrix_sdk::ruma::events::room::message::MessageType;
use matrix_sdk_ui::timeline::{
    EventSendState, MembershipChange, TimelineDetails, TimelineItem, TimelineItemContent,
    VirtualTimelineItem,
};
use tokio::sync::mpsc::UnboundedSender;

use super::MsgAction;
use super::ui_ctx::{RoomUiCtx, use_room_ui_ctx};
use crate::logging::RenderTimer;
use crate::ui::components::{Avatar, UserPopupInfo};
use crate::utils::{format_timestamp, id_color, use_app_colors};

/// Where a message sits in a run of consecutive messages from one sender
/// (see `timeline_view::group_positions`): the avatar and time show on the
/// last one, the name on the first.
#[derive(Clone, Copy, PartialEq, Debug)]
pub(super) struct GroupPosition {
    pub first: bool,
    pub last: bool,
}

/// Bubble corner radius, and the smaller one where bubbles of a group meet.
const BUBBLE_RADIUS: f32 = 18.;
const JOINED_RADIUS: f32 = 6.;
const AVATAR_SIZE: f32 = 32.;
const REACTION_HEIGHT: f32 = 22.;
/// How far the reactions overlap the bottom of their bubble.
const REACTION_OVERLAP: f32 = 8.;

/// Whether a tap on part of a message (image, reaction, avatar…) should act:
/// on Android not when it is the lift of a swipe-to-reply or a long press.
#[derive(Clone, Copy)]
pub(super) struct PressGuard {
    #[cfg(target_os = "android")]
    gesture: super::message_gesture::MessageGesture,
}

impl PressGuard {
    pub fn allows(&self) -> bool {
        #[cfg(target_os = "android")]
        return self.gesture.allows_press();
        #[cfg(not(target_os = "android"))]
        true
    }
}

pub struct MessageRow {
    pub room_id: String,
    pub item: Arc<TimelineItem>,
    pub date_label: Option<String>,
    pub group: GroupPosition,
    pub my_user_id: Option<String>,
    pub action_tx: Arc<UnboundedSender<MsgAction>>,
    pub is_dm: bool,
}

impl PartialEq for MessageRow {
    fn eq(&self, other: &Self) -> bool {
        Arc::ptr_eq(&self.item, &other.item)
            && self.date_label == other.date_label
            && self.group == other.group
            && self.is_dm == other.is_dm
            && Arc::ptr_eq(&self.action_tx, &other.action_tx)
    }
}

impl Component for MessageRow {
    fn render(&self) -> impl IntoElement {
        let _timer =
            RenderTimer::with_threshold("MessageRow", std::time::Duration::from_micros(200));
        let c = use_app_colors();
        let item = self.item.clone();
        let action_tx = self.action_tx.clone();
        let RoomUiCtx {
            image_viewer,
            mut action_popup,
            mut detail_modal,
            mut user_popup,
            ..
        } = use_room_ui_ctx();
        let reply_info = use_room_ui_ctx().reply_info;
        #[cfg(not(target_os = "android"))]
        let mut hovered = use_state(|| false);
        #[cfg(not(target_os = "android"))]
        let hover_bar_opacity = use_fading(hovered.read().then_some(()), 120).map(|(_, o)| o);
        let is_dm = self.is_dm;
        let my_user_id = self.my_user_id.clone();
        let date_label = self.date_label.clone();
        #[cfg(target_os = "android")]
        let gesture = super::message_gesture::use_message_gesture();
        let guard = PressGuard {
            #[cfg(target_os = "android")]
            gesture,
        };
        #[cfg(target_os = "android")]
        let compose_focus = use_room_ui_ctx().compose_focus;

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

        let sender_name = crate::utils::room_preview::sender_name(event);
        let sender_color_val = id_color(&sender_str);

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
        let send_state = event.send_state().cloned();

        let reactions = super::reactions(&msg_like.reactions, my_user_id.as_deref());

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
                            let truncated: String = b.chars().take(120).collect();
                            if truncated.len() < b.len() {
                                format!("{truncated}…")
                            } else {
                                truncated
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

        // ── Reply quote: accent bar, sender, two lines of the message ──────
        let reply_el = if let Some((reply_sender, reply_body)) = &reply_to {
            let (bg, accent, text) = if is_me {
                (c.reply_me_bg, c.reply_me_sender, c.reply_me_text)
            } else {
                (c.reply_other_bg, c.reply_other_sender, c.reply_other_text)
            };
            rect()
                .width(Size::fill())
                .padding(Gaps::new(0., 0., 4., 0.))
                .child(
                    rect()
                        .vertical()
                        .width(Size::fill())
                        .padding(Gaps::new(6., 10., 6., 10.))
                        .corner_radius(10.)
                        .overflow(Overflow::Clip)
                        .background(bg)
                        .border(
                            Border::new()
                                .fill(accent)
                                .width(BorderWidth {
                                    top: 0.,
                                    right: 0.,
                                    bottom: 0.,
                                    left: 3.,
                                })
                                .alignment(BorderAlignment::Inner),
                        )
                        .spacing(2.)
                        .child(
                            label()
                                .width(Size::fill())
                                .text(reply_sender.clone())
                                .max_lines(1)
                                .text_overflow(TextOverflow::Ellipsis)
                                .font_size(12.)
                                .font_weight(FontWeight::BOLD)
                                .color(accent),
                        )
                        .child(
                            label()
                                .width(Size::fill())
                                .text(reply_body.clone())
                                .max_lines(2)
                                .text_overflow(TextOverflow::Ellipsis)
                                .font_size(13.)
                                .color(text),
                        ),
                )
                .into_element()
        } else {
            rect().into_element()
        };

        // ── Content ───────────────────────────────────────────────────────
        let Some(content_el) = super::message_content::message_content(
            &message,
            event_id.clone(),
            is_me,
            image_viewer,
            guard,
            c,
        ) else {
            return rect();
        };

        // ── Bubble ────────────────────────────────────────────────────────
        let group = self.group;
        let pending_or_failed = matches!(
            send_state,
            Some(EventSendState::NotSentYet { .. } | EventSendState::SendingFailed { .. })
        );
        // One time per group, on its last bubble; a send problem always shows.
        let show_meta = group.last || pending_or_failed;
        // Images fill their bubble edge to edge; the text around them keeps padding.
        let edge_to_edge = matches!(message.msgtype(), MessageType::Image(_));
        // Nothing but the image: no bubble around it, the time over its corner.
        let shows_name = !is_me && !is_dm && group.first;
        let media_only = match message.msgtype() {
            MessageType::Image(img) => {
                crate::utils::timeline_media::caption(&img.body).is_none()
                    && reply_to.is_none()
                    && !shows_name
            }
            _ => false,
        };
        let padded = move |el: Rect| {
            if edge_to_edge {
                el.padding(Gaps::new(6., 12., 0., 12.))
            } else {
                el
            }
        };
        let top_inner = if group.first {
            BUBBLE_RADIUS
        } else {
            JOINED_RADIUS
        };
        let bottom_inner = if group.last {
            BUBBLE_RADIUS
        } else {
            JOINED_RADIUS
        };
        // The corners on the sender's side are smaller where bubbles join.
        let radius = if is_me {
            CornerRadius::new(BUBBLE_RADIUS, top_inner, bottom_inner, BUBBLE_RADIUS)
        } else {
            CornerRadius::new(top_inner, BUBBLE_RADIUS, BUBBLE_RADIUS, bottom_inner)
        };
        let has_reply = reply_to.is_some();
        let reply_el = if has_reply {
            padded(rect().child(reply_el)).into_element()
        } else {
            reply_el
        };

        let bubble_inner = rect()
            .vertical()
            .max_width(Size::percent(82.))
            .padding(if edge_to_edge {
                Gaps::new(0., 0., 6., 0.)
            } else {
                Gaps::new(8., 12., 8., 12.)
            })
            .corner_radius(radius)
            .maybe(!media_only, |b| b.background(bubble_bg))
            .maybe(edge_to_edge, |b| b.overflow(Overflow::Clip))
            .spacing(2.);
        let bubble_inner = if media_only {
            bubble_inner.padding(Gaps::new_all(0.))
        } else {
            bubble_inner
        };
        // The time over an image's bottom right corner, on a dark pill.
        let over_image = |meta: Rect| {
            rect()
                .position(Position::new_absolute().bottom(6.).right(6.))
                .padding(Gaps::new(2., 8., 2., 8.))
                .corner_radius(10.)
                .background((0u8, 0u8, 0u8, 140u8))
                .child(meta)
        };

        let bubble_inner = if !is_me {
            bubble_inner
                .maybe(!is_dm && group.first, |b| {
                    b.child(padded(
                        rect().child(
                            label()
                                .text(sender_name.clone())
                                .font_size(12.)
                                .font_weight(FontWeight::BOLD)
                                .color(sender_color_val),
                        ),
                    ))
                })
                .child(reply_el)
                .child(content_el)
                .maybe_child(show_meta.then(|| {
                    let color = if media_only {
                        (255, 255, 255)
                    } else {
                        c.on_surface_faint
                    };
                    let meta =
                        rect().child(label().text(timestamp.clone()).font_size(11.).color(color));
                    if media_only {
                        over_image(meta)
                    } else {
                        padded(meta)
                    }
                }))
        } else {
            let (receipt_icon, receipt_color) = match &send_state {
                Some(EventSendState::NotSentYet { .. }) => {
                    (freya_icons::lucide::clock(), c.on_surface_muted)
                }
                Some(EventSendState::SendingFailed { .. }) => {
                    (freya_icons::lucide::circle_alert(), c.error)
                }
                _ => {
                    if fully_read {
                        (freya_icons::lucide::check_check(), c.receipt_read)
                    } else {
                        (freya_icons::lucide::check(), c.receipt_default)
                    }
                }
            };
            bubble_inner
                .child(reply_el)
                .child(content_el)
                .maybe_child(show_meta.then(|| {
                    let time_color = if media_only {
                        (255, 255, 255)
                    } else {
                        c.timestamp_me
                    };
                    let place = move |meta: Rect| {
                        if media_only {
                            over_image(meta)
                        } else {
                            padded(meta)
                        }
                    };
                    place(
                        rect()
                            .horizontal()
                            .cross_align(Alignment::Center)
                            .spacing(4.)
                            .child(label().text(timestamp).font_size(11.).color(time_color))
                            .child(
                                SvgViewer::new(receipt_icon)
                                    .color(receipt_color)
                                    .width(Size::px(13.))
                                    .height(Size::px(13.)),
                            ),
                    )
                }))
        };

        // ── Reactions pills ───────────────────────────────────────────────
        let reactions_section = {
            let msg_eid = event_id.clone();
            let action_tx_r = action_tx.clone();
            let mut pills_row = rect()
                .horizontal()
                .spacing(4.)
                .padding(Gaps::new(0., 8., 0., 8.))
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
                        .height(Size::px(REACTION_HEIGHT))
                        .padding(Gaps::new(0., 8., 0., 8.))
                        .corner_radius(REACTION_HEIGHT / 2.)
                        .background(pill_bg)
                        // A ring in the page colour separates it from the bubble.
                        .border(Border::new().fill(c.surface).width(2.))
                        .on_press({
                            let key = key.clone();
                            move |_| {
                                if !guard.allows() {
                                    return;
                                }
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
                        )
                        .hoverable(
                            Size::auto(),
                            Size::px(REACTION_HEIGHT),
                            REACTION_HEIGHT / 2.,
                        ),
                );
            }
            // Overlaps the bubble's bottom edge, drawn over it. Negative
            // margins are ignored, so the holder is shorter than the pills and
            // `offset_y` (which moves its children) lifts them into the bubble.
            rect()
                .height(Size::px(REACTION_HEIGHT - REACTION_OVERLAP))
                .offset_y(-REACTION_OVERLAP)
                .layer(1)
                .child(pills_row)
        };

        // ── Bubble column ─────────────────────────────────────────────────
        let item_for_popup = item.clone();
        let item_for_detail = item.clone();
        let bubble_col = rect()
            .vertical()
            .on_secondary_down(move |_| {
                *action_popup.write() = Some(item_for_popup.clone());
            })
            .main_align(if is_me {
                Alignment::End
            } else {
                Alignment::Start
            })
            .cross_align(if is_me {
                Alignment::End
            } else {
                Alignment::Start
            })
            .child(bubble_inner)
            .maybe_child((!reactions.is_empty()).then_some(reactions_section));

        // ── Row with avatar ───────────────────────────────────────────────
        let row = rect()
            .horizontal()
            .width(Size::fill())
            // A group's bubbles sit close; groups get a gap between them.
            .padding(Gaps::new(if group.first { 6. } else { 1. }, 8., 1., 8.))
            .spacing(8.)
            .cross_align(Alignment::End)
            .main_align(if is_me {
                Alignment::End
            } else {
                Alignment::Start
            });

        let room_id = self.room_id.clone();
        let row = if !is_me && !is_dm && !group.last {
            // Avatar only on a group's last bubble; keep its column aligned.
            row.child(rect().width(Size::px(AVATAR_SIZE)))
        } else if !is_me && !is_dm {
            let sender_name_c = sender_name.clone();
            let sender_uid = sender_str.clone();
            let sender_avatar = AvatarSource::member(&room_id, &sender_str);
            let popup_avatar = sender_avatar.clone();
            row.child(
                rect()
                    .overflow(Overflow::Clip)
                    .corner_radius(AVATAR_SIZE / 2.)
                    .on_press(move |_| {
                        if !guard.allows() {
                            return;
                        }
                        *user_popup.write() = Some(UserPopupInfo {
                            user_id: sender_uid.clone(),
                            display_name: sender_name_c.clone(),
                            avatar: Some(popup_avatar.clone()),
                        });
                    })
                    .child(Avatar {
                        size: AVATAR_SIZE,
                        source: Some(sender_avatar),
                        name: sender_name.clone(),
                        color: sender_color_val,
                    })
                    .hoverable(Size::auto(), Size::auto(), AVATAR_SIZE / 2.),
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
                    if !guard.allows() {
                        return;
                    }
                    *detail_modal.write() = Some(item_modal.clone());
                });
            for (uid, _ts) in read_receipts.iter().take(5) {
                let color = id_color(uid);
                r = r.child(Avatar {
                    size: 16.,
                    source: Some(AvatarSource::member(&self.room_id, uid)),
                    name: uid.clone(),
                    color,
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
            r.hoverable(Size::fill(), Size::auto(), 0.)
        } else {
            rect().into_element()
        };

        // ── Inline cancel row for failed sends ───────────────────────────
        let failed_send_row = if matches!(&send_state, Some(EventSendState::SendingFailed { .. })) {
            if let Some(handle) = event.local_echo_send_handle() {
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .main_align(Alignment::End)
                    .padding(Gaps::new(1., 12., 2., 12.))
                    .spacing(8.)
                    .child(label().text("Failed to send").font_size(11.).color(c.error))
                    .child(
                        rect()
                            .corner_radius(4.)
                            .padding(Gaps::new(2., 8., 2., 8.))
                            .background(c.error)
                            .on_press(move |_| {
                                if !guard.allows() {
                                    return;
                                }
                                let h = handle.clone();
                                tokio::task::spawn(async move {
                                    let _ = h.abort().await;
                                });
                            })
                            .child(
                                label()
                                    .text("Discard")
                                    .font_size(11.)
                                    .color((255u8, 255u8, 255u8)),
                            )
                            .hoverable(Size::auto(), Size::auto(), 4.),
                    )
                    .into_element()
            } else {
                rect().into_element()
            }
        } else {
            rect().into_element()
        };

        #[cfg(not(target_os = "android"))]
        let hover_bar = hover_bar_opacity.map(|opacity| {
            let tx = action_tx.clone();
            let react_eid = event_id.clone();
            let reply_eid = event_id.clone();
            let reply_sender = sender_name.clone();
            let reply_body = crate::utils::room_preview::reply_preview(message.msgtype());
            let item_more = item.clone();
            let bar = super::message_hover_bar::hover_bar(
                c,
                move |key| {
                    if let Some(event_id) = react_eid.clone() {
                        let _ = tx.send(MsgAction::React { event_id, key });
                    }
                },
                move || {
                    if let Some(event_id) = reply_eid.clone() {
                        let mut reply_info = reply_info;
                        reply_info.set(Some((event_id, reply_sender.clone(), reply_body.clone())));
                    }
                },
                move || action_popup.set(Some(item_more.clone())),
            );
            rect().opacity(opacity).child(bar)
        });

        #[cfg(not(target_os = "android"))]
        return rect()
            .vertical()
            .width(Size::fill())
            .on_pointer_over(move |_| {
                if !*hovered.peek() {
                    hovered.set(true);
                }
            })
            .on_pointer_out(move |_| {
                if *hovered.peek() {
                    hovered.set(false);
                }
            })
            .child(date_separator)
            .child(if is_me {
                // Toolbar on the inner side of the bubble.
                row.maybe_child(hover_bar).child(bubble_col)
            } else {
                row.child(bubble_col).maybe_child(hover_bar)
            })
            .child(failed_send_row)
            .child(read_receipt_row);

        #[cfg(target_os = "android")]
        {
            let item_popup = item.clone();
            let reply_body = crate::utils::room_preview::reply_preview(message.msgtype());
            let on_reply = event_id.clone().map(|event_id| {
                move || {
                    let (mut reply_info, mut compose_focus) = (reply_info, compose_focus);
                    reply_info.set(Some((
                        event_id.clone(),
                        sender_name.clone(),
                        reply_body.clone(),
                    )));
                    *compose_focus.write() += 1;
                }
            });
            return rect()
                .vertical()
                .width(Size::fill())
                .child(date_separator)
                .child(gesture.attach(
                    rect().width(Size::fill()),
                    row.child(bubble_col),
                    c,
                    move || {
                        let mut action_popup = action_popup;
                        action_popup.set(Some(item_popup.clone()));
                    },
                    on_reply,
                ))
                .child(failed_send_row)
                .child(read_receipt_row);
        }
    }
}
