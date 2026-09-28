use freya::prelude::*;
use freya_material_design::prelude::Ripple;
use freya_query::prelude::*;
use matrix_sdk::{Room, RoomHero};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{Duration, Instant};

use super::room_list_model::is_unread;
use crate::ui::components::{Avatar, StackedAvatar, user_color};
use crate::ui::pages::home::ActiveRoomCtx;
use crate::utils::matrix::{get_room, my_user_id};
use crate::utils::room_preview::{SenderPrefix, last_message, preview_text};
use crate::utils::use_app_colors;
use crate::utils::{format_timestamp, queries::FetchSenderName};

fn hero_initial(hero: &RoomHero) -> String {
    hero.display_name
        .as_ref()
        .and_then(|n| n.chars().next())
        .or_else(|| hero.user_id.localpart().chars().next())
        .map(|c| c.to_uppercase().to_string())
        .unwrap_or_else(|| "?".to_string())
}

// ---------------------------------------------------------------------------
// Timing helpers (debug builds only; grep adb logcat for [TIMING])
// ---------------------------------------------------------------------------

static MOUNT_COUNT: AtomicU64 = AtomicU64::new(0);

struct RenderTimer(Instant, u64);
impl Drop for RenderTimer {
    fn drop(&mut self) {
        #[cfg(debug_assertions)]
        {
            let dt = self.0.elapsed().as_micros();
            if dt > 200 {
                println!("[TIMING] RoomListItem render {}µs (mount #{})", dt, self.1);
            }
        };
    }
}

// ---------------------------------------------------------------------------
// RoomListItem
// ---------------------------------------------------------------------------

#[derive(Clone)]
pub struct RoomListItem {
    pub room: Room,
}

impl PartialEq for RoomListItem {
    fn eq(&self, other: &Self) -> bool {
        if self.room.room_id() != other.room.room_id() {
            return false;
        }
        self.room.recency_stamp() == other.room.recency_stamp()
            && self.room.num_unread_messages() == other.room.num_unread_messages()
            && self.room.num_unread_notifications() == other.room.num_unread_notifications()
            && self.room.latest_event().timestamp() == other.room.latest_event().timestamp()
            && self.room.cached_user_defined_notification_mode()
                == other.room.cached_user_defined_notification_mode()
    }
}

impl Component for RoomListItem {
    fn render(&self) -> impl IntoElement {
        let _render_timer = RenderTimer(Instant::now(), MOUNT_COUNT.load(Ordering::Relaxed));

        let c = use_app_colors();

        let room = self.room.clone();
        let room_id = room.room_id().to_string();
        let mut hovered: State<bool> = use_state(|| false);
        let room_is_muted = room.cached_user_defined_notification_mode()
            == Some(matrix_sdk::notification_settings::RoomNotificationMode::Mute);

        // `try_read` instead of `read`: the context may point at a State whose
        // owning scope was dropped (e.g. the dummy ctx UserPopupOverlay installs
        // at ScopeId::ROOT outlives the popup), which would panic on `read()`.
        let is_active = try_consume_context::<ActiveRoomCtx>()
            .and_then(|ctx| {
                ctx.0
                    .try_read()
                    .map(|v| v.as_deref() == Some(room_id.as_str()))
            })
            .unwrap_or(false);
        #[cfg(target_os = "android")]
        let swipe_state = super::room_swipe::use_swipe_state();
        #[cfg(not(target_os = "android"))]
        let recontact_hovered: State<bool> = use_state(|| false);
        #[cfg(not(target_os = "android"))]
        let archive_hovered: State<bool> = use_state(|| false);

        // Rooms without a cached latest event need a preview fetch.
        use_side_effect_with_deps(&room_id, move |rid: &String| {
            let rid = rid.clone();
            tokio::task::spawn(async move {
                if let Some(room) = get_room(&rid)
                    && room.latest_event().is_none()
                {
                    crate::REQUESTER
                        .get()
                        .expect("not initialized")
                        .fetch_room_previews(vec![room.room_id().to_owned()]);
                }
            });
        });

        let fetch_key = room_id.clone();

        let (msg_body, sender_prefix) = last_message(&room, my_user_id().as_deref())
            .unwrap_or((String::new(), SenderPrefix::None));

        let sender_query_key = match &sender_prefix {
            SenderPrefix::Other(uid) => format!("{}\x00{}", room_id, uid),
            _ => String::new(),
        };
        let sender_query = use_query(
            Query::new(sender_query_key.clone(), FetchSenderName)
                .stale_time(Duration::from_secs(3600)),
        );

        let msg = if msg_body.is_empty() {
            String::new()
        } else {
            let sender_name = sender_query.read().state().ok().cloned();
            preview_text(&msg_body, &sender_prefix, sender_name.as_deref())
        };

        let heroes = room.heroes();
        let is_dm = room.is_dm();
        let heroes_with_avatar: Vec<_> = heroes.iter().filter(|h| h.avatar_url.is_some()).collect();
        let show_stacked = !is_dm && heroes_with_avatar.len() >= 2;

        let name = room
            .cached_display_name()
            .map(|n| n.to_string())
            .unwrap_or_else(|| "Unknown".to_string());
        let initial = name
            .chars()
            .next()
            .unwrap_or('?')
            .to_uppercase()
            .to_string();
        let timestamp = room
            .latest_event()
            .timestamp()
            .map(format_timestamp)
            .unwrap_or_default();
        let notif_count = room.num_unread_notifications();
        let is_unread = is_unread(&room);
        let font_weight = if is_unread {
            FontWeight::BOLD
        } else {
            FontWeight::NORMAL
        };
        let timestamp_color: (u8, u8, u8) = if is_unread {
            c.primary
        } else {
            c.on_surface_faint
        };

        let room_id_nav = room_id.clone();

        #[cfg(not(target_os = "android"))]
        let bg = if is_active {
            c.surface_container_high
        } else if *hovered.read() {
            c.surface_container
        } else {
            c.surface
        };
        #[cfg(target_os = "android")]
        let bg = if is_active {
            c.surface_container_high
        } else if *swipe_state.long_pressed.read() {
            c.surface_container
        } else {
            c.surface
        };

        let inner = rect()
            .horizontal()
            .width(Size::fill())
            .height(Size::fill())
            .padding(Gaps::new(8., 12., 8., 12.))
            .spacing(14.)
            .cross_align(Alignment::Center)
            .child({
                let av: Element = if show_stacked {
                    let h1 = heroes_with_avatar[0];
                    let h2 = heroes_with_avatar[1];
                    StackedAvatar {
                        size: 48.,
                        initial1: hero_initial(h1),
                        color1: user_color(&h1.user_id.to_string()),
                        initial2: hero_initial(h2),
                        color2: user_color(&h2.user_id.to_string()),
                        border_color: bg,
                    }
                    .into()
                } else {
                    Avatar {
                        size: 48.,
                        bytes: None,
                        fetch_key: Some(fetch_key.clone()),
                        initial,
                        color: c.primary,
                        image_key: room_id.clone(),
                    }
                    .into()
                };
                av
            })
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
                                rect()
                                    .horizontal()
                                    .width(Size::flex(1.0))
                                    .cross_align(Alignment::Center)
                                    .child(
                                        label()
                                            .text(name)
                                            .width(Size::flex(1.0))
                                            .font_size(16.)
                                            .font_weight(font_weight)
                                            .color(c.on_surface),
                                    ),
                            )
                            .child(
                                rect()
                                    .vertical()
                                    .cross_align(Alignment::End)
                                    .spacing(4.)
                                    .child(
                                        rect()
                                            .horizontal()
                                            .spacing(4.)
                                            .cross_align(Alignment::Center)
                                            .child(if room_is_muted {
                                                SvgViewer::new(freya_icons::lucide::bell_off())
                                                    .width(Size::px(12.))
                                                    .height(Size::px(12.))
                                                    .color(c.on_surface_faint)
                                                    .into_element()
                                            } else {
                                                rect().into_element()
                                            })
                                            .child(
                                                label()
                                                    .text(timestamp)
                                                    .font_size(12.)
                                                    .font_weight(font_weight)
                                                    .color(timestamp_color),
                                            ),
                                    )
                                    .child(if notif_count > 0 {
                                        let count_text = if notif_count > 99 {
                                            "99+".to_string()
                                        } else {
                                            notif_count.to_string()
                                        };
                                        rect()
                                            .min_width(Size::px(20.))
                                            .height(Size::px(20.))
                                            .corner_radius(10.)
                                            .background(c.primary)
                                            .center()
                                            .padding(Gaps::new(0., 4., 0., 4.))
                                            .child(
                                                label()
                                                    .text(count_text)
                                                    .font_size(11.)
                                                    .color(c.on_primary),
                                            )
                                            .into_element()
                                    } else if is_unread {
                                        rect()
                                            .width(Size::px(8.))
                                            .height(Size::px(8.))
                                            .corner_radius(4.)
                                            .background(c.primary)
                                            .into_element()
                                    } else {
                                        rect()
                                            .width(Size::px(8.))
                                            .height(Size::px(8.))
                                            .into_element()
                                    }),
                            ),
                    )
                    .child(
                        label()
                            .text(msg)
                            .width(Size::fill())
                            .max_lines(1)
                            .color(c.on_surface_variant)
                            .font_size(13.5)
                            .font_weight(FontWeight::NORMAL),
                    ),
            );

        #[cfg(not(target_os = "android"))]
        let feedback: Element = Ripple::new()
            .width(Size::fill())
            .height(Size::fill())
            .child(inner)
            .into();
        #[cfg(target_os = "android")]
        let feedback: Element = inner.into();

        // Highlight rect: rounded background inside the outer padding gap.
        let highlighted: Element = rect()
            .width(Size::fill())
            .height(Size::fill())
            .background(bg)
            .corner_radius(12.)
            .overflow(Overflow::Clip)
            .child(feedback)
            .into();

        let outer = rect()
            .key(room_id.clone())
            .height(Size::px(80.))
            .width(Size::fill())
            .padding(Gaps::new(2., 8., 2., 8.))
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
            .on_press(move |_| crate::app::navigation::navigate_to_room(room_id_nav.clone()));

        // Desktop: hovering a row reveals two small action buttons (recontact /
        // archive) at its trailing edge instead of a swipe gesture.
        #[cfg(not(target_os = "android"))]
        {
            let hover_actions = hovered.read().then(|| {
                super::room_row_actions::hover_action_buttons(
                    c,
                    &room_id,
                    recontact_hovered,
                    archive_hovered,
                )
            });
            return outer.child(highlighted).maybe_child(hover_actions);
        }

        // Android: real swipe-to-reveal, handled entirely by `room_swipe`.
        #[cfg(target_os = "android")]
        return super::room_swipe::attach_swipe(
            outer,
            swipe_state,
            room_id.clone(),
            c,
            highlighted,
        );
    }
}
