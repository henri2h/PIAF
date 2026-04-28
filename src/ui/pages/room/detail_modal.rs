use freya::prelude::*;

use crate::ui::components::Avatar;
use crate::utils::const_values::AppColors;
use crate::utils::sender_color;

use super::{MessageItem, Reaction, ReactionSender};

pub(super) fn detail_modal_overlay(
    msg: MessageItem,
    mut modal: State<Option<MessageItem>>,
    c: AppColors,
) -> Element {
    rect()
        .position(Position::new_global().top(0.).left(0.))
        .layer(Layer::Overlay)
        .width(Size::window_percent(100.))
        .height(Size::window_percent(100.))
        .background((0, 0, 0, 160u8))
        .on_press(move |_| *modal.write() = None)
        .child(
            rect()
                .position(Position::new_absolute().bottom(0.).left(0.))
                .width(Size::fill())
                .max_height(Size::percent(70.))
                .content(Content::Flex)
                .corner_radius(20.)
                .background(c.surface)
                .vertical()
                .on_press(|_| {})
                .child(
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .cross_align(Alignment::Center)
                        .padding(Gaps::new(16., 16., 12., 16.))
                        .child(
                            label()
                                .text("Message details")
                                .font_size(16.)
                                .font_weight(FontWeight::BOLD)
                                .color(c.on_surface),
                        ),
                )
                .child(
                    ScrollView::new()
                        .width(Size::fill())
                        .height(Size::flex(1.0))
                        .child(
                            rect()
                                .vertical()
                                .width(Size::fill())
                                .padding(Gaps::new(0., 16., 24., 16.))
                                .spacing(16.)
                                .child(seen_by_section(&msg, c))
                                .child(reactions_section(&msg, c)),
                        ),
                ),
        )
        .into()
}

fn section_title(text: &str, c: AppColors) -> Element {
    label()
        .text(text.to_string())
        .font_size(13.)
        .font_weight(FontWeight::BOLD)
        .color(c.primary)
        .into()
}

fn seen_by_section(msg: &MessageItem, c: AppColors) -> Element {
    let mut col = rect()
        .vertical()
        .width(Size::fill())
        .spacing(4.)
        .child(section_title("Seen by", c));

    if msg.read_receipts.is_empty() {
        col = col.child(
            label()
                .text("No read receipts yet")
                .font_size(13.)
                .color(c.on_surface_muted),
        );
    } else {
        for (uid, ts) in &msg.read_receipts {
            let display = uid
                .trim_start_matches('@')
                .split(':')
                .next()
                .unwrap_or(uid)
                .to_string();
            let ts = ts.clone();
            col = col.child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .cross_align(Alignment::Center)
                    .padding(Gaps::new(6., 0., 6., 0.))
                    .spacing(10.)
                    .child(Avatar {
                        size: 28.,
                        bytes: None,
                        initial: display
                            .chars()
                            .next()
                            .unwrap_or('?')
                            .to_uppercase()
                            .to_string(),
                        color: sender_color(uid),
                        image_key: uid.clone(),
                        fetch_key: None,
                    })
                    .child(
                        rect()
                            .vertical()
                            .spacing(1.)
                            .child(label().text(display).font_size(13.).color(c.on_surface))
                            .child(label().text(ts).font_size(11.).color(c.on_surface_muted)),
                    ),
            );
        }
    }
    col.into()
}

fn reactions_section(msg: &MessageItem, c: AppColors) -> Element {
    if msg.reactions.is_empty() {
        return rect().into();
    }

    let mut col = rect()
        .vertical()
        .width(Size::fill())
        .spacing(12.)
        .child(section_title("Reactions", c));

    for reaction in &msg.reactions {
        col = col.child(reaction_group(reaction, c));
    }
    col.into()
}

fn reaction_group(reaction: &Reaction, c: AppColors) -> Element {
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
        group = group.child(reaction_sender_row(sender, c));
    }
    group.into()
}

fn reaction_sender_row(sender: &ReactionSender, c: AppColors) -> Element {
    rect()
        .horizontal()
        .width(Size::fill())
        .cross_align(Alignment::Center)
        .padding(Gaps::new(4., 8., 4., 0.))
        .spacing(8.)
        .child(Avatar {
            size: 24.,
            bytes: None,
            initial: sender
                .display
                .chars()
                .next()
                .unwrap_or('?')
                .to_uppercase()
                .to_string(),
            color: sender_color(&sender.user_id),
            image_key: sender.user_id.clone(),
            fetch_key: None,
        })
        .child(
            rect()
                .vertical()
                .spacing(1.)
                .child(
                    label()
                        .text(sender.display.clone())
                        .font_size(12.)
                        .color(c.on_surface),
                )
                .child(
                    label()
                        .text(sender.timestamp.clone())
                        .font_size(11.)
                        .color(c.on_surface_muted),
                ),
        )
        .into()
}
