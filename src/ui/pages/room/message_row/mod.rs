mod body;
mod content;
mod meta;
mod notices;
mod reactions;
mod receipts;
mod reply_quote;

use std::sync::Arc;

use freya::prelude::*;
use matrix_sdk::ruma::events::room::message::MessageType;
use matrix_sdk_ui::timeline::{
    EventSendState, EventTimelineItem, Message, MsgLikeContent, MsgLikeKind, TimelineItem,
    TimelineItemContent, VirtualTimelineItem,
};
use tokio::sync::mpsc::UnboundedSender;

#[cfg(not(target_os = "android"))]
use crate::ui::components::use_fading;
use crate::ui::components::{Avatar, HoverableExt, UserPopupInfo};
use crate::utils::avatars::AvatarSource;
use crate::utils::const_values::AppColors;
use crate::utils::room_preview::reply_preview;
use crate::utils::timeline_media::forward_split;
use crate::utils::{format_timestamp, id_color, use_app_colors};

use super::MsgAction;
use super::ui_ctx::{ReplyTo, RoomUiCtx, use_room_ui_ctx};
use crate::logging::RenderTimer;
use content::{ContentCtx, message_content};
use meta::Meta;
use notices::{date_separator, membership_text, notice, placeholder, read_marker};
use reactions::reactions_row;
use receipts::{failed_send_row, read_receipts_row};
use reply_quote::Quote;

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
        let ui = use_room_ui_ctx();
        #[cfg(not(target_os = "android"))]
        let mut hovered = use_state(|| false);
        #[cfg(not(target_os = "android"))]
        let hover_bar_opacity = use_fading(hovered.read().then_some(()), 120).map(|(_, o)| o);
        #[cfg(target_os = "android")]
        let gesture = super::message_gesture::use_message_gesture();
        let guard = PressGuard {
            #[cfg(target_os = "android")]
            gesture,
        };

        let date = self.date_label.clone().map(|d| date_separator(d, c));
        if let Some(VirtualTimelineItem::ReadMarker) = self.item.as_virtual() {
            return read_marker(c);
        }
        let Some(event) = self.item.as_event() else {
            return rect().into_element();
        };
        let with_date = |row: Element| {
            rect()
                .vertical()
                .width(Size::fill())
                .maybe_child(date.clone())
                .child(row)
                .into_element()
        };
        match event.content() {
            TimelineItemContent::MembershipChange(m) => match membership_text(m) {
                Some(text) => with_date(notice(text, c)),
                None => rect().into_element(),
            },
            TimelineItemContent::MsgLike(msg_like) => {
                let Some((bubble, quote)) = self.bubble(event, msg_like, ui, guard, c) else {
                    return rect().into_element();
                };
                let message = msg_like.as_message();
                let row = self.bubble_row(event, bubble, quote.is_some(), ui, guard);
                let readers = readers(event);
                let failed = matches!(
                    event.send_state(),
                    Some(EventSendState::SendingFailed { .. })
                );

                #[cfg(not(target_os = "android"))]
                let row = {
                    let hover_bar = hover_bar_opacity.and_then(|opacity| {
                        let bar = self.hover_bar(event, message.as_ref()?, ui, c);
                        Some(rect().opacity(opacity).child(bar))
                    });
                    let is_me = self.is_me(event);
                    let (row, bubble_col) = row;
                    rect()
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
                        .maybe_child(quote)
                        // The toolbar on the inner side of the bubble.
                        .child(if is_me {
                            row.maybe_child(hover_bar).child(bubble_col)
                        } else {
                            row.child(bubble_col).maybe_child(hover_bar)
                        })
                };
                #[cfg(target_os = "android")]
                let row = {
                    let (row, bubble_col) = row;
                    let action_popup = ui.action_popup;
                    let item = self.item.clone();
                    let on_reply = message
                        .as_ref()
                        .and_then(|m| reply_target(event, m))
                        .map(|reply_to| move || ui.reply(reply_to.clone()));
                    rect().vertical().width(Size::fill()).child(
                        gesture.attach(
                            rect().width(Size::fill()),
                            // The quote moves with the bubble on a swipe.
                            rect()
                                .vertical()
                                .width(Size::fill())
                                .maybe_child(quote)
                                .child(row.child(bubble_col)),
                            c,
                            move || {
                                let mut action_popup = action_popup;
                                action_popup.set(Some(item.clone()))
                            },
                            on_reply,
                        ),
                    )
                };

                with_date(
                    row.maybe_child(failed.then(|| failed_send_row(event, guard, c)).flatten())
                        .maybe_child((!readers.is_empty()).then(|| {
                            read_receipts_row(
                                &readers,
                                &self.room_id,
                                self.item.clone(),
                                ui.detail_modal,
                                guard,
                                c,
                            )
                        }))
                        .into_element(),
                )
            }
            _ => rect().into_element(),
        }
    }
}

impl MessageRow {
    fn is_me(&self, event: &EventTimelineItem) -> bool {
        self.my_user_id.as_deref() == Some(event.sender().as_str())
    }

    /// The bubble with its reactions; `None` for message kinds not shown.
    fn bubble(
        &self,
        event: &EventTimelineItem,
        msg_like: &MsgLikeContent,
        ui: RoomUiCtx,
        guard: PressGuard,
        c: AppColors,
    ) -> Option<(Element, Option<Element>)> {
        let is_me = self.is_me(event);
        let group = self.group;
        let sender_name = crate::utils::room_preview::sender_name(event);
        let event_id = event.event_id().map(|id| id.to_string());
        let muted = if is_me {
            c.timestamp_me
        } else {
            c.on_surface_muted
        };
        let (content, message) = match &msg_like.kind {
            MsgLikeKind::Message(message) => (
                message_content(
                    message,
                    ContentCtx {
                        room_id: &self.room_id,
                        event_id: event_id.clone(),
                        sender_name: &sender_name,
                        is_me,
                        image_viewer: ui.image_viewer,
                        guard,
                    },
                    c,
                )?,
                Some(message),
            ),
            MsgLikeKind::Redacted => (
                placeholder(freya_icons::lucide::trash_2(), "Message deleted", muted),
                None,
            ),
            MsgLikeKind::UnableToDecrypt(_) => (
                placeholder(
                    freya_icons::lucide::lock(),
                    "Unable to decrypt this message",
                    muted,
                ),
                None,
            ),
            _ => return None,
        };
        let msgtype = message.map(|m| m.msgtype());
        // Bridged from a forward: marked compactly, the marker kept out of the body.
        let forwarded = message.is_some_and(|m| forward_split(m.msgtype()).0);
        let reply = msg_like
            .in_reply_to
            .as_ref()
            .map(|reply| Quote::new(reply).render(&self.room_id, is_me, guard, c));

        let pending_or_failed = matches!(
            event.send_state(),
            Some(EventSendState::NotSentYet { .. } | EventSendState::SendingFailed { .. })
        );
        // One time per group, on its last bubble; a send problem always shows.
        let show_meta = group.last || pending_or_failed;
        let shows_name = !is_me && !self.is_dm && group.first;
        // Images fill their bubble edge to edge; the text around them keeps padding.
        let edge_to_edge = matches!(msgtype, Some(MessageType::Image(_)));
        // Nothing but the image: no bubble around it, the time over its corner.
        let media_only = match msgtype {
            Some(msgtype @ MessageType::Image(img)) => {
                crate::utils::timeline_media::caption(
                    forward_split(msgtype).1,
                    img.filename.as_deref(),
                )
                .is_none()
                    && !shows_name
                    && !forwarded
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
        let meta = show_meta.then(|| {
            let meta = Meta {
                timestamp: format_timestamp(event.timestamp()),
                edited: message.is_some_and(Message::is_edited),
                mine: is_me.then(|| !readers(event).is_empty()),
                send_state: event.send_state().cloned(),
            }
            .render(media_only, c);
            if media_only {
                // On a dark pill over the image's bottom right corner.
                rect()
                    .position(Position::new_absolute().bottom(6.).right(6.))
                    // Above the image, which is nested deeper (layers add up).
                    .layer(100)
                    .padding(Gaps::new(2., 8., 2., 8.))
                    .corner_radius(10.)
                    .background((0u8, 0u8, 0u8, 140u8))
                    .child(meta)
            } else {
                padded(meta)
            }
        });

        let corner = |open: bool| if open { BUBBLE_RADIUS } else { JOINED_RADIUS };
        let (top_inner, bottom_inner) = (corner(group.first), corner(group.last));
        // The corners on the sender's side are smaller where bubbles join.
        let radius = if is_me {
            CornerRadius::new(BUBBLE_RADIUS, top_inner, bottom_inner, BUBBLE_RADIUS)
        } else {
            CornerRadius::new(top_inner, BUBBLE_RADIUS, BUBBLE_RADIUS, bottom_inner)
        };
        let bubble = rect()
            .vertical()
            .max_width(Size::percent(82.))
            .padding(if media_only {
                Gaps::new_all(0.)
            } else if edge_to_edge {
                Gaps::new(0., 0., 6., 0.)
            } else {
                Gaps::new(8., 12., 8., 12.)
            })
            .corner_radius(radius)
            .maybe(!media_only, |b| {
                b.background(if is_me {
                    c.primary
                } else {
                    c.surface_container
                })
            })
            .maybe(edge_to_edge, |b| b.overflow(Overflow::Clip))
            .spacing(2.)
            .maybe_child(shows_name.then(|| {
                padded(
                    rect().child(
                        label()
                            .text(sender_name.clone())
                            .font_size(12.)
                            .font_weight(FontWeight::BOLD)
                            .color(id_color(event.sender().as_str())),
                    ),
                )
            }))
            .maybe_child(forwarded.then(|| padded(forwarded_label(muted))))
            .child(content)
            .maybe_child(meta);

        let reactions = super::reactions(&msg_like.reactions, self.my_user_id.as_deref());
        let mut action_popup = ui.action_popup;
        let item = self.item.clone();
        let align = if is_me {
            Alignment::End
        } else {
            Alignment::Start
        };
        Some((
            rect()
                .vertical()
                .on_secondary_down(move |_| action_popup.set(Some(item.clone())))
                .main_align(align.clone())
                .cross_align(align)
                .child(bubble)
                .maybe_child(
                    (!reactions.is_empty())
                        .then(|| reactions_row(&reactions, event_id, &self.action_tx, guard, c)),
                )
                .into_element(),
            reply.map(|quote| self.quote_row(event, quote)),
        ))
    }

    /// The quote line above the bubble, lined up with the bubble's edge.
    fn quote_row(&self, event: &EventTimelineItem, quote: Element) -> Element {
        let is_me = self.is_me(event);
        // Others' bubbles start after the avatar column (group rooms).
        let avatar_column = if is_me || self.is_dm {
            0.
        } else {
            AVATAR_SIZE + 8.
        };
        rect()
            .horizontal()
            .width(Size::fill())
            .padding(Gaps::new(
                if self.group.first { 6. } else { 2. },
                8.,
                0.,
                8. + avatar_column,
            ))
            .main_align(if is_me {
                Alignment::End
            } else {
                Alignment::Start
            })
            .child(quote)
            .into_element()
    }

    /// The row holding the bubble: the sender's avatar on a group's last
    /// bubble in group rooms. Returns `(row, bubble)` for the platform to
    /// place its extras.
    fn bubble_row(
        &self,
        event: &EventTimelineItem,
        bubble: Element,
        quoted: bool,
        ui: RoomUiCtx,
        guard: PressGuard,
    ) -> (Rect, Element) {
        let is_me = self.is_me(event);
        let group = self.group;
        let row = rect()
            .horizontal()
            .width(Size::fill())
            // A group's bubbles sit close; groups get a gap between them
            // (above the quote line, when there is one: its connector meets
            // the bubble).
            .padding(Gaps::new(
                match (quoted, group.first) {
                    (true, _) => 0.,
                    (false, true) => 6.,
                    (false, false) => 1.,
                },
                8.,
                1.,
                8.,
            ))
            .spacing(8.)
            .cross_align(Alignment::End)
            .main_align(if is_me {
                Alignment::End
            } else {
                Alignment::Start
            });
        if is_me || self.is_dm {
            return (row, bubble);
        }
        if !group.last {
            // Avatar only on a group's last bubble; keep its column aligned.
            return (row.child(rect().width(Size::px(AVATAR_SIZE))), bubble);
        }
        let name = crate::utils::room_preview::sender_name(event);
        let user_id = event.sender().to_string();
        let source = AvatarSource::member(&self.room_id, &user_id);
        let popup = UserPopupInfo {
            user_id: user_id.clone(),
            display_name: name.clone(),
            avatar: Some(source.clone()),
        };
        let mut user_popup = ui.user_popup;
        let avatar = rect()
            .overflow(Overflow::Clip)
            .corner_radius(AVATAR_SIZE / 2.)
            .on_press(move |_| {
                if guard.allows() {
                    user_popup.set(Some(popup.clone()));
                }
            })
            .child(Avatar {
                size: AVATAR_SIZE,
                source: Some(source),
                name,
                color: id_color(&user_id),
            })
            .hoverable(Size::auto(), Size::auto(), AVATAR_SIZE / 2.);
        (row.child(avatar), bubble)
    }

    /// Desktop toolbar beside a hovered bubble: quick reactions, reply, more.
    #[cfg(not(target_os = "android"))]
    fn hover_bar(
        &self,
        event: &EventTimelineItem,
        message: &Message,
        ui: RoomUiCtx,
        c: AppColors,
    ) -> Element {
        let tx = self.action_tx.clone();
        let event_id = event.event_id().map(|id| id.to_string());
        let reply_to = reply_target(event, message);
        let item = self.item.clone();
        let mut action_popup = ui.action_popup;
        super::message_hover_bar::hover_bar(
            c,
            move |key| {
                if let Some(event_id) = event_id.clone() {
                    let _ = tx.send(MsgAction::React { event_id, key });
                }
            },
            move || {
                if let Some(reply_to) = reply_to.clone() {
                    ui.reply(reply_to);
                }
            },
            move || action_popup.set(Some(item.clone())),
        )
    }
}

/// "↷ Forwarded", one small line.
fn forwarded_label(color: (u8, u8, u8)) -> Rect {
    rect()
        .horizontal()
        .cross_align(Alignment::Center)
        .spacing(4.)
        .child(
            SvgViewer::new(freya_icons::lucide::forward())
                .color(color)
                .width(Size::px(12.))
                .height(Size::px(12.)),
        )
        .child(
            label()
                .text("Forwarded")
                .font_size(12.)
                .font_slant(FontSlant::Italic)
                .color(color),
        )
}

/// What the composer quotes when replying to `message`.
pub(super) fn reply_target(event: &EventTimelineItem, message: &Message) -> Option<ReplyTo> {
    Some(ReplyTo {
        event_id: event.event_id()?.to_string(),
        sender: crate::utils::room_preview::sender_name(event),
        body: reply_preview(message.msgtype()),
    })
}

/// Who else read up to this event.
fn readers(event: &EventTimelineItem) -> Vec<String> {
    event
        .read_receipts()
        .keys()
        .filter(|uid| *uid != event.sender())
        .map(|uid| uid.to_string())
        .collect()
}
