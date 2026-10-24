mod bookmark_picker_overlay;
mod composer;
mod detail_modal;
mod focus;
mod invite_mutual_rooms;
mod invite_view;
mod jump_to_latest;
mod media_items;
mod message_actions;
#[cfg(target_os = "android")]
mod message_gesture;
#[cfg(not(target_os = "android"))]
mod message_hover_bar;
mod message_row;
mod outgoing;
mod room_app_bar;
mod room_start_banner;
mod timeline_task;
mod timeline_view;
mod typing_indicator;
mod ui_ctx;
mod use_room_timeline;

use std::rc::Rc;

use freya::prelude::*;

use bookmark_picker_overlay::BookmarkPickerOverlay;
use composer::ComposeBar;
use focus::take_focus_event;
use invite_view::InviteView;
use matrix_sdk::RoomState;
use media_items::media_items;
use message_actions::message_actions;
use room_app_bar::room_app_bar;
use timeline_task::MsgAction;
use timeline_view::TimelineView;
use typing_indicator::TypingIndicator;
use ui_ctx::{RoomUiCtx, use_provide_room_ui_ctx};
use use_room_timeline::use_room_timeline;

use crate::logging::{PERF, RenderTimer};
use crate::ui::components::{MediaViewer, Snackbar, UserPopupOverlay, confirm_dialog};
use crate::utils::matrix::{get_room, my_user_id};
use crate::utils::use_app_colors;
use crate::utils::use_watch_tick;

#[derive(Debug, Clone, PartialEq)]
pub(super) struct ReactionSender {
    pub user_id: String,
    pub display: String,
    pub timestamp: String,
}

#[derive(Debug, Clone, PartialEq)]
pub(super) struct Reaction {
    pub key: String,
    pub count: usize,
    pub reacted_by_me: bool,
    pub senders: Vec<ReactionSender>,
}

/// One [`Reaction`] per emoji of a timeline event; `me` marks ours.
pub(super) fn reactions(
    by_key: &matrix_sdk_ui::timeline::ReactionsByKeyBySender,
    me: Option<&str>,
) -> Vec<Reaction> {
    by_key
        .iter()
        .map(|(key, senders)| Reaction {
            key: key.clone(),
            count: senders.len(),
            reacted_by_me: me.is_some_and(|me| senders.keys().any(|uid| uid.as_str() == me)),
            senders: senders
                .iter()
                .map(|(uid, info)| ReactionSender {
                    display: uid.localpart().to_string(),
                    user_id: uid.to_string(),
                    timestamp: crate::utils::format_timestamp(info.timestamp),
                })
                .collect(),
        })
        .collect()
}

/// A room, or its invite screen while the invite is pending.
#[derive(PartialEq)]
pub struct RoomPage {
    pub room_id: String,
}

impl Component for RoomPage {
    fn render(&self) -> impl IntoElement {
        // Sync ticks catch invites accepted or declined on another device.
        let _sync = use_watch_tick(crate::SYNC_RX.get().expect("not initialized"));
        let joined = use_state(|| false);
        let is_invite = !*joined.read()
            && get_room(&self.room_id).is_some_and(|r| r.state() == RoomState::Invited);
        if is_invite {
            InviteView {
                room_id: self.room_id.clone(),
                joined,
            }
            .into_element()
        } else {
            RoomView {
                room_id: self.room_id.clone(),
            }
            .into_element()
        }
    }
}

/// A joined room: app bar, timeline, composer, and their overlays.
/// Timeline updates re-render `TimelineView`, not this component.
#[derive(PartialEq)]
struct RoomView {
    room_id: String,
}

impl Component for RoomView {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let room_id = self.room_id.clone();

        let _timer = RenderTimer::new("RoomView");
        use_hook(|| tracing::debug!(target: PERF, room_id, "mount RoomView"));

        use_hook(|| crate::utils::sync::subscribe_room(&room_id).map(Rc::new));
        let focus_event_id = use_hook(|| take_focus_event(&room_id));
        let timeline = use_room_timeline(&room_id, focus_event_id.clone());
        let scroll_controller = use_scroll_controller(|| ScrollConfig {
            default_vertical_position: if focus_event_id.is_some() {
                ScrollPosition::Start
            } else {
                ScrollPosition::End
            },
            vertical_anchor: ScrollAnchor::Bottom,
            ..Default::default()
        });
        let ui = use_provide_room_ui_ctx(scroll_controller);
        // Tinted while messages are scrolled under the bar.
        crate::ui::components::use_app_bar_tint(scroll_controller);

        let name = timeline.state.room_name.read().clone();
        let me = my_user_id();
        // The viewer covers the room instead of replacing it: the composer
        // (and its unsaved text) stays mounted underneath.
        let viewer = ui.image_viewer.read().is_some().then(|| {
            let handle = timeline.handle.clone();
            rect()
                .position(Position::new_absolute().top(0.).left(0.))
                .layer(VIEWER_LAYER)
                // Not `expanded()`: that is the space the siblings leave, none here.
                .width(Size::percent(100.))
                .height(Size::percent(100.))
                .child(MediaViewer {
                    items: media_items(&timeline.state.messages.read()),
                    selected_key: ui.image_viewer,
                    on_load_more: Some(std::rc::Rc::new(move || handle.paginate())),
                    on_show_in_chat: None,
                })
        });

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(detail_modal::DetailModalOverlay {
                modal: ui.detail_modal,
                room_id: room_id.clone(),
            })
            .child(UserPopupOverlay {
                open: ui.user_popup,
            })
            .maybe_child(message_actions(
                ui,
                &room_id,
                &name,
                me.as_deref(),
                timeline.handle.actions(),
                c,
            ))
            .maybe_child(delete_confirm(ui, timeline.handle.actions()))
            .child(BookmarkPickerOverlay {
                pending: ui.bookmark_picker,
            })
            .child(room_app_bar(&room_id, &name, true))
            .child(TimelineView {
                room_id: room_id.clone(),
                timeline: timeline.clone(),
                scroll_controller,
            })
            .child(Snackbar {
                message: timeline.state.error,
            })
            .child(TypingIndicator {
                users: timeline.state.typing_users,
            })
            .child(composer(ui, &room_id, &timeline))
            .maybe_child(viewer)
    }
}

/// Above the app bar, the composer and their menus.
const VIEWER_LAYER: i16 = 2000;

/// The composer, keyed on the edited event so an edit gets a fresh one.
fn composer(ui: RoomUiCtx, room_id: &str, timeline: &use_room_timeline::RoomTimeline) -> Rect {
    let key = match ui.editing.read().as_ref() {
        Some(editing) => format!("edit-{}", editing.event_id),
        // Per room: a room → room navigation reusing the page gets a fresh
        // composer (its draft, not the previous room's text).
        None => format!("normal-{room_id}"),
    };
    rect().key(key).width(Size::fill()).child(ComposeBar {
        room_id: room_id.to_string(),
        action_tx: timeline.handle.actions(),
    })
}

/// "Delete message?" for `ui.confirm_delete`.
fn delete_confirm(
    ui: RoomUiCtx,
    action_tx: std::sync::Arc<tokio::sync::mpsc::UnboundedSender<MsgAction>>,
) -> Option<Element> {
    let event_id = ui.confirm_delete.read().clone()?;
    let mut open = ui.confirm_delete;
    Some(
        confirm_dialog(
            "Delete message?",
            "It will be removed for everyone in the room.",
            "Delete",
            move || open.set(None),
            move || {
                open.set(None);
                let _ = action_tx.send(MsgAction::Delete {
                    event_id: event_id.clone(),
                });
            },
        )
        .into_element(),
    )
}
