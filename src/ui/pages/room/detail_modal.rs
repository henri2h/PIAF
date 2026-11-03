use std::sync::Arc;

use freya::prelude::*;

use crate::utils::avatars::AvatarSource;
use matrix_sdk_ui::timeline::{TimelineItem, TimelineItemContent};

use crate::ui::components::{Avatar, Chip, bottom_sheet};
use crate::utils::queries::use_member_name;
use crate::utils::{format_timestamp, id_color, use_app_colors};

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
        let show_source = use_state(|| false);
        let modal_item = self.modal.read().clone();
        let room_id = self.room_id.clone();
        let mut modal = self.modal;

        let Some(item) = modal_item else {
            return if cfg!(target_os = "android") {
                rect().into_element()
            } else {
                Popup::new()
                    .on_close_request(move |_| modal.set(None))
                    .into_element()
            };
        };
        let body = rect()
            .vertical()
            .width(Size::fill())
            .padding(Gaps::new(4., 16., 12., 4.))
            .spacing(20.)
            .child(info_section(&item, c))
            .child(seen_by_section(&item, &room_id, c))
            .child(reactions_section(&item, &room_id, c))
            .child(source_section(&item, show_source, c));

        // Android: a bottom sheet, the mobile way to show details.
        if cfg!(target_os = "android") {
            return bottom_sheet(c, move || modal.set(None))
                .title("Message details")
                .child(
                    ScrollView::new()
                        .width(Size::fill())
                        .max_height(Size::window_percent(65.))
                        .height(Size::auto())
                        .child(body.padding(Gaps::new(0., 24., 16., 24.))),
                )
                .into_element();
        }

        Popup::new()
            .on_close_request(move |_| modal.set(None))
            .child(
                label()
                    .text("Message details")
                    .font_size(18.)
                    .font_weight(FontWeight::BOLD)
                    .color(c.on_surface),
            )
            .child(
                ScrollView::new()
                    .width(Size::fill())
                    .height(Size::px(440.))
                    .child(body),
            )
            .into_element()
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

/// Who sent it, when, and the IDs.
fn info_section(item: &Arc<TimelineItem>, c: crate::utils::const_values::AppColors) -> Element {
    let Some(event) = item.as_event() else {
        return rect().into();
    };
    let mut rows = vec![
        ("Sent", format_timestamp(event.timestamp())),
        (
            "From",
            format!(
                "{} ({})",
                crate::utils::room_preview::sender_name(event),
                event.sender()
            ),
        ),
    ];
    if let Some(id) = event.event_id() {
        rows.push(("Event ID", id.to_string()));
    }
    let mut col = rect()
        .vertical()
        .width(Size::fill())
        .spacing(8.)
        .child(section_title("Message", c));
    for (name, value) in rows {
        col = col.child(
            rect()
                .vertical()
                .width(Size::fill())
                .child(
                    label()
                        .text(name)
                        .font_size(11.)
                        .color(c.on_surface_muted),
                )
                .child(
                    label()
                        .width(Size::fill())
                        .text(breakable(&value))
                        .font_size(13.)
                        .color(c.on_surface),
                ),
        );
    }
    col.into()
}

/// `text` with line-break chances after URL and ID punctuation: a long
/// token otherwise runs out of the box. For display only.
fn breakable(text: &str) -> String {
    let mut out = String::with_capacity(text.len() * 2);
    for ch in text.chars() {
        out.push(ch);
        if "/&?=_-.:,$!".contains(ch) {
            out.push('\u{200B}');
        }
    }
    out
}

/// The event's JSON as received: hidden until asked, then pretty-printed
/// with a button to copy it.
fn source_section(
    item: &Arc<TimelineItem>,
    mut show: State<bool>,
    c: crate::utils::const_values::AppColors,
) -> Element {
    use matrix_sdk::ruma::exports::serde_json::{Value, from_str, to_string_pretty};
    let Some(raw) = item.as_event().and_then(|e| e.original_json()) else {
        return rect().into();
    };
    let open = *show.read();
    let mut header = rect()
        .horizontal()
        .width(Size::fill())
        .cross_align(Alignment::Center)
        .spacing(8.)
        .child(section_title("Source", c))
        .child(
            Chip::new(if open { "Hide" } else { "Show" }, false, move |_| {
                show.toggle()
            })
            .height(26.),
        );
    let mut col = rect().vertical().width(Size::fill()).spacing(8.);
    if open {
        let raw = raw.json().get();
        let source = from_str::<Value>(raw)
            .and_then(|v| to_string_pretty(&v))
            .unwrap_or_else(|_| raw.to_string());
        let to_copy = source.clone();
        header = header.child(
            Chip::new("Copy", false, move |_| {
                let _ = Clipboard::set(to_copy.clone());
            })
            .icon(freya_icons::lucide::copy())
            .height(26.),
        );
        col = col.child(header).child(
            rect()
                .width(Size::fill())
                .padding(Gaps::new(8., 10., 8., 10.))
                .corner_radius(8.)
                .background(c.surface_container)
                .child(
                    label()
                        .width(Size::fill())
                        .text(breakable(&source))
                        .font_size(11.)
                        .color(c.on_surface_variant),
                ),
        );
    } else {
        col = col.child(header);
    }
    col.into()
}

fn seen_by_section(
    item: &Arc<TimelineItem>,
    room_id: &str,
    c: crate::utils::const_values::AppColors,
) -> Element {
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

        let name = use_member_name(&room_id, &uid).unwrap_or_else(|| display_fallback.clone());

        rect()
            .horizontal()
            .width(Size::fill())
            .cross_align(Alignment::Center)
            .padding(Gaps::new(6., 0., 6., 0.))
            .spacing(10.)
            .child(Avatar {
                size: 28.,
                source: Some(AvatarSource::member(&self.room_id, &uid)),
                name: name.clone(),
                color: id_color(&uid),
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

fn reactions_section(
    item: &Arc<TimelineItem>,
    room_id: &str,
    c: crate::utils::const_values::AppColors,
) -> Element {
    let reactions = match item.as_event().map(|e| e.content()) {
        Some(TimelineItemContent::MsgLike(m)) => {
            super::reactions(&m.reactions, crate::utils::matrix::my_user_id().as_deref())
        }
        _ => vec![],
    };

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

fn reaction_group(
    reaction: &Reaction,
    room_id: &str,
    c: crate::utils::const_values::AppColors,
) -> Element {
    let mut group = rect().vertical().width(Size::fill()).spacing(4.).child(
        label()
            .text(format!(
                "{} · {} {}",
                reaction.key,
                reaction.count,
                if reaction.count == 1 {
                    "person"
                } else {
                    "people"
                }
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

        let name = use_member_name(&self.room_id, &uid).unwrap_or_else(|| display_fallback.clone());

        rect()
            .horizontal()
            .width(Size::fill())
            .cross_align(Alignment::Center)
            .padding(Gaps::new(4., 8., 4., 0.))
            .spacing(8.)
            .child(Avatar {
                size: 24.,
                source: Some(AvatarSource::member(&self.room_id, &uid)),
                name: name.clone(),
                color: id_color(&uid),
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
