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

/// Displays a thumbnail: blurhash → thumbnail → fallback (full image) → spinner.
/// The caller provides the keyed parent rect; use_hook fires on each mount.
pub struct MediaThumbnail {
    pub item_key: String,
    pub blurhash: Option<String>,
    pub thumbnail_source: Option<ViewerSource>,
    /// Full-image source used as a last resort when no thumbnail is available.
    pub fallback_source: Option<ViewerSource>,
}

impl PartialEq for MediaThumbnail {
    fn eq(&self, other: &Self) -> bool {
        self.item_key == other.item_key
    }
}

impl Component for MediaThumbnail {
    fn render(&self) -> impl IntoElement {
        let mut thumb_bytes: State<Option<Vec<u8>>> = use_state(|| None);

        // Prefer thumbnail; fall back to full image when thumbnail absent.
        let fetch_source = match &self.thumbnail_source {
            Some(ViewerSource::Remote(s)) => Some(s.clone()),
            _ => match &self.fallback_source {
                Some(ViewerSource::Remote(s)) => Some(s.clone()),
                _ => None,
            },
        };
        let local_bytes = match &self.thumbnail_source {
            Some(ViewerSource::Bytes(b)) => Some(b.clone()),
            _ => match &self.fallback_source {
                Some(ViewerSource::Bytes(b)) => Some(b.clone()),
                _ => None,
            },
        };

        use_hook(move || {
            if let Some(source) = fetch_source {
                let key = media_source_key(&source);
                spawn(async move {
                    if let Ok(b) = FetchMediaContent.run(&key).await {
                        *thumb_bytes.write() = Some(b);
                    }
                });
            } else if let Some(b) = local_bytes {
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
