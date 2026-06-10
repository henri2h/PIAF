use freya::prelude::*;
use freya_material_design::prelude::Ripple;
use matrix_sdk::ruma::{MilliSecondsSinceUnixEpoch, UInt};

use crate::ui::components::{Avatar, user_color};
use crate::utils::{format_timestamp, use_app_colors};

fn navigate_to_room_at_event(room_id: String, event_id: String) {
    if let Some(tx) = crate::FOCUS_EVENT_TX.get() {
        let _ = tx.send(Some((room_id.clone(), event_id)));
    }
    super::navigate_to_room(room_id);
}

// ---------------------------------------------------------------------------
// RoomSearchTile
// ---------------------------------------------------------------------------

#[derive(PartialEq)]
pub struct RoomSearchTile {
    pub room_id: String,
    pub display_name: String,
}

impl Component for RoomSearchTile {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut hovered: State<bool> = use_state(|| false);

        let room_id = self.room_id.clone();
        let display_name = self.display_name.clone();
        let initial = display_name
            .chars()
            .next()
            .map(|ch| ch.to_uppercase().to_string())
            .unwrap_or_else(|| "?".to_string());
        let color = user_color(&room_id);
        let bg = if *hovered.read() {
            c.surface_container
        } else {
            c.surface
        };
        let rid = room_id.clone();

        rect()
            .width(Size::fill())
            .background(bg)
            .overflow(Overflow::Clip)
            .on_pointer_enter(move |_| *hovered.write() = true)
            .on_pointer_leave(move |_| *hovered.write() = false)
            .on_press(move |_| super::navigate_to_room(rid.clone()))
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
                            size: 44.,
                            bytes: None,
                            fetch_key: Some(room_id.clone()),
                            initial,
                            color,
                            image_key: room_id.clone(),
                        })
                        .child(
                            label()
                                .text(display_name)
                                .font_size(15.)
                                .color(c.on_surface)
                                .width(Size::flex(1.0)),
                        ),
                ),
            )
    }
}

// ---------------------------------------------------------------------------
// UserSearchTile
// ---------------------------------------------------------------------------

#[derive(PartialEq)]
pub struct UserSearchTile {
    pub user_id: String,
    pub display_name: String,
    pub avatar_mxc: Option<String>,
}

impl Component for UserSearchTile {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut hovered: State<bool> = use_state(|| false);

        let user_id = self.user_id.clone();
        let display_name = self.display_name.clone();
        let avatar_mxc = self.avatar_mxc.clone();
        let initial = display_name
            .chars()
            .next()
            .map(|ch| ch.to_uppercase().to_string())
            .unwrap_or_else(|| "?".to_string());
        let color = user_color(&user_id);
        let bg = if *hovered.read() {
            c.surface_container
        } else {
            c.surface
        };
        let uid = user_id.clone();

        rect()
            .width(Size::fill())
            .background(bg)
            .overflow(Overflow::Clip)
            .on_pointer_enter(move |_| *hovered.write() = true)
            .on_pointer_leave(move |_| *hovered.write() = false)
            .on_press(move |_| {
                let uid = uid.clone();
                spawn(async move {
                    if let Some(room_id) = crate::utils::matrix::create_or_get_dm(uid).await {
                        super::navigate_to_room(room_id);
                    }
                });
            })
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
                            size: 42.,
                            bytes: None,
                            fetch_key: avatar_mxc,
                            initial,
                            color,
                            image_key: user_id.clone(),
                        })
                        .child(
                            rect()
                                .vertical()
                                .width(Size::flex(1.0))
                                .spacing(2.)
                                .child(
                                    label()
                                        .text(display_name)
                                        .font_size(15.)
                                        .color(c.on_surface),
                                )
                                .child(
                                    label()
                                        .text(user_id)
                                        .font_size(12.)
                                        .color(c.on_surface_muted),
                                ),
                        )
                        .child(
                            svg(freya_icons::lucide::message_circle())
                                .width(Size::px(18.))
                                .height(Size::px(18.))
                                .color(c.primary),
                        ),
                ),
            )
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
        let mut hovered: State<bool> = use_state(|| false);

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
        let initial = room_name
            .chars()
            .next()
            .map(|ch| ch.to_uppercase().to_string())
            .unwrap_or_else(|| "?".to_string());
        let color = user_color(&room_id);
        let bg = if *hovered.read() {
            c.surface_container
        } else {
            c.surface
        };
        let rid = room_id.clone();
        let eid = event_id.clone();

        rect()
            .width(Size::fill())
            .background(bg)
            .overflow(Overflow::Clip)
            .on_pointer_enter(move |_| *hovered.write() = true)
            .on_pointer_leave(move |_| *hovered.write() = false)
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
                            bytes: None,
                            fetch_key: Some(room_id.clone()),
                            initial,
                            color,
                            image_key: room_id.clone(),
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
    }
}
