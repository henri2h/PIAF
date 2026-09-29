use std::rc::Rc;
use std::time::Duration;

use freya::prelude::*;
use freya_query::prelude::*;
use matrix_sdk::RoomHero;
use matrix_sdk::ruma::MilliSecondsSinceUnixEpoch;

use super::room_menu::open_room_menu;
use super::row_interaction::{OnMenu, use_row_interaction};
use crate::app::keys::{Area, use_key_nav};
use crate::app::navigation::navigate_to_room;
use crate::logging::RenderTimer;
use crate::ui::components::{Avatar, StackedAvatar, user_color};
use crate::ui::pages::home::ActiveRoomCtx;
use crate::utils::const_values::AppColors;
use crate::utils::matrix::my_user_id;
pub use crate::utils::room_list::RoomSummary;
use crate::utils::room_preview::{SenderPrefix, last_message, preview_text};
use crate::utils::{
    format_full_timestamp, format_timestamp, queries::FetchSenderName, use_app_colors,
};

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
        // Keyboard cursor, shown only while the list has keyboard focus.
        let is_key_selected = use_key_nav().is_some_and(|nav| {
            *nav.area.read() == Area::List
                && nav.selected.read().as_deref() == Some(room_id.as_str())
        });

        use_hook(|| crate::utils::sync::track_latest_event(&room_id));
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
                            .spacing(4.)
                            .cross_align(Alignment::Center)
                            .child(
                                label()
                                    .text(s.name.clone())
                                    .width(Size::flex(1.0))
                                    .max_lines(1)
                                    .font_size(16.)
                                    .font_weight(font_weight)
                                    .color(c.on_surface),
                            )
                            .maybe_child(
                                s.is_favourite
                                    .then(|| small_icon(freya_icons::lucide::star(), c.primary)),
                            )
                            .child(trailing(s, c, font_weight)),
                    )
                    .child(preview_line(s, preview, c)),
            );

        let highlighted: Element = rect()
            .expanded()
            .background(bg)
            .corner_radius(12.)
            .overflow(Overflow::Clip)
            .maybe(is_key_selected, |el| {
                el.border(
                    Border::new()
                        .fill(c.primary)
                        .width(2.)
                        .alignment(BorderAlignment::Inner),
                )
            })
            .child(interaction.feedback(inner))
            .into();

        let room_id_nav = room_id.clone();
        let outer = rect()
            .key(room_id.clone())
            .height(Size::px(ROOM_ROW_HEIGHT))
            .width(Size::fill())
            .padding(Gaps::new(2., 8., 2., 8.))
            .on_press(move |_| navigate_to_room(room_id_nav.clone()));

        let summary = s.clone();
        let on_menu: OnMenu = Rc::new(move |from_down| open_room_menu(&summary, from_down));
        interaction.attach(outer, room_id, c, highlighted, on_menu)
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

/// Send failure, else draft, else the latest message.
fn preview_line(s: &RoomSummary, preview: String, c: AppColors) -> Rect {
    let row = rect()
        .horizontal()
        .width(Size::fill())
        .content(Content::Flex)
        .spacing(4.)
        .cross_align(Alignment::Center);
    let text = |t: String, color| {
        label()
            .text(t)
            .width(Size::flex(1.))
            .max_lines(1)
            .font_size(13.5)
            .color(color)
    };
    if s.send_failed {
        return row
            .child(small_icon(freya_icons::lucide::circle_alert(), c.error))
            .child(text("Failed to send".into(), c.error));
    }
    if let Some(draft) = s.draft.clone().filter(|_| !s.is_invite) {
        return row
            .child(
                label()
                    .text("Draft:")
                    .font_size(13.5)
                    .font_weight(FontWeight::MEDIUM)
                    .color(c.error),
            )
            .child(text(draft, c.on_surface_variant));
    }
    row.child(text(preview, c.on_surface_variant))
}

fn small_icon(svg: bytes::Bytes, color: (u8, u8, u8)) -> SvgViewer {
    SvgViewer::new(svg)
        .width(Size::px(14.))
        .height(Size::px(14.))
        .color(color)
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
    let ts = s
        .latest_ts
        .and_then(|ts| ts.try_into().ok())
        .map(MilliSecondsSinceUnixEpoch);
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
                .maybe_child(ts.map(|ts| {
                    TooltipContainer::new(Tooltip::new_text(format_full_timestamp(ts)))
                        .position(AttachedPosition::Bottom)
                        .child(
                            label()
                                .text(format_timestamp(ts))
                                .font_size(12.)
                                .font_weight(font_weight)
                                .color(timestamp_color),
                        )
                })),
        )
        .child(unread_badge(s, c))
}

/// Count pill for notifications (red with `@` when you're mentioned), a dot
/// for unread-only or marked unread, else an empty spacer.
fn unread_badge(s: &RoomSummary, c: AppColors) -> Element {
    if s.notifications > 0 || s.mentions > 0 {
        let n = s.notifications.max(s.mentions);
        let count = if n > 99 {
            "99+".to_string()
        } else {
            n.to_string()
        };
        let (count, background) = if s.mentions > 0 {
            (format!("@ {count}"), c.error)
        } else {
            (count, c.primary)
        };
        return rect()
            .min_width(Size::px(20.))
            .height(Size::px(20.))
            .corner_radius(10.)
            .background(background)
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
