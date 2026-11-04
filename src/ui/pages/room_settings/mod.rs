use std::sync::atomic::Ordering;
use std::time::Duration;

use freya::prelude::*;
use freya_router::prelude::RouterContext;
use matrix_sdk::Room;
use matrix_sdk::notification_settings::RoomNotificationMode;
use matrix_sdk::ruma::events::room::MediaSource;

use crate::app::navigation::push;
use crate::ui::components::{
    Avatar, HoverableExt, ListItem, MediaViewer, MediaViewerItem, TopAppBar, UserPopupInfo,
    UserPopupOverlay, ViewerSource, confirm_dialog, use_app_bar_tint,
};
use crate::ui::pages::room_members::member_row;
use crate::utils::avatars::AvatarSource;
use crate::utils::bridges::{self, BridgeInfo};
use crate::utils::const_values::AppColors;
use crate::utils::haptics::{self, Haptic};
use crate::utils::members::{self, MemberItem};
use crate::utils::use_app_colors;
use crate::{Route, WIDE_MODE};

mod action_buttons;
mod notif_mode_selector;
mod topic;
use action_buttons::{Action, action_buttons};
use notif_mode_selector::{load_notif_mode, notif_icon, notif_sheet, notif_short_label};
use topic::RoomTopic;

const MEMBER_PREVIEW_COUNT: usize = 5;
const AVATAR_KEY: &str = "room-avatar";
const COPIED_FOR: Duration = Duration::from_secs(2);

/// What the page shows about the room, loaded once off the UI thread.
#[derive(Default)]
struct RoomInfo {
    name: String,
    member_count: u64,
    members: Vec<MemberItem>,
    topic: Option<String>,
    version: Option<String>,
    /// The room's own picture (`mxc://`), if it has one.
    avatar_url: Option<String>,
    bridge: Option<BridgeInfo>,
    can_invite: bool,
}

impl RoomInfo {
    async fn load(room: Room) -> Self {
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
        Self {
            name: room
                .display_name()
                .await
                .map(|n| n.to_string())
                .unwrap_or_default(),
            member_count: room.joined_members_count(),
            members: members::joined(&room).await,
            topic: room.topic(),
            version: room.version().map(|v| v.as_str().to_string()),
            avatar_url: room.avatar_url().map(|u| u.to_string()),
            bridge: bridges::bridge_info(&room).await,
            can_invite,
        }
    }
}

#[derive(PartialEq)]
pub struct RoomSettings {
    pub room_id: String,
}

impl Component for RoomSettings {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let room_id = self.room_id.clone();

        let mut info: State<RoomInfo> = use_state(RoomInfo::default);
        let notif_mode: State<Option<RoomNotificationMode>> = use_state(|| None);
        let notif_open: State<bool> = use_state(|| false);
        let confirm_leave: State<bool> = use_state(|| false);
        let user_popup: State<Option<UserPopupInfo>> = use_state(|| None);
        let leaving: State<bool> = use_state(|| false);
        // Bumped by each copy; "Copied" shows while non-zero.
        let copied: State<u32> = use_state(|| 0);
        // Key of the avatar while it is open full screen.
        let avatar_viewer: State<Option<String>> = use_state(|| None);
        let scroll = use_scroll_controller(ScrollConfig::default);
        use_app_bar_tint(scroll);

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
                let loaded = crate::utils::on_tokio(async move {
                    Some(RoomInfo::load(crate::utils::matrix::get_room(&room_id)?).await)
                });
                if let Some(Some(loaded)) = loaded.await {
                    info.set(loaded);
                }
            });
        });

        let info = info.read();

        // The room's own picture (a DM without one shows the other user's
        // avatar, which doesn't open).
        if avatar_viewer.read().is_some()
            && let Some(mxc) = info.avatar_url.clone()
        {
            return avatar_viewer_page(mxc, avatar_viewer);
        }

        let notif = *notif_mode.read();
        let actions = room_actions(&room_id, notif, notif_open, info.can_invite);

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar::new("Room info"))
            .child(
                ScrollView::new_controlled(scroll)
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .child(
                        rect()
                            .vertical()
                            .width(Size::fill())
                            .child(header(&room_id, &info, avatar_viewer, c))
                            .child(action_buttons(actions, c))
                            .maybe_child(info.bridge.as_ref().map(|b| bridge_row(b, c)))
                            .child(members_section(&room_id, &info, user_popup, c))
                            .child(advanced_section(&room_id, &info, copied, c))
                            .child(leave_row(*leaving.read(), confirm_leave, c)),
                    ),
            )
            // ── Overlays ──────────────────────────────────────────────────────
            .maybe_child(
                (*notif_open.read())
                    .then(|| notif_sheet(notif_mode, room_id.clone(), notif_open, c)),
            )
            .maybe_child(
                (*confirm_leave.read())
                    .then(|| leave_confirm_overlay(room_id.clone(), confirm_leave, leaving)),
            )
            .child(UserPopupOverlay { open: user_popup })
            .into_element()
    }
}

fn avatar_viewer_page(mxc: String, selected_key: State<Option<String>>) -> Element {
    MediaViewer {
        items: vec![MediaViewerItem {
            key: AVATAR_KEY.to_string(),
            source: ViewerSource::Remote(MediaSource::Plain(mxc.into())),
            info: None,
            caption: None,
            blurhash: None,
            thumbnail_source: None,
        }],
        selected_key,
        on_load_more: None,
        on_show_in_chat: None,
    }
    .into_element()
}

/// Avatar (opens full screen when the room has a picture), name, member
/// count and topic.
fn header(
    room_id: &str,
    info: &RoomInfo,
    mut avatar_viewer: State<Option<String>>,
    c: AppColors,
) -> Element {
    let size = if WIDE_MODE.load(Ordering::Relaxed) {
        80.
    } else {
        96.
    };
    let avatar = Avatar {
        size,
        source: Some(AvatarSource::Room(room_id.to_string())),
        name: info.name.clone(),
        color: crate::utils::id_color(room_id),
    };
    let avatar = if info.avatar_url.is_some() {
        rect()
            .on_press(move |_| avatar_viewer.set(Some(AVATAR_KEY.to_string())))
            .child(avatar)
            .hoverable(Size::auto(), Size::auto(), size / 2.)
    } else {
        avatar.into_element()
    };
    rect()
        .vertical()
        .cross_align(Alignment::Center)
        .spacing(8.)
        .width(Size::fill())
        .padding(Gaps::new(24., 16., 16., 16.))
        .child(avatar)
        .child(
            label()
                .text(info.name.clone())
                .font_size(22.)
                .font_weight(FontWeight::MEDIUM)
                .color(c.on_surface),
        )
        .child(
            label()
                .text(format!("{} members", info.member_count))
                .font_size(14.)
                .color(c.on_surface_variant),
        )
        .maybe_child(info.topic.clone().map(|topic| RoomTopic { topic }))
        .into_element()
}

/// Notifications, search, media and (when allowed) invite.
fn room_actions(
    room_id: &str,
    notif: Option<RoomNotificationMode>,
    mut notif_open: State<bool>,
    may_invite: bool,
) -> Vec<Action> {
    let route_action = |icon, label: &str, route: Route| Action {
        icon,
        label: label.to_string(),
        highlighted: false,
        on_press: Box::new(move |_| push(route.clone())),
    };
    let room_id = room_id.to_string();
    let mut actions = vec![
        Action {
            icon: notif_icon(notif),
            label: notif_short_label(notif).to_string(),
            highlighted: notif == Some(RoomNotificationMode::Mute),
            on_press: Box::new(move |_| {
                haptics::play(Haptic::Click);
                notif_open.set(true);
            }),
        },
        route_action(
            freya_icons::lucide::search(),
            "Search",
            Route::RoomSearch {
                room_id: room_id.clone(),
            },
        ),
        route_action(
            freya_icons::lucide::image(),
            "Media",
            Route::RoomMediaPage {
                room_id: room_id.clone(),
            },
        ),
    ];
    if may_invite {
        actions.push(route_action(
            freya_icons::lucide::user_plus(),
            "Invite",
            Route::RoomInvite { room_id },
        ));
    }
    actions
}

fn bridge_row(info: &BridgeInfo, c: AppColors) -> Element {
    let detail = match (&info.channel, &info.bot) {
        (Some(ch), Some(bot)) => Some(format!("{ch} · via {bot}")),
        (Some(ch), None) => Some(ch.clone()),
        (None, Some(bot)) => Some(format!("via {bot}")),
        (None, None) => None,
    };
    let row = ListItem::new(format!("Bridged to {}", info.network))
        .leading(row_icon(freya_icons::lucide::cable(), c.primary));
    match detail {
        Some(detail) => row.supporting(detail),
        None => row,
    }
    .into_element()
}

/// The first members, then "See all" when they aren't everyone.
fn members_section(
    room_id: &str,
    info: &RoomInfo,
    user_popup: State<Option<UserPopupInfo>>,
    c: AppColors,
) -> Element {
    let count = info.member_count;
    // A bridged room's members are mostly puppets: the bridge row says
    // who is there; the full list stays one tap away.
    let preview: &[MemberItem] = if info.bridge.is_some() {
        &[]
    } else {
        &info.members[..info.members.len().min(MEMBER_PREVIEW_COUNT)]
    };
    let all_shown = preview.len() == info.members.len();
    let room_id_members = room_id.to_string();
    rect()
        .vertical()
        .width(Size::fill())
        .child(section_label(&format!("Members · {count}"), c))
        .children(preview.iter().map(|m| {
            // Keyed by user: unkeyed rows are matched by position.
            rect()
                .key(&m.user_id)
                .width(Size::fill())
                .child(member_row(m, room_id, user_popup, c))
                .into_element()
        }))
        .maybe_child((!all_shown).then(|| {
            ListItem::new(format!("See all {count} members"))
                .leading(row_icon(freya_icons::lucide::users(), c.on_surface_variant))
                .trailing(chevron(c))
                .on_press(move |_| {
                    push(Route::RoomMembers {
                        room_id: room_id_members.clone(),
                    })
                })
        }))
        .into_element()
}

/// Room ID (tap to copy) and version: rarely needed, so near the end.
fn advanced_section(
    room_id: &str,
    info: &RoomInfo,
    mut copied: State<u32>,
    c: AppColors,
) -> Element {
    let is_copied = *copied.read() != 0;
    let room_id_copy = room_id.to_string();
    rect()
        .vertical()
        .width(Size::fill())
        .child(section_label("Advanced", c))
        .child(
            ListItem::new("Room ID")
                .supporting(if is_copied {
                    "Copied to clipboard".to_string()
                } else {
                    room_id.to_string()
                })
                .leading(row_icon(freya_icons::lucide::hash(), c.on_surface_variant))
                .trailing(row_icon(
                    if is_copied {
                        freya_icons::lucide::check()
                    } else {
                        freya_icons::lucide::copy()
                    },
                    if is_copied {
                        c.primary
                    } else {
                        c.on_surface_variant
                    },
                ))
                .on_press(move |_| {
                    let _ = Clipboard::set(room_id_copy.clone());
                    let generation = copied.peek().wrapping_add(1).max(1);
                    copied.set(generation);
                    spawn(async move {
                        timer(COPIED_FOR).await;
                        // A later copy restarts the delay.
                        if *copied.peek() == generation {
                            copied.set(0);
                        }
                    });
                }),
        )
        .maybe_child(info.version.clone().map(|version| {
            ListItem::new("Room version")
                .supporting(version)
                .leading(row_icon(freya_icons::lucide::info(), c.on_surface_variant))
        }))
        .into_element()
}

/// Last on the page, set apart from the rest.
fn leave_row(is_leaving: bool, mut confirm: State<bool>, c: AppColors) -> Element {
    rect()
        .width(Size::fill())
        .padding(Gaps::new(16., 0., 16., 0.))
        .child(
            ListItem::with_headline(
                label()
                    .width(Size::fill())
                    .text(if is_leaving {
                        "Leaving…"
                    } else {
                        "Leave room"
                    })
                    .font_size(15.)
                    .font_weight(FontWeight::MEDIUM)
                    .color(c.error),
            )
            .leading(row_icon(freya_icons::lucide::log_out(), c.error))
            .on_press(move |_| {
                if !is_leaving {
                    confirm.set(true);
                }
            }),
        )
        .into_element()
}

/// A row's icon, centred in the width of a member avatar so the text lines up.
fn row_icon(icon: bytes::Bytes, color: (u8, u8, u8)) -> Element {
    rect()
        .width(Size::px(40.))
        .center()
        .child(
            SvgViewer::new(icon)
                .color(color)
                .width(Size::px(22.))
                .height(Size::px(22.)),
        )
        .into_element()
}

fn chevron(c: AppColors) -> Element {
    SvgViewer::new(freya_icons::lucide::chevron_right())
        .color(c.on_surface_variant)
        .width(Size::px(20.))
        .height(Size::px(20.))
        .into_element()
}

fn section_label(text: &str, c: AppColors) -> Element {
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
