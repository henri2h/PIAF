use std::sync::Arc;

use freya::prelude::*;
use matrix_sdk_ui::timeline::TimelineItem;

use crate::ui::components::UserPopupInfo;
use crate::utils::bookmarks::BookmarkEntry;

/// Overlay/popup state shared by the room page, its rows and its overlays.
#[derive(Clone, Copy, PartialEq)]
pub(super) struct RoomUiCtx {
    /// `(event_id, body)` being edited.
    pub edit_info: State<Option<(String, String)>>,
    /// `(event_id, sender, body)` being replied to.
    pub reply_info: State<Option<(String, String, String)>>,
    /// Key of the media item open in the viewer.
    pub image_viewer: State<Option<String>>,
    pub detail_modal: State<Option<Arc<TimelineItem>>>,
    pub action_popup: State<Option<Arc<TimelineItem>>>,
    pub bookmark_picker: State<Option<BookmarkEntry>>,
    pub user_popup: State<Option<UserPopupInfo>>,
    /// Bumped to move keyboard focus into the composer (`i`).
    pub compose_focus: State<u64>,
}

pub(super) fn use_provide_room_ui_ctx() -> RoomUiCtx {
    let ctx = RoomUiCtx {
        edit_info: use_state(|| None),
        reply_info: use_state(|| None),
        image_viewer: use_state(|| None),
        detail_modal: use_state(|| None),
        action_popup: use_state(|| None),
        bookmark_picker: use_state(|| None),
        user_popup: use_state(|| None),
        compose_focus: use_state(|| 0),
    };
    use_provide_context(|| ctx);
    ctx
}

pub(super) fn use_room_ui_ctx() -> RoomUiCtx {
    use_consume::<RoomUiCtx>()
}
