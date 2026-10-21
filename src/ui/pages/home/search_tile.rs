use crate::utils::id_color;
use freya::prelude::*;

use crate::ui::components::{ListItem, PersonRow};
use crate::utils::users::UserInfo;

use crate::ui::components::HoverableExt;

use crate::utils::avatars::AvatarSource;
use freya_material_design::prelude::Ripple;
use matrix_sdk::ruma::{MilliSecondsSinceUnixEpoch, UInt};

use crate::ui::components::Avatar;
use crate::utils::{format_timestamp, use_app_colors};

use super::search::find_match;
use crate::app::navigation::{navigate_to_room, navigate_to_room_at_event};
use crate::utils::room_preview::{last_message, preview_text};

// ---------------------------------------------------------------------------
// RoomSearchTile
// ---------------------------------------------------------------------------

#[derive(PartialEq)]
pub struct RoomSearchTile {
    pub room_id: String,
    pub display_name: String,
    /// The query: its match in the name is bold.
    pub query: String,
}

impl Component for RoomSearchTile {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let room_id = self.room_id.clone();
        let display_name = &self.display_name;
        let name = match find_match(display_name, &self.query) {
            Some((start, end)) => paragraph()
                .span(Span::new(display_name[..start].to_string()))
                .span(Span::new(display_name[start..end].to_string()).font_weight(FontWeight::BOLD))
                .span(Span::new(display_name[end..].to_string())),
            None => paragraph().span(display_name.clone()),
        }
        .width(Size::fill())
        .max_lines(1)
        .text_overflow(TextOverflow::Ellipsis)
        .font_size(15.)
        .color(c.on_surface);

        let mut item = ListItem::with_headline(name).leading(Avatar {
            size: 44.,
            source: Some(AvatarSource::Room(room_id.clone())),
            name: display_name.clone(),
            color: id_color(&room_id),
        });
        if let Some(subtitle) = room_subtitle(&room_id) {
            item = item.supporting(subtitle);
        }
        item.on_press(move |_| navigate_to_room(room_id.clone()))
    }
}

/// The room's latest message, else its member count (groups).
fn room_subtitle(room_id: &str) -> Option<String> {
    let room = crate::utils::matrix::get_room(room_id)?;
    let me = crate::utils::matrix::my_user_id();
    if let Some((body, prefix)) = last_message(&room, me.as_deref()) {
        return Some(preview_text(&body, &prefix, None));
    }
    if room.is_dm() {
        return None;
    }
    match room.joined_members_count() {
        0 => None,
        1 => Some("1 member".to_string()),
        n => Some(format!("{n} members")),
    }
}

// ---------------------------------------------------------------------------
// UserSearchTile
// ---------------------------------------------------------------------------

#[derive(PartialEq)]
pub struct UserSearchTile {
    pub user: UserInfo,
}

impl Component for UserSearchTile {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let user = self.user.clone();
        PersonRow::new(&user.user_id, &user.display_name, user.avatar.clone())
            .trailing(
                SvgViewer::new(freya_icons::lucide::message_circle())
                    .width(Size::px(18.))
                    .height(Size::px(18.))
                    .color(c.primary),
            )
            .on_press(move |_| crate::app::navigation::open_dm(user.clone()))
    }
}

// ---------------------------------------------------------------------------
// MessageSearchTile
// ---------------------------------------------------------------------------

#[derive(PartialEq)]
pub struct MessageSearchTile {
    pub event_id: String,
    pub room_id: String,
    pub room_name: String,
    pub body: String,
    pub sender_display_name: String,
    pub event_ts_ms: u64,
    pub is_dm: bool,
}

impl Component for MessageSearchTile {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let event_id = self.event_id.clone();
        let room_id = self.room_id.clone();
        let room_name = self.room_name.clone();
        let body = self.body.clone();
        let sender_display_name = self.sender_display_name.clone();
        let is_dm = self.is_dm;
        let ts = MilliSecondsSinceUnixEpoch(
            UInt::try_from(self.event_ts_ms).unwrap_or(UInt::from(0u32)),
        );
        let date_str = format_timestamp(ts);
        let color = id_color(&room_id);
        let bg = c.surface;
        let rid = room_id.clone();
        let eid = event_id.clone();

        rect()
            .width(Size::fill())
            .background(bg)
            .overflow(Overflow::Clip)
            .on_press(move |_| navigate_to_room_at_event(rid.clone(), eid.clone()))
            .child(
                Ripple::new().color(c.primary).width(Size::fill()).child(
                    rect()
                        .horizontal()
                        .content(Content::Flex)
                        .width(Size::fill())
                        .padding(Gaps::new(10., 16., 10., 16.))
                        .spacing(12.)
                        .cross_align(Alignment::Center)
                        .child(Avatar {
                            size: 38.,
                            source: Some(AvatarSource::Room(room_id.clone())),
                            name: room_name.clone(),
                            color,
                        })
                        .child(
                            rect()
                                .vertical()
                                .width(Size::flex(1.0))
                                .spacing(2.)
                                .child(
                                    // Top row: room name + timestamp
                                    rect()
                                        .horizontal()
                                        .content(Content::Flex)
                                        .width(Size::fill())
                                        .cross_align(Alignment::Center)
                                        .child(
                                            label()
                                                .text(room_name)
                                                .font_size(13.)
                                                .color(c.on_surface_muted)
                                                .width(Size::flex(1.0)),
                                        )
                                        .child(
                                            label()
                                                .text(date_str)
                                                .font_size(11.)
                                                .color(c.on_surface_muted),
                                        ),
                                )
                                .child(label().text(body).font_size(14.).color(c.on_surface))
                                .maybe_child(if !is_dm {
                                    Some(
                                        label()
                                            .text(sender_display_name)
                                            .font_size(12.)
                                            .color(c.on_surface_muted),
                                    )
                                } else {
                                    None
                                }),
                        ),
                ),
            )
            .hoverable(Size::fill(), Size::auto(), 0.)
    }
}
