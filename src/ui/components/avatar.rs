use std::rc::Rc;

use bytes::Bytes;
use freya::prelude::*;
use freya_components::{
    cache::{Asset, AssetAge, AssetCacher, AssetConfiguration, use_asset},
    image_viewer::ImageSource,
};
use freya_core::elements::image::{ImageHandle, SamplingMode};

use super::use_fade;
use crate::utils::{avatars::AvatarSource, use_app_colors};

/// Letter shown when there is no picture: the first letter or digit of
/// `name`, uppercased (skips the `@`/`#`/`!` of Matrix IDs).
pub fn initial(name: &str) -> String {
    name.chars()
        .find(|c| c.is_alphanumeric())
        .map(|c| c.to_uppercase().collect())
        .unwrap_or_else(|| "?".to_string())
}

fn mix(a: (u8, u8, u8), b: (u8, u8, u8), t: f32) -> (u8, u8, u8) {
    let m = |x: u8, y: u8| (x as f32 + (y as f32 - x as f32) * t).round() as u8;
    (m(a.0, b.0), m(a.1, b.1), m(a.2, b.2))
}

/// Tonal (background, letter) pair from an ID color: a soft tint with the
/// letter in a deep shade (light theme), or the reverse (dark theme).
fn disc_colors(color: (u8, u8, u8), dark: bool) -> ((u8, u8, u8), (u8, u8, u8)) {
    const WHITE: (u8, u8, u8) = (255, 255, 255);
    const BLACK: (u8, u8, u8) = (0, 0, 0);
    if dark {
        (mix(color, BLACK, 0.6), mix(color, WHITE, 0.65))
    } else {
        (mix(color, WHITE, 0.8), mix(color, BLACK, 0.3))
    }
}

fn initial_disc(size: f32, initial: &str, color: (u8, u8, u8), dark: bool) -> Element {
    let radius = size / 2.;
    let font_size = (size * 0.41).floor();
    let (background, foreground) = disc_colors(color, dark);
    rect()
        .width(Size::px(size))
        .height(Size::px(size))
        .corner_radius(radius)
        .background(background)
        .center()
        .child(
            label()
                .text(initial.to_string())
                .font_size(font_size)
                .font_weight(FontWeight::MEDIUM)
                .color(foreground),
        )
        .into()
}

/// Circular avatar: the image of `source` once loaded, otherwise (and when
/// `source` is `None`) a solid-color disc with the [`initial`] of `name`.
///
/// Images are fetched and decoded into the shared asset cache keyed by the
/// source, so every avatar of the same room or user shares one entry and
/// re-renders work inside `VirtualScrollView`.
#[derive(Clone, PartialEq)]
pub struct Avatar {
    pub size: f32,
    pub source: Option<AvatarSource>,
    /// Display name (or ID) the initial comes from.
    pub name: String,
    pub color: (u8, u8, u8),
}

impl Component for Avatar {
    fn render(&self) -> impl IntoElement {
        let size = self.size;
        let radius = size / 2.;
        let initial = initial(&self.name);
        let color = self.color;
        let dark = use_app_colors().on_surface.0 > 128;

        // Cache key only: the bytes are fetched in the effect below and
        // written straight into the asset cache.
        let cache_key = match &self.source {
            Some(source) => source.cache_key(),
            None => "avatar:none".to_string(),
        };
        let image_source: ImageSource = (cache_key, Bytes::new()).into();
        let fetch_source = self.source.clone();

        let asset_config = AssetConfiguration::new(&image_source, AssetAge::default());
        use_asset(&asset_config);
        let mut asset_cacher = use_hook(AssetCacher::get);

        use_side_effect_with_deps(&asset_config, move |asset_config| {
            let Some(source) = fetch_source.clone() else {
                return;
            };
            if !matches!(
                asset_cacher.read_asset(asset_config),
                Some(Asset::Pending) | Some(Asset::Error(_))
            ) {
                return;
            }
            asset_cacher.update_asset(asset_config.clone(), Asset::Loading);
            let asset_config = asset_config.clone();
            // Not tied to this component: the cache entry is always completed,
            // so a remount (e.g. scrolling back) hits it immediately.
            spawn_in_window(async move {
                let fetch = source.clone();
                let bytes =
                    crate::utils::on_tokio(
                        async move { crate::utils::avatars::fetch(&fetch).await },
                    );
                let Some(Some(bytes)) = bytes.await else {
                    asset_cacher.update_asset(asset_config, Asset::Error("no avatar".into()));
                    return;
                };
                let decode: ImageSource = (source.cache_key(), Bytes::from(bytes)).into();
                match decode.load(None, SamplingMode::default()).await {
                    Ok((image, bytes)) => {
                        let holder = ImageHandle::new(image, bytes);
                        asset_cacher.update_asset(asset_config, Asset::Cached(Rc::new(holder)));
                    }
                    Err(_) => {
                        tracing::debug!(target: "piaf::avatar", ?source, "decode failed");
                        asset_cacher
                            .update_asset(asset_config, Asset::Error("decode failed".into()));
                    }
                }
            });
        });

        let asset = asset_cacher
            .read_asset(&asset_config)
            .expect("Asset should exist by now");
        // Fades in over the initial when the image arrives while shown; an
        // image already cached at mount shows at once (no flash on scroll).
        let opacity = use_fade(matches!(asset, Asset::Cached(_)), 150);

        let Asset::Cached(holder) = asset else {
            return initial_disc(size, &initial, color, dark);
        };
        let holder = holder.downcast_ref::<ImageHandle>().unwrap().clone();
        // Cover the disc: non-square pictures are cropped around their center.
        let image = freya_core::elements::image::image(holder)
            .width(Size::px(size))
            .height(Size::px(size))
            .aspect_ratio(AspectRatio::Max)
            .image_cover(ImageCover::Center)
            .corner_radius(radius);
        if opacity >= 1. {
            return image.into_element();
        }
        rect()
            .width(Size::px(size))
            .height(Size::px(size))
            .child(initial_disc(size, &initial, color, dark))
            .child(
                rect()
                    .position(Position::new_absolute().top(0.).left(0.))
                    .opacity(opacity)
                    .child(image),
            )
            .into_element()
    }
}

/// Two circular avatars arranged diagonally (Messenger-style) for group rooms
/// without a room-level avatar.
#[derive(Clone, PartialEq)]
pub struct StackedAvatar {
    pub size: f32,
    pub name1: String,
    pub color1: (u8, u8, u8),
    /// Image of the first circle; its initial if `None`.
    pub source1: Option<AvatarSource>,
    pub name2: String,
    pub color2: (u8, u8, u8),
    pub source2: Option<AvatarSource>,
    /// Background color of the parent surface, used to draw a separator ring
    /// between the two overlapping circles so they don't bleed into each other.
    pub border_color: (u8, u8, u8),
}

impl Component for StackedAvatar {
    fn render(&self) -> impl IntoElement {
        let size = self.size;
        // Each circle is ~71% of container; offset is the remaining ~29%.
        let circle_size = (size * 0.71).floor();
        let offset = size - circle_size;
        // A 2-px ring drawn as a slightly larger circle in the surface color
        // creates a visual gap between the two overlapping avatar circles.
        let border = 2.0_f32;
        let ring_size = circle_size + border * 2.;
        let ring_r = ring_size / 2.;

        let mk_circle =
            |color: (u8, u8, u8), name: String, source: Option<AvatarSource>, ring: bool| {
                let inner: Element = Avatar {
                    size: circle_size,
                    source,
                    name,
                    color,
                }
                .into();
                if ring {
                    rect()
                        .width(Size::px(ring_size))
                        .height(Size::px(ring_size))
                        .corner_radius(ring_r)
                        .background(self.border_color)
                        .center()
                        .child(inner)
                        .into_element()
                } else {
                    inner
                }
            };

        rect()
            .vertical()
            .width(Size::px(size))
            .height(Size::px(size))
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .height(Size::px(offset))
                    .child(mk_circle(
                        self.color1,
                        self.name1.clone(),
                        self.source1.clone(),
                        false,
                    )),
            )
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .height(Size::px(ring_size))
                    .content(Content::Flex)
                    .layer(1)
                    .child(rect().width(Size::flex(1.0)).height(Size::px(1.)))
                    .child(mk_circle(
                        self.color2,
                        self.name2.clone(),
                        self.source2.clone(),
                        true,
                    )),
            )
    }
}

#[cfg(test)]
mod tests {
    use super::initial;

    #[test]
    fn initial_skips_id_sigils_and_uppercases() {
        assert_eq!(initial("alice"), "A");
        assert_eq!(initial("@bob:example.org"), "B");
        assert_eq!(initial("#room:example.org"), "R");
        assert_eq!(initial("élise"), "É");
        assert_eq!(initial(""), "?");
        assert_eq!(initial("@@"), "?");
    }
}
