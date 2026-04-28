use freya::prelude::*;
use freya_material_design::prelude::Ripple;
use freya_query::prelude::*;
use freya_router::prelude::RouterContext;
use matrix_sdk::{
    Room, RoomHero,
    ruma::events::{
        AnySyncMessageLikeEvent, AnySyncTimelineEvent, SyncMessageLikeEvent,
        room::message::MessageType,
    },
};
use std::time::Duration;

use crate::Route;
use crate::ui::components::{Avatar, StackedAvatar, user_color};
use crate::utils::use_app_colors;
use crate::utils::{format_timestamp, queries::FetchSenderName};

/// Parsed info about the latest message in a room.
enum SenderPrefix {
    /// DM room — no sender prefix
    None,
    /// Current user sent the message
    Me,
    /// Another user; contains the Matrix user ID for display name lookup
    Other(String),
}

/// Returns (body, sender_prefix) for the room's latest message.
fn last_message(room: &Room, my_user_id: Option<&str>) -> (String, SenderPrefix) {
    let Some(latest) = room.latest_event() else {
        return (String::new(), SenderPrefix::None);
    };
    let Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
        SyncMessageLikeEvent::Original(msg),
    ))) = latest.event().raw().deserialize()
    else {
        return (String::new(), SenderPrefix::None);
    };

    let body = match msg.content.msgtype {
        MessageType::Text(t) => t.body,
        MessageType::Image(_) => "📷 Image".to_string(),
        MessageType::File(_) => "📎 File".to_string(),
        MessageType::Audio(_) => "🎵 Audio".to_string(),
        MessageType::Video(_) => "🎬 Video".to_string(),
        _ => return (String::new(), SenderPrefix::None),
    };

    // Only prefix in group rooms
    if room.direct_targets().is_empty() {
        let sender_id = msg.sender.to_string();
        if my_user_id == Some(sender_id.as_str()) {
            (body, SenderPrefix::Me)
        } else {
            (body, SenderPrefix::Other(sender_id))
        }
    } else {
        (body, SenderPrefix::None)
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
    }
}

impl Component for RoomListItem {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let room = self.room.clone();
        let room_id = room.room_id().to_string();
        let mut hovered: State<bool> = use_state(|| false);
        let is_muted: State<bool> = use_state(|| false);

        // Android: long-press shimmer — activates after 350 ms hold without
        // finger movement, so scroll gestures never trigger the highlight.
        #[cfg(target_os = "android")]
        let mut press_gen: State<u64> = use_state(|| 0u64);
        #[cfg(target_os = "android")]
        let mut long_pressed: State<bool> = use_state(|| false);

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
        // Only show stacked avatars for group rooms where at least 2 heroes have an
        // avatar_url set — heroes without one are excluded to avoid meaningless placeholder
        // circles appearing in the stack.
        let is_dm = !room.direct_targets().is_empty();
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
            .new_latest_event_timestamp()
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

        // Background: hover on desktop, long-press highlight on Android.
        #[cfg(not(target_os = "android"))]
        let bg = if *hovered.read() {
            c.surface_container_high
        } else {
            c.surface
        };
        #[cfg(target_os = "android")]
        let bg = if *long_pressed.read() {
            c.surface_container_high
        } else {
            c.surface
        };

        // Inner content (shared between platforms)
        let inner = rect()
            .horizontal()
            .width(Size::fill())
            .height(Size::fill())
            .padding(Gaps::new(8., 16., 8., 16.))
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
                        border_color: c.surface,
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
                                        // Timestamp + optional muted icon on the same row.
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
                            .max_lines(2)
                            .color(c.on_surface_variant)
                            .font_size(13.5)
                            .font_weight(FontWeight::NORMAL),
                    ),
            );

        // Desktop: wrap with Ripple (fires on pointer_down — fine for mouse).
        // Android: plain inner rect; the background of the outer rect changes
        //          on long press via the touch handlers below.
        #[cfg(not(target_os = "android"))]
        let feedback: Element = Ripple::new()
            .width(Size::fill())
            .height(Size::fill())
            .child(inner)
            .into();
        #[cfg(target_os = "android")]
        let feedback: Element = inner.into();

        let outer = rect()
            .key(room_id.clone())
            .height(Size::px(80.))
            .width(Size::fill())
            .background(bg)
            .on_pointer_enter(move |e: Event<PointerEventData>| {
                if matches!(e.data(), PointerEventData::Mouse(_)) {
                    *hovered.write() = true;
                }
            })
            .on_pointer_leave(move |e: Event<PointerEventData>| {
                if matches!(e.data(), PointerEventData::Mouse(_)) {
                    *hovered.write() = false;
                }
            })
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

        // Android: attach touch handlers that detect long press vs scroll.
        // touch_move and touch_end/cancel bump the generation counter to abort
        // any in-flight long-press timer.
        #[cfg(not(target_os = "android"))]
        return outer.child(feedback);

        #[cfg(target_os = "android")]
        return outer
            .on_touch_start(move |_: Event<TouchEventData>| {
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
            })
            .on_touch_move(move |_: Event<TouchEventData>| {
                *press_gen.write() += 1;
                *long_pressed.write() = false;
            })
            .on_touch_end(move |_: Event<TouchEventData>| {
                *press_gen.write() += 1;
                *long_pressed.write() = false;
            })
            .on_touch_cancel(move |_: Event<TouchEventData>| {
                *press_gen.write() += 1;
                *long_pressed.write() = false;
            })
            .child(feedback);
    }
}
