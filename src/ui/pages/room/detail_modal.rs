use std::sync::Arc;
use std::time::Duration;

use freya::prelude::*;
use freya_query::prelude::*;
use matrix_sdk_ui::timeline::{TimelineItem, TimelineItemContent};

use crate::ui::components::Avatar;
use crate::utils::queries::FetchSenderName;
use crate::utils::{format_timestamp, sender_color, use_app_colors};

use super::{Reaction, ReactionSender};

pub(super) struct DetailModalOverlay {
    pub modal: State<Option<Arc<TimelineItem>>>,
    pub room_id: String,
}

impl PartialEq for DetailModalOverlay {
    fn eq(&self, other: &Self) -> bool {
        self.room_id == other.room_id && self.modal == other.modal
    }
}

impl Component for DetailModalOverlay {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let modal_item = self.modal.read().clone();
        let show = modal_item.is_some();
        let room_id = self.room_id.clone();
        let mut modal = self.modal;

        let mut popup = Popup::new()
            .show(show)
            .on_close_request(move |_| *modal.write() = None);

        if let Some(item) = modal_item {
            popup = popup
                // ── Header ────────────────────────────────────────────────────
                .child(
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .cross_align(Alignment::Center)
                        .child(
                            label()
                                .text("Message details")
                                .font_size(16.)
                                .font_weight(FontWeight::BOLD)
                                .color(c.on_surface),
                        ),
                )
                // ── Scrollable content ────────────────────────────────────────
                .child(
                    ScrollView::new()
                        .width(Size::fill())
                        .height(Size::px(400.))
                        .child(
                            rect()
                                .vertical()
                                .width(Size::fill())
                                .spacing(16.)
                                .child(seen_by_section(&item, &room_id, c))
                                .child(reactions_section(&item, &room_id, c)),
                        ),
                );
        }

        popup
    }
}

fn section_title(text: &str, c: crate::utils::const_values::AppColors) -> Element {
    label()
        .text(text.to_string())
        .font_size(13.)
        .font_weight(FontWeight::BOLD)
        .color(c.primary)
        .into()
}

fn seen_by_section(item: &Arc<TimelineItem>, room_id: &str, c: crate::utils::const_values::AppColors) -> Element {
    let mut col = rect()
        .vertical()
        .width(Size::fill())
        .spacing(4.)
        .child(section_title("Seen by", c));

    let receipts: Vec<(String, String, String)> = item
        .as_event()
        .map(|e| {
            e.read_receipts()
                .iter()
                .map(|(uid, receipt)| {
                    let ts = receipt.ts.map(format_timestamp).unwrap_or_default();
                    let display = uid.localpart().to_string();
                    (uid.to_string(), display, ts)
                })
                .collect()
        })
        .unwrap_or_default();

    if receipts.is_empty() {
        col = col.child(
            label()
                .text("No read receipts yet")
                .font_size(13.)
                .color(c.on_surface_muted),
        );
    } else {
        for (uid, display_fallback, timestamp) in &receipts {
            col = col.child(SeenByRow {
                room_id: room_id.to_string(),
                uid: uid.clone(),
                display_fallback: display_fallback.clone(),
                timestamp: timestamp.clone(),
            });
        }
    }
    col.into()
}

#[derive(PartialEq, Clone)]
struct SeenByRow {
    room_id: String,
    uid: String,
    display_fallback: String,
    timestamp: String,
}

impl Component for SeenByRow {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let uid = self.uid.clone();
        let room_id = self.room_id.clone();
        let display_fallback = self.display_fallback.clone();
        let timestamp = self.timestamp.clone();

        let member_key = format!("{}\x00{}", room_id, uid);
        let name_query = use_query(
            Query::new(member_key.clone(), FetchSenderName).stale_time(Duration::from_secs(3600)),
        );
        let name = name_query
            .read()
            .state()
            .ok()
            .cloned()
            .unwrap_or_else(|| display_fallback.clone());

        let avatar_key = member_key;
        rect()
            .horizontal()
            .width(Size::fill())
            .cross_align(Alignment::Center)
            .padding(Gaps::new(6., 0., 6., 0.))
            .spacing(10.)
            .child(Avatar {
                size: 28.,
                bytes: None,
                initial: name
                    .chars()
                    .next()
                    .unwrap_or('?')
                    .to_uppercase()
                    .to_string(),
                color: sender_color(&uid),
                image_key: avatar_key.clone(),
                fetch_key: Some(avatar_key),
            })
            .child(
                rect()
                    .vertical()
                    .spacing(1.)
                    .child(label().text(name).font_size(13.).color(c.on_surface))
                    .child(
                        label()
                            .text(timestamp)
                            .font_size(11.)
                            .color(c.on_surface_muted),
                    ),
            )
    }
}

fn reactions_section(item: &Arc<TimelineItem>, room_id: &str, c: crate::utils::const_values::AppColors) -> Element {
    let reactions: Vec<Reaction> = item
        .as_event()
        .and_then(|e| {
            if let TimelineItemContent::MsgLike(m) = e.content() {
                let r: Vec<Reaction> = m
                    .reactions
                    .iter()
                    .map(|(key, senders)| {
                        let count = senders.len();
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
                            reacted_by_me: false,
                            senders: sender_list,
                        }
                    })
                    .collect();
                Some(r)
            } else {
                None
            }
        })
        .unwrap_or_default();

    if reactions.is_empty() {
        return rect().into();
    }

    let mut col = rect()
        .vertical()
        .width(Size::fill())
        .spacing(12.)
        .child(section_title("Reactions", c));

    for reaction in &reactions {
        col = col.child(reaction_group(reaction, room_id, c));
    }
    col.into()
}

fn reaction_group(reaction: &Reaction, room_id: &str, c: crate::utils::const_values::AppColors) -> Element {
    let mut group = rect().vertical().width(Size::fill()).spacing(4.).child(
        label()
            .text(format!(
                "{} · {} {}",
                reaction.key,
                reaction.count,
                if reaction.count == 1 { "person" } else { "people" }
            ))
            .font_size(13.)
            .color(c.on_surface),
    );

    for sender in &reaction.senders {
        group = group.child(ReactionSenderRow {
            room_id: room_id.to_string(),
            sender: sender.clone(),
        });
    }
    group.into()
}

#[derive(PartialEq, Clone)]
struct ReactionSenderRow {
    room_id: String,
    sender: ReactionSender,
}

impl Component for ReactionSenderRow {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let uid = self.sender.user_id.clone();
        let timestamp = self.sender.timestamp.clone();
        let display_fallback = self.sender.display.clone();

        let member_key = format!("{}\x00{}", self.room_id, uid);
        let name_query = use_query(
            Query::new(member_key.clone(), FetchSenderName).stale_time(Duration::from_secs(3600)),
        );
        let name = name_query
            .read()
            .state()
            .ok()
            .cloned()
            .unwrap_or_else(|| display_fallback.clone());

        let avatar_key = member_key;
        rect()
            .horizontal()
            .width(Size::fill())
            .cross_align(Alignment::Center)
            .padding(Gaps::new(4., 8., 4., 0.))
            .spacing(8.)
            .child(Avatar {
                size: 24.,
                bytes: None,
                initial: name
                    .chars()
                    .next()
                    .unwrap_or('?')
                    .to_uppercase()
                    .to_string(),
                color: sender_color(&uid),
                image_key: avatar_key.clone(),
                fetch_key: Some(avatar_key),
            })
            .child(
                rect()
                    .vertical()
                    .spacing(1.)
                    .child(label().text(name).font_size(12.).color(c.on_surface))
                    .child(
                        label()
                            .text(timestamp)
                            .font_size(11.)
                            .color(c.on_surface_muted),
                    ),
            )
    }
}
