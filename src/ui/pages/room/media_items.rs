use std::sync::Arc;

use matrix_sdk::ruma::events::room::message::MessageType;
use matrix_sdk_ui::timeline::{TimelineDetails, TimelineItem, TimelineItemContent};

use crate::ui::components::{MediaViewerItem, ViewerSource};
use crate::utils::format_timestamp;

/// Images in the loaded timeline, for the media viewer.
pub(super) fn media_items(msgs: &[Arc<TimelineItem>]) -> Vec<MediaViewerItem> {
    msgs.iter()
        .filter_map(|item| {
            let event = item.as_event()?;
            let event_id = event.event_id()?.to_string();
            let TimelineItemContent::MsgLike(msg_like) = event.content() else {
                return None;
            };
            let msg = msg_like.as_message()?;
            let MessageType::Image(img) = msg.msgtype() else {
                return None;
            };
            let sender = match event.sender_profile() {
                TimelineDetails::Ready(p) => p
                    .display_name
                    .clone()
                    .unwrap_or_else(|| event.sender().to_string()),
                _ => event.sender().to_string(),
            };
            Some(MediaViewerItem {
                key: event_id,
                source: ViewerSource::Remote(img.source.clone()),
                info: Some((sender, format_timestamp(event.timestamp()))),
                caption: caption(&img.body),
                blurhash: img.info.as_ref().and_then(|i| i.blurhash.clone()),
                thumbnail_source: img.info.as_ref().and_then(|i| {
                    i.thumbnail_source
                        .as_ref()
                        .map(|s| ViewerSource::Remote(s.clone()))
                }),
            })
        })
        .collect()
}

/// Image body, unless it's just a filename.
fn caption(body: &str) -> Option<String> {
    const FILE_EXTS: [&str; 5] = [".jpg", ".jpeg", ".png", ".gif", ".webp"];
    let is_filename = body.starts_with("image") || FILE_EXTS.iter().any(|e| body.ends_with(e));
    (!is_filename && !body.is_empty()).then(|| body.to_string())
}

#[cfg(test)]
mod tests {
    use super::caption;

    #[test]
    fn filenames_are_not_captions() {
        assert_eq!(caption("IMG_1.jpg"), None);
        assert_eq!(caption("image.png"), None);
        assert_eq!(caption(""), None);
        assert_eq!(caption("Sunset"), Some("Sunset".to_string()));
    }
}
