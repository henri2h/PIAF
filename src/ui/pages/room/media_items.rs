use std::sync::Arc;

use matrix_sdk_ui::timeline::TimelineItem;

use crate::ui::components::MediaViewerItem;
use crate::utils::timeline_media;

/// Images in the loaded timeline, for the media viewer.
pub(super) fn media_items(msgs: &[Arc<TimelineItem>]) -> Vec<MediaViewerItem> {
    msgs.iter()
        .flat_map(|item| timeline_media::entries(item))
        .filter_map(|entry| MediaViewerItem::from_entry(&entry))
        .collect()
}
