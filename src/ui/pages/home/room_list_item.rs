use freya::prelude::*;
use freya_material_design::prelude::Ripple;
use freya_query::prelude::*;
use freya_router::prelude::RouterContext;
use matrix_sdk::{
    Room, RoomHero,
    latest_events::LatestEventValue,
    ruma::events::{
        AnySyncMessageLikeEvent, AnySyncTimelineEvent, SyncMessageLikeEvent,
        room::message::MessageType,
    },
};
use std::time::Duration;

use crate::Route;
use crate::ui::components::{Avatar, StackedAvatar, user_color};
use crate::ui::pages::home::ActiveRoomCtx;
use crate::utils::use_app_colors;
use crate::utils::{format_timestamp, queries::FetchSenderName};

enum SenderPrefix {
    None,
    Me,
    Other(String),
}

fn last_message(room: &Room, my_user_id: Option<&str>) -> (String, SenderPrefix) {
    match room.latest_event() {
        LatestEventValue::RemoteInvite { inviter, .. } => {
            let body = if let Some(ref inviter_id) = inviter {
                format!("You were invited by {}", inviter_id.localpart())
            } else {
                "You were invited".to_string()
            };
            return (body, SenderPrefix::None);
        }
        LatestEventValue::Remote(_) => {}
        _ => {
            return (String::new(), SenderPrefix::None);
        }
    }
    let LatestEventValue::Remote(latest) = room.latest_event() else {
        return (String::new(), SenderPrefix::None);
    };

    let (body, sender_id) = match latest.raw().deserialize() {
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
            SyncMessageLikeEvent::Original(msg),
        ))) => {
            let body = match msg.content.msgtype {
                MessageType::Text(t) => t.body,
                MessageType::Notice(n) => n.body,
                MessageType::Image(_) => "📷 Image".to_string(),
                MessageType::File(_) => "📎 File".to_string(),
                MessageType::Audio(_) => "🎵 Audio".to_string(),
                MessageType::Video(_) => "🎬 Video".to_string(),
                MessageType::Emote(e) => format!("* {}", e.body),
                MessageType::Location(_) => "📍 Location".to_string(),
                MessageType::VerificationRequest(_) => "🔐 Verification request".to_string(),
                ref other => {
                    println!(
                        "[piaf] unhandled MessageType in room {}: {:?}",
                        room.room_id(),
                        other.msgtype()
                    );
                    return (String::new(), SenderPrefix::None);
                }
            };
            (body, msg.sender.to_string())
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
            SyncMessageLikeEvent::Redacted(r),
        ))) => ("🗑 Message deleted".to_string(), r.sender.to_string()),
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomEncrypted(
            SyncMessageLikeEvent::Original(r),
        ))) => ("🔐 Encrypted message".to_string(), r.sender.to_string()),
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomEncrypted(
            SyncMessageLikeEvent::Redacted(r),
        ))) => ("🗑 Message deleted".to_string(), r.sender.to_string()),
        _ => {
            println!(
                "[{}] {}",
                room.name().unwrap_or_default(),
                latest.raw().json().to_string()
            );

            // Fallback: read sender + event type from raw JSON for unhandled events
            // (state events, call events, etc.) so old rooms show something.
            let Ok(val) = latest
                .raw()
                .deserialize_as::<matrix_sdk::ruma::exports::serde_json::Value>()
            else {
                println!(
                    "[piaf] failed to deserialize last event as JSON in room {}",
                    room.room_id()
                );
                return (String::new(), SenderPrefix::None);
            };
            let sender = val
                .get("sender")
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string();
            let event_type = val.get("type").and_then(|v| v.as_str()).unwrap_or("");
            let body = match event_type {
                "m.sticker" => "🎉 Sticker".to_string(),
                "m.call.invite" | "m.call.answer" | "m.call.hangup" => "📞 Call".to_string(),
                "m.room.member" => "Activity".to_string(),
                "m.poll.start" | "org.matrix.msc3381.poll.start" => "📊 Poll".to_string(),
                "m.location" | "org.matrix.msc3488.location" => "📍 Location".to_string(),
                "m.room.tombstone" => "🚪 Room upgraded".to_string(),
                "m.room.name"
                | "m.room.topic"
                | "m.room.avatar"
                | "m.room.canonical_alias"
                | "m.room.power_levels"
                | "m.room.join_rules"
                | "m.room.guest_access"
                | "m.room.history_visibility"
                | "m.room.server_acl"
                | "m.room.create" => "Room settings updated".to_string(),
                "m.reaction" => return (String::new(), SenderPrefix::None),
                _ => {
                    println!(
                        "[piaf] unhandled last event type: {event_type:?} in room {}",
                        room.room_id()
                    );
                    return (String::new(), SenderPrefix::None);
                }
            };
            if sender.is_empty() {
                return (String::new(), SenderPrefix::None);
            }
            (body, sender)
        }
    };

    if my_user_id == Some(sender_id.as_str()) {
        (body, SenderPrefix::Me)
    } else if room.is_dm() {
        (body, SenderPrefix::None)
    } else {
        (body, SenderPrefix::Other(sender_id))
    }
}

fn hero_initial(hero: &RoomHero) -> String {
    hero.display_name
        .as_ref()
        .and_then(|n| n.chars().next())
        .or_else(|| hero.user_id.localpart().chars().next())
        .map(|c| c.to_uppercase().to_string())
        .unwrap_or_else(|| "?".to_string())
}

// ---------------------------------------------------------------------------
// Android long-press helpers
// ---------------------------------------------------------------------------

#[cfg(target_os = "android")]
fn start_long_press(mut press_gen: State<u64>, mut long_pressed: State<bool>) {
    let next_gen = *press_gen.read() + 1;
    *press_gen.write() = next_gen;
    spawn(async move {
        tokio::time::sleep(std::time::Duration::from_millis(350)).await;
        if *press_gen.read() == next_gen {
            *long_pressed.write() = true;
            tokio::time::sleep(std::time::Duration::from_millis(500)).await;
            if *press_gen.read() == next_gen {
                *long_pressed.write() = false;
            }
        }
    });
}

#[cfg(target_os = "android")]
fn cancel_long_press(mut press_gen: State<u64>, mut long_pressed: State<bool>) {
    *press_gen.write() += 1;
    *long_pressed.write() = false;
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
    }
}

impl Component for RoomListItem {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let room = self.room.clone();
        let room_id = room.room_id().to_string();
        let mut hovered: State<bool> = use_state(|| false);
        let is_muted: State<bool> = use_state(|| false);
        let is_active = try_consume_context::<ActiveRoomCtx>()
            .map(|ctx| ctx.0.read().as_deref() == Some(room_id.as_str()))
            .unwrap_or(false);

        #[cfg(target_os = "android")]
        let mut press_gen: State<u64> = use_state(|| 0u64);
        #[cfg(target_os = "android")]
        let mut long_pressed: State<bool> = use_state(|| false);

        use_hook(|| {
            if room.latest_event().is_none() {
                let room_id = room.room_id().to_owned();
                tokio::task::spawn(async move {
                    if let Some(rq) = crate::REQUESTER.get() {
                        rq.fetch_room_previews(vec![room_id]);
                    }
                });
            }
        });

        use_hook(|| {
            let room_id = room_id.clone();
            let mut is_muted = is_muted;
            spawn(async move {
                let Some(client) = crate::utils::matrix::CLIENT.get().cloned() else {
                    return;
                };
                let (tx, rx) = futures::channel::oneshot::channel::<bool>();
                tokio::task::spawn(async move {
                    let Ok(parsed_id) = matrix_sdk::ruma::RoomId::parse(&room_id) else {
                        let _ = tx.send(false);
                        return;
                    };
                    let ns = client.notification_settings().await;
                    let mode = ns.get_user_defined_room_notification_mode(&parsed_id).await;
                    let _ = tx.send(
                        mode == Some(matrix_sdk::notification_settings::RoomNotificationMode::Mute),
                    );
                });
                if let Ok(muted) = rx.await {
                    *is_muted.write() = muted;
                }
            });
        });

        let fetch_key = room_id.clone();

        let my_user_id = crate::utils::matrix::CLIENT
            .get()
            .and_then(|c| c.user_id().map(|id| id.to_string()));
        let (msg_body, sender_prefix) = last_message(&room, my_user_id.as_deref());

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
            match &sender_prefix {
                SenderPrefix::None => msg_body.clone(),
                SenderPrefix::Me => format!("You: {msg_body}"),
                SenderPrefix::Other(_) => {
                    let sender_reader = sender_query.read();
                    let display_name =
                        sender_reader.state().ok().cloned().unwrap_or_else(
                            || match &sender_prefix {
                                SenderPrefix::Other(uid) => uid
                                    .trim_start_matches('@')
                                    .split(':')
                                    .next()
                                    .unwrap_or(uid)
                                    .to_string(),
                                _ => String::new(),
                            },
                        );
                    format!("{display_name}: {msg_body}")
                }
            }
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
        let is_unread = room.num_unread_messages() > 0 || notif_count > 0;
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

        let room_is_muted = *is_muted.read();
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
        } else if *long_pressed.read() {
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
                                                svg(freya_icons::lucide::bell_off())
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
            .on_pointer_enter(move |_| *hovered.write() = true)
            .on_pointer_leave(move |_| *hovered.write() = false)
            .on_press(move |_| {
                if crate::WIDE_MODE.load(std::sync::atomic::Ordering::Relaxed) {
                    if let Some(tx) = crate::ACTIVE_ROOM_TX.get() {
                        let _ = tx.send(Some(room_id_nav.clone()));
                    }
                }
                let _ = RouterContext::get().push(Route::RoomPage {
                    room_id: room_id_nav.clone(),
                });
            });

        #[cfg(not(target_os = "android"))]
        return outer.child(highlighted);

        #[cfg(target_os = "android")]
        return outer
            .on_touch_start(move |_: Event<TouchEventData>| {
                start_long_press(press_gen, long_pressed)
            })
            .on_touch_move(move |_: Event<TouchEventData>| {
                cancel_long_press(press_gen, long_pressed)
            })
            .on_touch_end(move |_: Event<TouchEventData>| {
                cancel_long_press(press_gen, long_pressed)
            })
            .on_touch_cancel(move |_: Event<TouchEventData>| {
                cancel_long_press(press_gen, long_pressed)
            })
            .child(highlighted);
    }
}
