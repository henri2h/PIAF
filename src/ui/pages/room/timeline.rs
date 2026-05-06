use std::collections::HashMap;
use std::sync::Arc;

use matrix_sdk::ruma::events::room::message::MessageType;
use matrix_sdk_ui::timeline::{MembershipChange, TimelineDetails, TimelineItemContent};

use crate::utils::{format_date_key, format_date_label, format_timestamp, sender_color};

use super::{MessageContent, MessageItem, Reaction, ReactionSender};

pub(super) fn item_to_message(
    item: &Arc<matrix_sdk_ui::timeline::TimelineItem>,
    my_user_id: Option<&str>,
) -> Option<MessageItem> {
    if let Some(matrix_sdk_ui::timeline::VirtualTimelineItem::ReadMarker) = item.as_virtual() {
        return Some(MessageItem {
            event_id: None,
            date_key: String::new(),
            date_label: None,
            reply_to: None,
            sender: String::new(),
            sender_name: String::new(),
            sender_initial: '?',
            sender_color: (128, 128, 128),
            content: MessageContent::ReadMarker,
            timestamp: String::new(),
            is_me: false,
            read_receipts: vec![],
            seen_by: vec![],
            fully_read: false,
            reactions: vec![],
        });
    }

    let event = item.as_event()?;

    if let TimelineItemContent::MembershipChange(m) = event.content() {
        let name = m
            .display_name()
            .unwrap_or_else(|| m.user_id().localpart().to_string());
        let notice_text = match m.change() {
            Some(MembershipChange::Joined) | Some(MembershipChange::InvitationAccepted) => {
                format!("{name} joined the room")
            }
            Some(MembershipChange::Left) => format!("{name} left the room"),
            Some(MembershipChange::Banned) | Some(MembershipChange::KickedAndBanned) => {
                format!("{name} was banned")
            }
            Some(MembershipChange::Kicked) => format!("{name} was removed from the room"),
            Some(MembershipChange::Invited) => format!("{name} was invited"),
            _ => return None,
        };
        return Some(MessageItem {
            event_id: event.event_id().map(|id| id.to_string()),
            date_key: format_date_key(event.timestamp()),
            date_label: None,
            reply_to: None,
            sender: String::new(),
            sender_name: String::new(),
            sender_initial: '?',
            sender_color: (128, 128, 128),
            content: MessageContent::Notice(notice_text),
            timestamp: format_timestamp(event.timestamp()),
            is_me: false,
            read_receipts: vec![],
            seen_by: vec![],
            fully_read: false,
            reactions: vec![],
        });
    }

    let (
        msg_type,
        event_id,
        date_key,
        reply_to,
        sender,
        sender_name,
        sender_initial,
        sender_color_val,
        timestamp,
        is_me,
        read_receipts,
        reactions,
    ) = {
        let msg_like = match event.content() {
            TimelineItemContent::MsgLike(m) => m,
            _ => return None,
        };
        let message = msg_like.as_message()?;

        let event_id = event.event_id().map(|id| id.to_string());
        let date_key = format_date_key(event.timestamp());

        let reactions: Vec<Reaction> = msg_like
            .reactions
            .iter()
            .map(|(key, senders)| {
                let count = senders.len();
                let reacted_by_me = my_user_id
                    .map(|me| senders.iter().any(|(uid, _)| uid.as_str() == me))
                    .unwrap_or(false);
                let sender_list: Vec<ReactionSender> = senders
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
                let sender_name = match &embedded.sender_profile {
                    TimelineDetails::Ready(profile) => profile
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
                Some((sender_name, body))
            } else {
                Some((reply.event_id.to_string(), "[Loading…]".to_string()))
            }
        } else {
            None
        };

        let msg_type = message.msgtype().clone();
        let sender = event.sender().to_string();
        let is_me = my_user_id.map(|me| me == sender.as_str()).unwrap_or(false);
        let (sender_name, sender_initial) = match event.sender_profile() {
            TimelineDetails::Ready(profile) => {
                let name = profile
                    .display_name
                    .clone()
                    .unwrap_or_else(|| sender.clone());
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
                let initial = sender
                    .chars()
                    .nth(1)
                    .unwrap_or('?')
                    .to_uppercase()
                    .next()
                    .unwrap_or('?');
                (sender.clone(), initial)
            }
        };
        let color = sender_color(&sender);
        let timestamp = format_timestamp(event.timestamp());
        let read_receipts: Vec<(String, String)> = event
            .read_receipts()
            .iter()
            .filter(|(uid, _)| uid.as_str() != sender.as_str())
            .map(|(uid, receipt)| {
                let ts = receipt.ts.map(format_timestamp).unwrap_or_default();
                (uid.to_string(), ts)
            })
            .collect();

        (
            msg_type,
            event_id,
            date_key,
            reply_to,
            sender,
            sender_name,
            sender_initial,
            color,
            timestamp,
            is_me,
            read_receipts,
            reactions,
        )
    };

    let content = match msg_type {
        MessageType::Text(t) => MessageContent::Text(t.body),
        MessageType::Image(img) => {
            let key = event_id
                .clone()
                .unwrap_or_else(|| "img-unknown".to_string());
            let caption = if img.body.starts_with("image")
                || img.body.ends_with(".jpg")
                || img.body.ends_with(".jpeg")
                || img.body.ends_with(".png")
                || img.body.ends_with(".gif")
                || img.body.ends_with(".webp")
            {
                None
            } else {
                Some(img.body.clone()).filter(|s| !s.is_empty())
            };
            let blurhash = img.info.as_ref().and_then(|i| i.blurhash.clone());
            let thumbnail_source = img.info.as_ref().and_then(|i| i.thumbnail_source.clone());
            MessageContent::Image {
                key,
                source: img.source.clone(),
                caption,
                blurhash,
                thumbnail_source,
            }
        }
        _ => return None,
    };

    Some(MessageItem {
        event_id,
        date_key,
        date_label: None,
        reply_to,
        sender,
        sender_name,
        sender_initial,
        sender_color: sender_color_val,
        content,
        timestamp,
        is_me,
        read_receipts,
        seen_by: vec![],
        fully_read: false,
        reactions,
    })
}

pub(super) fn assign_date_labels(msgs: &mut Vec<MessageItem>) {
    let mut prev_date = String::new();
    for msg in msgs.iter_mut() {
        if msg.date_key != prev_date && !msg.date_key.is_empty() {
            msg.date_label = Some(format_date_label(&msg.date_key));
            prev_date = msg.date_key.clone();
        } else {
            msg.date_label = None;
        }
    }
}

pub(super) fn assign_read_receipts(msgs: &mut Vec<MessageItem>, my_user_id: Option<&str>) {
    let mut user_latest: HashMap<String, (usize, String)> = HashMap::new();
    for (idx, msg) in msgs.iter().enumerate() {
        for (uid, ts) in &msg.read_receipts {
            if my_user_id.is_some_and(|me| me == uid.as_str()) {
                continue;
            }
            let e = user_latest.entry(uid.clone()).or_insert((0, ts.clone()));
            if idx >= e.0 {
                *e = (idx, ts.clone());
            }
        }
    }

    for msg in msgs.iter_mut() {
        msg.read_receipts.clear();
        msg.seen_by.clear();
        msg.fully_read = false;
    }

    if user_latest.is_empty() {
        return;
    }

    for (uid, (latest_idx, ts)) in &user_latest {
        msgs[*latest_idx].read_receipts.push((uid.clone(), ts.clone()));
    }

    for (idx, msg) in msgs.iter_mut().enumerate() {
        msg.seen_by = user_latest
            .iter()
            .filter(|(_, (pos, _))| *pos >= idx)
            .map(|(uid, (_, ts))| {
                let display = uid
                    .trim_start_matches('@')
                    .split(':')
                    .next()
                    .unwrap_or(uid)
                    .to_string();
                (uid.clone(), display, ts.clone())
            })
            .collect();
        if msg.is_me {
            msg.fully_read = user_latest.values().all(|(pos, _)| *pos >= idx);
        }
    }
}
