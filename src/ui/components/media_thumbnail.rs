use bytes::Bytes;
use freya::prelude::*;
use freya_query::prelude::QueryCapability;

use crate::utils::queries::{FetchMediaContent, media_source_key};

use super::ViewerSource;

pub fn decode_blurhash_to_png(hash: &str, width: u32, height: u32) -> Option<Vec<u8>> {
    let pixels = blurhash::decode(hash, width, height, 1.0).ok()?;
    let mut bytes = Vec::new();
    let mut encoder = png::Encoder::new(&mut bytes, width, height);
    encoder.set_color(png::ColorType::Rgba);
    encoder.set_depth(png::BitDepth::Eight);
    let mut writer = encoder.write_header().ok()?;
    writer.write_image_data(&pixels).ok()?;
    drop(writer);
    Some(bytes)
}

/// Displays a thumbnail preview: blurhash → fetched thumbnail → spinner.
/// Never downloads the full-resolution image.
pub struct MediaThumbnail {
    pub item_key: String,
    pub blurhash: Option<String>,
    pub thumbnail_source: Option<ViewerSource>,
}

impl PartialEq for MediaThumbnail {
    fn eq(&self, other: &Self) -> bool {
        self.item_key == other.item_key
    }
}

impl Component for MediaThumbnail {
    fn render(&self) -> impl IntoElement {
        let mut thumb_bytes: State<Option<Vec<u8>>> = use_state(|| None);
        // Track which item_key the current thumb_bytes belongs to so we can
        // reset and re-fetch whenever the component is reused for a new image.
        let mut tracked_key: State<String> = use_state(|| String::new());

        let item_key = self.item_key.clone();
        let fetch_thumb = match &self.thumbnail_source {
            Some(ViewerSource::Remote(s)) => Some(s.clone()),
            _ => None,
        };
        let local_thumb = match &self.thumbnail_source {
            Some(ViewerSource::Bytes(b)) => Some(b.clone()),
            _ => None,
        };

        // Runs whenever tracked_key changes. On first render tracked_key is ""
        // which differs from item_key, so the fetch starts immediately.
        // On navigation (same component position, new item_key) tracked_key is
        // still the old key, so the effect fires again and re-fetches.
        use_side_effect(move || {
            let prev = tracked_key.read().clone();
            if prev == item_key {
                return;
            }
            *tracked_key.write() = item_key.clone();
            *thumb_bytes.write() = None;

            if let Some(source) = fetch_thumb.clone() {
                let key = media_source_key(&source);
                spawn(async move {
                    if let Ok(b) = FetchMediaContent.run(&key).await {
                        *thumb_bytes.write() = Some(b);
                    }
                });
            } else if let Some(b) = local_thumb.clone() {
                *thumb_bytes.write() = Some(b);
            }
        });

        let item_key = self.item_key.clone();
        let bh_png = self
            .blurhash
            .as_deref()
            .and_then(|h| decode_blurhash_to_png(h, 40, 30));
        let th = thumb_bytes.read().clone();

        match (th, bh_png) {
            (Some(tb), _) => ImageViewer::new((format!("{item_key}-thumb"), Bytes::from(tb)))
                .width(Size::fill())
                .height(Size::fill())
                .image_cover(ImageCover::Center)
                .into_element(),
            (None, Some(bh)) => ImageViewer::new((format!("{item_key}-bh"), Bytes::from(bh)))
                .width(Size::fill())
                .height(Size::fill())
                .image_cover(ImageCover::Center)
                .into_element(),
            (None, None) => rect()
                .width(Size::fill())
                .height(Size::fill())
                .center()
                .child(CircularLoader::new())
                .into_element(),
        }
    }
}
