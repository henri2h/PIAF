use std::time::Duration;

use freya::prelude::*;
use freya_query::prelude::*;
use matrix_sdk::RoomHero;
use matrix_sdk::ruma::MilliSecondsSinceUnixEpoch;

pub use super::room_list_model::RoomSummary;
use super::row_interaction::use_row_interaction;
use crate::app::navigation::navigate_to_room;
use crate::logging::RenderTimer;
use crate::ui::components::{Avatar, StackedAvatar, user_color};
use crate::ui::pages::home::ActiveRoomCtx;
use crate::utils::const_values::AppColors;
use crate::utils::matrix::my_user_id;
use crate::utils::room_preview::{SenderPrefix, last_message, preview_text};
use crate::utils::{format_timestamp, queries::FetchSenderName, use_app_colors};

pub const ROOM_ROW_HEIGHT: f32 = 80.;

#[derive(Clone, PartialEq)]
pub struct RoomListItem {
    pub summary: RoomSummary,
}

impl Component for RoomListItem {
    fn render(&self) -> impl IntoElement {
        let _timer = RenderTimer::with_threshold("RoomListItem", Duration::from_micros(200));
        let c = use_app_colors();
        let s = &self.summary;
        let room_id = s.room_id.clone();

        let interaction = use_row_interaction();
        let is_active = try_consume_context::<ActiveRoomCtx>()
            .is_some_and(|ctx| ctx.0.read().as_deref() == Some(room_id.as_str()));

        let needs_preview = s.needs_preview;
        use_side_effect_with_deps(&(room_id.clone(), needs_preview), move |(rid, needed)| {
            if *needed && let Ok(rid) = matrix_sdk::ruma::OwnedRoomId::try_from(rid.as_str()) {
                crate::REQUESTER
                    .get()
                    .expect("not initialized")
                    .fetch_room_previews(vec![rid]);
            }
        });

        let (body, prefix) = last_message(&s.room, my_user_id().as_deref())
            .unwrap_or((String::new(), SenderPrefix::None));
        let sender_query_key = match &prefix {
            SenderPrefix::Other(uid) => format!("{room_id}\x00{uid}"),
            _ => String::new(),
        };
        let sender_query = use_query(
            Query::new(sender_query_key, FetchSenderName).stale_time(Duration::from_secs(3600)),
        );
        let preview = if body.is_empty() {
            if s.is_invite {
                "Invitation".to_string()
            } else {
                String::new()
            }
        } else {
            let sender_name = sender_query.read().state().ok().cloned();
            preview_text(&body, &prefix, sender_name.as_deref())
        };

        let bg = if is_active {
            c.surface_container_high
        } else if interaction.is_highlighted() {
            c.surface_container
        } else {
            c.surface
        };
        let font_weight = if s.is_unread() {
            FontWeight::BOLD
        } else {
            FontWeight::NORMAL
        };

        let inner = rect()
            .horizontal()
            .expanded()
            .padding(Gaps::new(8., 12., 8., 12.))
            .spacing(14.)
            .cross_align(Alignment::Center)
            .child(room_avatar(s, c, bg))
            .child(
                rect()
                    .vertical()
                    .spacing(2.)
                    .width(Size::fill())
                    .main_align(Alignment::Center)
                    .child(
                        rect()
                            .horizontal()
                            .content(Content::Flex)
                            .width(Size::fill())
                            .child(
                                label()
                                    .text(s.name.clone())
                                    .width(Size::flex(1.0))
                                    .font_size(16.)
                                    .font_weight(font_weight)
                                    .color(c.on_surface),
                            )
                            .child(trailing(s, c, font_weight)),
                    )
                    .child(
                        label()
                            .text(preview)
                            .width(Size::fill())
                            .max_lines(1)
                            .color(c.on_surface_variant)
                            .font_size(13.5),
                    ),
            );

        let highlighted: Element = rect()
            .expanded()
            .background(bg)
            .corner_radius(12.)
            .overflow(Overflow::Clip)
            .child(interaction.feedback(inner))
            .into();

        let room_id_nav = room_id.clone();
        let outer = rect()
            .key(room_id.clone())
            .height(Size::px(ROOM_ROW_HEIGHT))
            .width(Size::fill())
            .padding(Gaps::new(2., 8., 2., 8.))
            .on_press(move |_| navigate_to_room(room_id_nav.clone()));

        interaction.attach(outer, room_id, c, highlighted)
    }
}

/// Group rooms with 2+ hero avatars get a stacked avatar; others the room avatar.
fn room_avatar(s: &RoomSummary, c: AppColors, bg: (u8, u8, u8)) -> Element {
    let heroes = s.room.heroes();
    let with_avatar: Vec<&RoomHero> = heroes.iter().filter(|h| h.avatar_url.is_some()).collect();
    if let [h1, h2, ..] = with_avatar[..]
        && !s.is_dm
    {
        return StackedAvatar {
            size: 48.,
            initial1: hero_initial(h1),
            color1: user_color(h1.user_id.as_str()),
            initial2: hero_initial(h2),
            color2: user_color(h2.user_id.as_str()),
            border_color: bg,
        }
        .into();
    }
    Avatar {
        size: 48.,
        bytes: None,
        fetch_key: Some(s.room_id.clone()),
        initial: initial_of(&s.name),
        color: c.primary,
        image_key: s.room_id.clone(),
    }
    .into()
}

/// Mute icon + timestamp, with the unread badge below. Invites get a pill instead.
fn trailing(s: &RoomSummary, c: AppColors, font_weight: FontWeight) -> Rect {
    if s.is_invite {
        return rect()
            .padding(Gaps::new(3., 10., 3., 10.))
            .corner_radius(10.)
            .background(c.primary)
            .child(
                label()
                    .text("Invite")
                    .font_size(11.)
                    .font_weight(FontWeight::MEDIUM)
                    .color(c.on_primary),
            );
    }
    let timestamp = s
        .latest_ts
        .and_then(|ts| ts.try_into().ok())
        .map(|ts| format_timestamp(MilliSecondsSinceUnixEpoch(ts)))
        .unwrap_or_default();
    let timestamp_color = if s.is_unread() {
        c.primary
    } else {
        c.on_surface_faint
    };
    rect()
        .vertical()
        .cross_align(Alignment::End)
        .spacing(4.)
        .child(
            rect()
                .horizontal()
                .spacing(4.)
                .cross_align(Alignment::Center)
                .maybe_child(s.is_muted.then(|| {
                    SvgViewer::new(freya_icons::lucide::bell_off())
                        .width(Size::px(12.))
                        .height(Size::px(12.))
                        .color(c.on_surface_faint)
                }))
                .child(
                    label()
                        .text(timestamp)
                        .font_size(12.)
                        .font_weight(font_weight)
                        .color(timestamp_color),
                ),
        )
        .child(unread_badge(s, c))
}

/// Count pill for notifications, a dot for unread-only, else an empty spacer.
fn unread_badge(s: &RoomSummary, c: AppColors) -> Element {
    if s.notifications > 0 {
        let count = if s.notifications > 99 {
            "99+".to_string()
        } else {
            s.notifications.to_string()
        };
        return rect()
            .min_width(Size::px(20.))
            .height(Size::px(20.))
            .corner_radius(10.)
            .background(c.primary)
            .center()
            .padding(Gaps::new(0., 4., 0., 4.))
            .child(label().text(count).font_size(11.).color(c.on_primary))
            .into();
    }
    let dot = rect().width(Size::px(8.)).height(Size::px(8.));
    if s.is_unread() {
        dot.corner_radius(4.).background(c.primary).into()
    } else {
        dot.into()
    }
}

fn initial_of(name: &str) -> String {
    name.chars()
        .next()
        .map(|c| c.to_uppercase().to_string())
        .unwrap_or_else(|| "?".to_string())
}

fn hero_initial(hero: &RoomHero) -> String {
    hero.display_name
        .as_deref()
        .and_then(|n| n.chars().next())
        .or_else(|| hero.user_id.localpart().chars().next())
        .map(|c| c.to_uppercase().to_string())
        .unwrap_or_else(|| "?".to_string())
}
