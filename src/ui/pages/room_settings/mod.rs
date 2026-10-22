use freya::prelude::*;

use crate::utils::avatars::AvatarSource;

use crate::ui::components::HoverableExt;
use freya_router::prelude::RouterContext;

use crate::Route;
use crate::ui::components::{Avatar, TopAppBar, UserPopupInfo, UserPopupOverlay};
use crate::utils::use_app_colors;

mod notif_mode_selector;
use crate::ui::components::M3ListItem;
use crate::ui::components::confirm_dialog;
use crate::ui::pages::room_members::member_row;
use crate::utils::bridges::{self, BridgeInfo};
use crate::utils::extract_urls;
use crate::utils::members::{self, MemberItem};
use matrix_sdk::notification_settings::RoomNotificationMode;
use notif_mode_selector::{load_notif_mode, notif_icon, notif_label, notif_sheet};

const MEMBER_PREVIEW_COUNT: usize = 5;

#[derive(PartialEq)]
pub struct RoomSettings {
    pub room_id: String,
}

impl Component for RoomSettings {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let room_id = self.room_id.clone();

        let mut room_name: State<String> = use_state(String::new);
        let mut member_count: State<u64> = use_state(|| 0u64);
        let mut members: State<Vec<MemberItem>> = use_state(|| vec![]);
        let mut room_topic: State<Option<String>> = use_state(|| None);
        let mut room_version: State<Option<String>> = use_state(|| None);
        let notif_mode: State<Option<RoomNotificationMode>> = use_state(|| None);
        let mut notif_open: State<bool> = use_state(|| false);
        let mut confirm_leave: State<bool> = use_state(|| false);
        let user_popup: State<Option<UserPopupInfo>> = use_state(|| None);
        let leaving: State<bool> = use_state(|| false);
        let mut copied: State<bool> = use_state(|| false);
        let mut bridge: State<Option<BridgeInfo>> = use_state(|| None);
        let mut can_invite: State<bool> = use_state(|| false);

        use_hook(|| {
            let room_id = room_id.clone();
            let mut notif_mode = notif_mode;
            spawn(async move {
                notif_mode.set(load_notif_mode(room_id).await);
            });
        });

        use_hook(|| {
            let room_id = room_id.clone();
            spawn(async move {
                let rx = crate::utils::on_tokio(async move {
                    let room = crate::utils::matrix::get_room(&room_id)?;
                    let name = room
                        .display_name()
                        .await
                        .map(|n| n.to_string())
                        .unwrap_or_default();
                    let count = room.joined_members_count();
                    let topic = room.topic();
                    let version = room.version().map(|v| v.as_str().to_string());
                    let member_list = members::joined(&room).await;
                    let bridge = bridges::bridge_info(&room).await;
                    let me = crate::utils::matrix::my_user_id()
                        .and_then(|id| matrix_sdk::ruma::UserId::parse(id).ok());
                    let can_invite = match me {
                        Some(me) => room
                            .get_member_no_sync(&me)
                            .await
                            .ok()
                            .flatten()
                            .is_some_and(|m| m.can_invite()),
                        None => false,
                    };
                    Some((name, count, member_list, topic, version, bridge, can_invite))
                });
                if let Some(Some((name, count, member_list, topic, version, info, invite))) =
                    rx.await
                {
                    *room_name.write() = name;
                    *member_count.write() = count;
                    *members.write() = member_list;
                    *room_topic.write() = topic;
                    *room_version.write() = version;
                    bridge.set(info);
                    can_invite.set(invite);
                }
            });
        });

        let name = room_name.read().clone();
        let count = *member_count.read();
        let member_list = members.read().clone();
        let topic = room_topic.read().clone();
        let version = room_version.read().clone();
        let is_leaving = *leaving.read();
        let current_notif = *notif_mode.read();

        let room_id_media = room_id.clone();
        let room_id_members = room_id.clone();
        let room_id_avatar = room_id.clone();
        let room_id_copy = room_id.clone();
        let room_id_leave = room_id.clone();

        let bridge_info = bridge.read().clone();
        let may_invite = *can_invite.read();
        let room_id_invite = room_id.clone();
        // A bridged room's members are mostly puppets: the bridge row says
        // who is there; the full list stays one tap away.
        let preview_members: Vec<&MemberItem> = if bridge_info.is_some() {
            vec![]
        } else {
            member_list.iter().take(MEMBER_PREVIEW_COUNT).collect()
        };
        let all_shown = bridge_info.is_none() && member_list.len() <= MEMBER_PREVIEW_COUNT;

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar::new("Room info"))
            .child(
                ScrollView::new()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .child(
                        rect()
                            .vertical()
                            .width(Size::fill())
                            // ── Header ────────────────────────────────────────
                            .child(
                                rect()
                                    .vertical()
                                    .cross_align(Alignment::Center)
                                    .spacing(8.)
                                    .width(Size::fill())
                                    .padding(Gaps::new(24., 16., 16., 16.))
                                    .child(Avatar {
                                        size: 80.,
                                        source: Some(AvatarSource::Room(room_id.clone())),
                                        name: name.to_string(),
                                        color: crate::utils::id_color(&room_id),
                                    })
                                    .child(
                                        label()
                                            .text(name)
                                            .font_size(22.)
                                            .font_weight(FontWeight::MEDIUM)
                                            .color(c.on_surface),
                                    )
                                    .child(
                                        label()
                                            .text(format!("{count} members"))
                                            .font_size(14.)
                                            .color(c.on_surface_variant),
                                    )
                                    .child(if let Some(ref desc) = topic {
                                        let urls = extract_urls(desc);
                                        rect()
                                            .vertical()
                                            .width(Size::fill())
                                            .padding(Gaps::new(4., 0., 0., 0.))
                                            .spacing(4.)
                                            .cross_align(Alignment::Center)
                                            .child(
                                                label()
                                                    .width(Size::fill())
                                                    .text(desc.clone())
                                                    .font_size(14.)
                                                    .color(c.on_surface_variant)
                                                    .text_align(TextAlign::Center),
                                            )
                                            .children(urls.into_iter().map(|url| {
                                                let url_open = url.clone();
                                                rect()
                                                    .horizontal()
                                                    .spacing(4.)
                                                    .cross_align(Alignment::Center)
                                                    .on_press(move |_| {
                                                        Platform::get().open_url(url_open.clone())
                                                    })
                                                    .child(
                                                        SvgViewer::new(
                                                            freya_icons::lucide::external_link(),
                                                        )
                                                        .color(c.primary)
                                                        .width(Size::px(12.))
                                                        .height(Size::px(12.)),
                                                    )
                                                    .child(
                                                        label()
                                                            .text(url)
                                                            .font_size(13.)
                                                            .color(c.primary),
                                                    )
                                                    .hoverable(Size::auto(), Size::auto(), 0.)
                                            }))
                                            .into_element()
                                    } else {
                                        rect().into_element()
                                    }),
                            )
                            // ── Bridge ────────────────────────────────────────
                            .maybe_child(bridge_info.clone().map(|info| {
                                let detail = match (&info.channel, &info.bot) {
                                    (Some(ch), Some(bot)) => Some(format!("{ch} · via {bot}")),
                                    (Some(ch), None) => Some(ch.clone()),
                                    (None, Some(bot)) => Some(format!("via {bot}")),
                                    (None, None) => None,
                                };
                                rect()
                                    .width(Size::fill())
                                    .child(M3ListItem {
                                        icon: freya_icons::lucide::cable(),
                                        item_label: format!("Bridged to {}", info.network),
                                        sublabel: detail,
                                        icon_color: c.primary,
                                        destructive: false,
                                        on_press: EventHandler::new(|_| {}),
                                    })
                                    .child(divider(c))
                            }))
                            // ── Media ─────────────────────────────────────────
                            .child(M3ListItem {
                                icon: freya_icons::lucide::image(),
                                item_label: "Media".to_string(),
                                sublabel: None,
                                icon_color: c.on_surface_variant,
                                destructive: false,
                                on_press: EventHandler::new(move |_| {
                                    crate::app::navigation::push(Route::RoomMediaPage {
                                        room_id: room_id_media.clone(),
                                    });
                                }),
                            })
                            .child(divider(c))
                            // ── Notifications ─────────────────────────────────
                            .child(M3ListItem {
                                icon: notif_icon(current_notif),
                                item_label: "Notifications".to_string(),
                                sublabel: Some(notif_label(current_notif).to_string()),
                                icon_color: c.on_surface_variant,
                                destructive: false,
                                on_press: EventHandler::new(move |_| *notif_open.write() = true),
                            })
                            .child(divider(c))
                            // ── Members section ───────────────────────────────
                            .child(
                                rect()
                                    .vertical()
                                    .width(Size::fill())
                                    .padding(Gaps::new(16., 16., 4., 16.))
                                    .child(
                                        label()
                                            .text(format!("Members · {count}"))
                                            .font_size(12.)
                                            .font_weight(FontWeight::MEDIUM)
                                            .color(c.primary),
                                    ),
                            )
                            .children(preview_members.into_iter().map(|m| {
                                // Keyed by user: unkeyed rows are matched by position.
                                rect()
                                    .key(&m.user_id)
                                    .width(Size::fill())
                                    .child(member_row(m, &room_id_avatar, user_popup, c))
                                    .into_element()
                            }))
                            .maybe_child(may_invite.then(|| M3ListItem {
                                icon: freya_icons::lucide::user_plus(),
                                item_label: "Add people".to_string(),
                                sublabel: None,
                                icon_color: c.primary,
                                destructive: false,
                                on_press: EventHandler::new(move |_| {
                                    crate::app::navigation::push(Route::RoomInvite {
                                        room_id: room_id_invite.clone(),
                                    });
                                }),
                            }))
                            // Only when the list above doesn't show everyone.
                            .maybe_child((!all_shown).then(|| M3ListItem {
                                icon: freya_icons::lucide::users(),
                                item_label: format!("See all {count} members"),
                                sublabel: None,
                                icon_color: c.on_surface_variant,
                                destructive: false,
                                on_press: EventHandler::new(move |_| {
                                    crate::app::navigation::push(Route::RoomMembers {
                                        room_id: room_id_members.clone(),
                                    });
                                }),
                            }))
                            .child(divider(c))
                            // ── Leave room ────────────────────────────────────
                            .child(M3ListItem {
                                icon: freya_icons::lucide::log_out(),
                                item_label: if is_leaving {
                                    "Leaving…".to_string()
                                } else {
                                    "Leave room".to_string()
                                },
                                sublabel: None,
                                icon_color: c.error,
                                destructive: true,
                                on_press: EventHandler::new(move |_| {
                                    if !is_leaving {
                                        *confirm_leave.write() = true;
                                    }
                                }),
                            })
                            .child(divider(c))
                            // ── Advanced: last, rarely needed ────────────────
                            .child(section_label("Advanced", c))
                            .child(M3ListItem {
                                icon: freya_icons::lucide::hash(),
                                item_label: "Room ID".to_string(),
                                sublabel: Some(room_id.clone()),
                                icon_color: c.on_surface_variant,
                                destructive: false,
                                on_press: EventHandler::new(move |_| {
                                    use freya::prelude::Clipboard;
                                    let _ = Clipboard::set(room_id_copy.clone());
                                    *copied.write() = true;
                                    spawn(async move {
                                        timer(std::time::Duration::from_secs(2)).await;
                                        *copied.write() = false;
                                    });
                                }),
                            })
                            .child(divider(c))
                            .child(M3ListItem {
                                icon: freya_icons::lucide::info(),
                                item_label: "Room version".to_string(),
                                sublabel: version,
                                icon_color: c.on_surface_variant,
                                destructive: false,
                                on_press: EventHandler::new(|_| {}),
                            })
                            .child(rect().width(Size::fill()).height(Size::px(16.))),
                    ),
            )
            // ── Overlays ──────────────────────────────────────────────────────
            .maybe_child(
                (*notif_open.read())
                    .then(|| notif_sheet(notif_mode, room_id.clone(), notif_open, c)),
            )
            .maybe_child(
                (*confirm_leave.read())
                    .then(|| leave_confirm_overlay(room_id_leave.clone(), confirm_leave, leaving)),
            )
            .child(UserPopupOverlay { open: user_popup })
    }
}

fn section_label(text: &str, c: crate::utils::const_values::AppColors) -> Element {
    rect()
        .width(Size::fill())
        .padding(Gaps::new(16., 16., 4., 16.))
        .child(
            label()
                .text(text.to_string())
                .font_size(12.)
                .font_weight(FontWeight::MEDIUM)
                .color(c.primary),
        )
        .into_element()
}

fn divider(c: crate::utils::const_values::AppColors) -> Element {
    rect()
        .width(Size::fill())
        .height(Size::px(1.))
        .background(c.outline_variant)
        .into_element()
}

fn leave_confirm_overlay(
    room_id: String,
    mut open: State<bool>,
    mut leaving: State<bool>,
) -> Element {
    confirm_dialog(
        "Leave room?",
        "You will leave this room. You can rejoin later if it is public or if you get an invite.",
        "Leave",
        move || open.set(false),
        move || {
            open.set(false);
            leaving.set(true);
            let room_id = room_id.clone();
            spawn(async move {
                let left = crate::utils::on_tokio(async move {
                    match crate::utils::matrix::get_room(&room_id) {
                        Some(room) => room.leave().await.is_ok(),
                        None => false,
                    }
                });
                if left.await.unwrap_or(false) {
                    let _ = RouterContext::get().push(Route::HomePage);
                }
                leaving.set(false);
            });
        },
    )
    .into_element()
}
