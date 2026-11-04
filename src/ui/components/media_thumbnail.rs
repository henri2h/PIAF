use bytes::Bytes;
use freya::prelude::*;
use freya_query::prelude::QueryCapability;

use crate::utils::queries::{
    FetchMediaContent, FetchMediaThumbnail, media_source_key, media_thumbnail_key,
};

use super::ViewerSource;
use super::use_fade;

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
///
/// `thumb_size`: when `Some((w, h))`, uses `MediaFormat::Thumbnail` (server-side
/// scaling) for the fallback source instead of downloading the full image.
pub struct MediaThumbnail {
    pub item_key: String,
    pub blurhash: Option<String>,
    pub thumbnail_source: Option<ViewerSource>,
    /// Full-image source used as a last resort when no thumbnail is available.
    pub fallback_source: Option<ViewerSource>,
    /// Requested thumbnail pixel dimensions for server-side scaling of fallback.
    pub thumb_size: Option<(u32, u32)>,
}

impl PartialEq for MediaThumbnail {
    fn eq(&self, other: &Self) -> bool {
        self.item_key == other.item_key
    }
}

/// Loads slower than this fade in.
const SLOW_LOAD: std::time::Duration = std::time::Duration::from_millis(100);

impl Component for MediaThumbnail {
    fn render(&self) -> impl IntoElement {
        // Refcounted: re-renders hand the same buffer to the image viewer.
        let mut thumb_bytes: State<Option<Bytes>> = use_state(|| None);
        // Set when the thumbnail took long enough to be noticed loading: only
        // then does it fade in. Cached ones still arrive asynchronously, and
        // fading those would flash every cell remounted while scrolling.
        let mut fade_in = use_state(|| false);

        // Prefer thumbnail_source (already server-scaled); fall back to fallback_source.
        // For fallback remote sources, use FetchMediaThumbnail if thumb_size is given.
        use_hook(|| {
            let thumb_size = self.thumb_size;
            let remote_thumb = match &self.thumbnail_source {
                Some(ViewerSource::Remote(s)) => Some((s.clone(), false)),
                _ => match &self.fallback_source {
                    Some(ViewerSource::Remote(s)) => Some((s.clone(), true)),
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
            if let Some((source, is_fallback)) = remote_thumb {
                let started = std::time::Instant::now();
                spawn(async move {
                    let result = match (is_fallback, thumb_size) {
                        (true, Some((w, h))) => {
                            FetchMediaThumbnail
                                .run(&media_thumbnail_key(&source, w, h))
                                .await
                        }
                        _ => FetchMediaContent.run(&media_source_key(&source)).await,
                    };
                    if let Ok(b) = result {
                        thumb_bytes.set(Some(Bytes::from(b)));
                        if started.elapsed() > SLOW_LOAD {
                            fade_in.set(true);
                        }
                    }
                });
            } else if let Some(b) = local_bytes {
                thumb_bytes.set(Some(Bytes::from(b)));
            }
        });

        // Placeholder, decoded once per mount (it used to be decoded and
        // PNG-encoded on every render, which was costly in grids).
        let blurhash_png: Option<Bytes> = use_hook(|| {
            self.blurhash
                .as_deref()
                .and_then(|h| decode_blurhash_to_png(h, 40, 30))
                .map(Bytes::from)
        });
        let opacity = use_fade(*fade_in.read(), 200);
        let item_key = self.item_key.clone();
        let fill = |source: (String, Bytes)| {
            ImageViewer::new(source)
                .width(Size::fill())
                .height(Size::fill())
                .aspect_ratio(AspectRatio::Max)
                .image_cover(ImageCover::Center)
        };
        let placeholder = || match blurhash_png.clone() {
            Some(bh) => fill((format!("{item_key}-bh"), bh)).into_element(),
            None => rect()
                .width(Size::fill())
                .height(Size::fill())
                .center()
                .child(CircularLoader::new())
                .into_element(),
        };

        let Some(thumb) = thumb_bytes.read().clone() else {
            return placeholder();
        };
        let image = fill((format!("{item_key}-thumb"), thumb));
        if !*fade_in.read() || opacity >= 1. {
            return image.into_element();
        }
        rect()
            .expanded()
            .child(placeholder())
            .child(
                rect()
                    .position(Position::new_absolute().top(0.).left(0.))
                    .expanded()
                    .opacity(opacity)
                    .child(image),
            )
            .into_element()
    }
}

#[cfg(test)]
mod tests {
    use super::decode_blurhash_to_png;

    #[test]
    fn valid_blurhash_produces_png_bytes() {
        // "L6PZfSi_.AyE_3t7t7R**0o#DgR4" is a widely-used example blurhash.
        let result = decode_blurhash_to_png("L6PZfSi_.AyE_3t7t7R**0o#DgR4", 40, 30);
        assert!(result.is_some(), "expected Some for a valid blurhash");
        let bytes = result.unwrap();
        // PNG files start with the 8-byte PNG signature.
        assert!(bytes.starts_with(b"\x89PNG"), "output should be a PNG");
        assert!(bytes.len() > 8, "PNG should have content beyond the header");
    }

    #[test]
    fn invalid_blurhash_returns_none() {
        // Garbage string — decode should fail gracefully.
        assert!(decode_blurhash_to_png("not-a-real-hash!!!!", 40, 30).is_none());
    }

    #[test]
    fn zero_dimension_returns_none() {
        // 0-pixel image is meaningless; encoder should reject it.
        assert!(decode_blurhash_to_png("L6PZfSi_.AyE_3t7t7R**0o#DgR4", 0, 30).is_none());
    }
}
