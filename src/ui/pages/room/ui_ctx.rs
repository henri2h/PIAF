use std::sync::Arc;

use freya::prelude::*;
use matrix_sdk_ui::timeline::TimelineItem;

use crate::ui::components::UserPopupInfo;
use crate::utils::bookmarks::BookmarkEntry;

/// The message being replied to.
#[derive(Clone, Debug, PartialEq)]
pub(super) struct ReplyTo {
    pub event_id: String,
    pub sender: String,
    /// One-line preview (`room_preview::reply_preview`).
    pub body: String,
}

/// Our message being edited.
#[derive(Clone, Debug, PartialEq)]
pub(super) struct Editing {
    pub event_id: String,
    pub body: String,
}

/// Overlay/popup state shared by the room page, its rows and its overlays.
#[derive(Clone, Copy, PartialEq)]
pub(super) struct RoomUiCtx {
    pub editing: State<Option<Editing>>,
    pub reply_to: State<Option<ReplyTo>>,
    /// Key of the media item open in the viewer.
    pub image_viewer: State<Option<String>>,
    pub detail_modal: State<Option<Arc<TimelineItem>>>,
    pub action_popup: State<Option<Arc<TimelineItem>>>,
    /// Event waiting for the user to confirm its deletion.
    pub confirm_delete: State<Option<String>>,
    pub bookmark_picker: State<Option<BookmarkEntry>>,
    pub user_popup: State<Option<UserPopupInfo>>,
    /// Bumped to move keyboard focus into the composer (`i`).
    pub compose_focus: State<u64>,
    /// The timeline's scroll.
    #[cfg_attr(not(target_os = "android"), allow(dead_code))]
    pub scroll: ScrollController,
}

pub(super) fn use_provide_room_ui_ctx(scroll: ScrollController) -> RoomUiCtx {
    let ctx = RoomUiCtx {
        editing: use_state(|| None),
        reply_to: use_state(|| None),
        image_viewer: use_state(|| None),
        detail_modal: use_state(|| None),
        action_popup: use_state(|| None),
        confirm_delete: use_state(|| None),
        bookmark_picker: use_state(|| None),
        user_popup: use_state(|| None),
        compose_focus: use_state(|| 0),
        scroll,
    };
    use_provide_context(|| ctx);
    ctx
}

pub(super) fn use_room_ui_ctx() -> RoomUiCtx {
    use_consume::<RoomUiCtx>()
}

impl RoomUiCtx {
    /// Starts a reply to `reply_to` and moves focus into the composer.
    pub fn reply(mut self, reply_to: ReplyTo) {
        self.editing.set(None);
        self.reply_to.set(Some(reply_to));
        *self.compose_focus.write() += 1;
    }
}
