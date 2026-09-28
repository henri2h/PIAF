mod action_popup_overlay;
mod bookmark_picker_overlay;
mod compose_bar;
mod detail_modal;
mod focus;
mod media_items;
mod message_action_popup;
mod message_row;
mod room_app_bar;
mod room_start_banner;
mod timeline_task;
mod timeline_view;
mod ui_ctx;
mod use_room_timeline;

use freya::prelude::*;

use action_popup_overlay::action_popup_overlay;
use bookmark_picker_overlay::BookmarkPickerOverlay;
use compose_bar::ComposeBar;
use focus::take_focus_event;
use media_items::media_items;
use room_app_bar::room_app_bar;
use timeline_task::MsgAction;
use timeline_view::TimelineView;
use ui_ctx::{RoomUiCtx, use_provide_room_ui_ctx};
use use_room_timeline::use_room_timeline;

use crate::logging::{PERF, RenderTimer};
use crate::ui::components::{MediaViewer, UserPopupOverlay};
use crate::utils::matrix::my_user_id;
use crate::utils::use_app_colors;

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

/// A room: app bar, timeline, composer, and their overlays.
/// Timeline updates re-render `TimelineView`, not this component.
#[derive(PartialEq)]
pub struct RoomPage {
    pub room_id: String,
}

impl Component for RoomPage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let room_id = self.room_id.clone();

        let _timer = RenderTimer::new("RoomPage");
        use_hook(|| tracing::debug!(target: PERF, room_id, "mount RoomPage"));

        let ui = use_provide_room_ui_ctx();
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

        let body = if ui.image_viewer.read().is_some() {
            let handle = timeline.handle.clone();
            MediaViewer {
                items: media_items(&timeline.state.messages.read()),
                selected_key: ui.image_viewer,
                on_load_more: Some(std::rc::Rc::new(move || handle.paginate())),
            }
            .into_element()
        } else {
            let name = timeline.state.room_name.read().clone();
            rect()
                .expanded()
                .vertical()
                .content(Content::Flex)
                .child(detail_modal::DetailModalOverlay {
                    modal: ui.detail_modal,
                    room_id: room_id.clone(),
                })
                .child(UserPopupOverlay {
                    open: ui.user_popup,
                })
                .child(action_popup_overlay(
                    ui,
                    room_id.clone(),
                    name.clone(),
                    my_user_id(),
                    timeline.handle.actions(),
                    c,
                ))
                .child(BookmarkPickerOverlay {
                    pending: ui.bookmark_picker,
                })
                .child(room_app_bar(&room_id, &name, c))
                .child(TimelineView {
                    room_id: room_id.clone(),
                    timeline: timeline.clone(),
                    scroll_controller,
                })
                .child(bottom_bar(
                    ui,
                    &timeline.state.typing_users.read(),
                    &room_id,
                    &timeline,
                    c,
                ))
                .into_element()
        };

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(body)
    }
}

/// Typing indicator + composer. Keyed on the edited event so edits get a fresh composer.
fn bottom_bar(
    ui: RoomUiCtx,
    typing_users: &[String],
    room_id: &str,
    timeline: &use_room_timeline::RoomTimeline,
    c: crate::utils::const_values::AppColors,
) -> Rect {
    let (compose_key, initial_text) = match ui.edit_info.read().as_ref() {
        Some((eid, body)) => (format!("edit-{eid}"), body.clone()),
        None => ("normal".to_string(), String::new()),
    };
    rect()
        .vertical()
        .width(Size::fill())
        .maybe_child(typing_label(typing_users).map(|text| {
            rect()
                .width(Size::fill())
                .padding(Gaps::new(2., 16., 2., 16.))
                .child(
                    label()
                        .text(text)
                        .font_size(12.)
                        .color(c.on_surface_variant),
                )
        }))
        .child(
            rect()
                .key(compose_key)
                .width(Size::fill())
                .child(ComposeBar {
                    initial_text,
                    edit_info: ui.edit_info,
                    reply_info: ui.reply_info,
                    room_id: room_id.to_string(),
                    action_tx: timeline.handle.actions(),
                }),
        )
}

fn typing_label(users: &[String]) -> Option<String> {
    match users {
        [] => None,
        [a] => Some(format!("{a} is typing…")),
        [a, b] => Some(format!("{a} and {b} are typing…")),
        _ => Some("Several people are typing…".to_string()),
    }
}
