//! Rows that aren't bubbles: day dividers, the read marker, membership changes.

use freya::prelude::*;
use matrix_sdk_ui::timeline::{MembershipChange, RoomMembershipChange};

use crate::utils::const_values::AppColors;

/// "Today", "Monday"… centred on a pill.
pub(super) fn date_separator(label_text: String, c: AppColors) -> Element {
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
                .child(label().text(label_text).font_size(12.).color(c.on_surface)),
        )
        .into_element()
}

/// "New messages" between two lines.
pub(super) fn read_marker(c: AppColors) -> Element {
    let line = || {
        rect()
            .width(Size::flex(1.0))
            .height(Size::px(1.))
            .background(c.primary)
    };
    rect()
        .horizontal()
        .width(Size::fill())
        .content(Content::Flex)
        .cross_align(Alignment::Center)
        .padding(Gaps::new(8., 16., 8., 16.))
        .spacing(8.)
        .child(line())
        .child(label().text("New messages").font_size(12.).color(c.primary))
        .child(line())
        .into_element()
}

/// "Ann joined the room"…; `None` for changes not shown.
pub(super) fn membership_text(m: &RoomMembershipChange) -> Option<String> {
    let name = m
        .display_name()
        .unwrap_or_else(|| m.user_id().localpart().to_string());
    Some(match m.change()? {
        MembershipChange::Joined | MembershipChange::InvitationAccepted => {
            format!("{name} joined the room")
        }
        MembershipChange::Left => format!("{name} left the room"),
        MembershipChange::Banned | MembershipChange::KickedAndBanned => {
            format!("{name} was banned")
        }
        MembershipChange::Kicked => format!("{name} was removed from the room"),
        MembershipChange::Invited => format!("{name} was invited"),
        _ => return None,
    })
}

/// A small centred pill of muted text.
pub(super) fn notice(text: String, c: AppColors) -> Element {
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
        )
        .into_element()
}

/// Body of a message that can't be shown: deleted, or not decrypted.
pub(super) fn placeholder(icon: Bytes, text: &str, color: (u8, u8, u8)) -> Element {
    rect()
        .horizontal()
        .cross_align(Alignment::Center)
        .spacing(6.)
        .child(
            SvgViewer::new(icon)
                .color(color)
                .width(Size::px(14.))
                .height(Size::px(14.)),
        )
        .child(
            label()
                .text(text.to_string())
                .font_size(14.)
                .font_slant(FontSlant::Italic)
                .color(color),
        )
        .into_element()
}
