use std::{cell::RefCell, rc::Rc};

use bytes::Bytes;
use freya::prelude::*;
use freya_components::{
    cache::{Asset, AssetAge, AssetCacher, AssetConfiguration, use_asset},
    image_viewer::ImageSource,
};
use freya_core::elements::image::ImageHolder;

use crate::utils::queries::fetch_avatar_for_key;

/// Pick a deterministic color from a fixed palette based on a string (e.g. user ID).
pub fn user_color(id: &str) -> (u8, u8, u8) {
    const PALETTE: &[(u8, u8, u8)] = &[
        (103, 80, 164),
        (0, 105, 92),
        (183, 28, 28),
        (230, 81, 0),
        (1, 87, 155),
        (27, 94, 32),
        (136, 14, 79),
        (62, 39, 35),
    ];
    let hash = id
        .bytes()
        .fold(0usize, |acc, b| acc.wrapping_add(b as usize));
    PALETTE[hash % PALETTE.len()]
}

fn initial_disc(size: f32, initial: &str, color: (u8, u8, u8)) -> Element {
    let radius = size / 2.;
    let font_size = (size * 0.41).floor();
    rect()
        .width(Size::px(size))
        .height(Size::px(size))
        .corner_radius(radius)
        .background(color)
        .center()
        .child(
            label()
                .text(initial.to_string())
                .font_size(font_size)
                .color((255u8, 255u8, 255u8)),
        )
        .into()
}

/// Circular avatar: shows an image when bytes are available, otherwise a
/// solid-color disc with an initial letter.
///
/// Pass `fetch_key` (a room_id string) to have the avatar fetch and cache its
/// own image from the Matrix server using the same asset-caching mechanism as
/// `ImageViewer`, so re-renders work correctly inside `VirtualScrollView`.
#[derive(Clone, PartialEq)]
pub struct Avatar {
    pub size: f32,
    pub bytes: Option<Vec<u8>>,
    /// Room ID to fetch the avatar from. Used when `bytes` is `None`.
    pub fetch_key: Option<String>,
    pub initial: String,
    pub color: (u8, u8, u8),
    /// Stable cache key for the asset decoder (e.g. room_id or "home-avatar").
    pub image_key: String,
}

impl Component for Avatar {
    fn render(&self) -> impl IntoElement {
        let size = self.size;
        let radius = size / 2.;
        let initial = self.initial.clone();
        let color = self.color;

        // Choose the ImageSource used as the asset-cache key.
        //
        // • bytes provided  → Bytes source (decoded normally)
        // • fetch_key only  → (fetch_key, Bytes::new()) sentinel; actual bytes are
        //                     fetched inside use_side_effect_with_deps below and
        //                     written directly into the asset cache
        // • neither         → unique-per-instance sentinel; never decoded
        let source: ImageSource = match &self.bytes {
            Some(b) => (self.image_key.clone(), Bytes::from(b.clone())).into(),
            None => match &self.fetch_key {
                Some(k) => (k.clone(), Bytes::new()).into(),
                None => (format!("__none__{}", self.image_key), Bytes::new()).into(),
            },
        };

        let has_bytes = self.bytes.is_some();
        let fetch_key = self.fetch_key.clone();

        let asset_config = AssetConfiguration::new(&source, AssetAge::default());
        let asset = use_asset(&asset_config);
        let mut asset_cacher = use_hook(AssetCacher::get);
        let mut tasks: State<Vec<TaskHandle>> = use_state(Vec::new);

        use_side_effect_with_deps(
            &(source.clone(), asset_config.clone()),
            move |(source, asset_config)| {
                if !matches!(
                    asset_cacher.read_asset(asset_config),
                    Some(Asset::Pending) | Some(Asset::Error(_))
                ) {
                    return;
                }

                // Cancel any previous in-flight decode task.
                for t in tasks.write().drain(..) {
                    t.cancel();
                }

                asset_cacher.update_asset(asset_config.clone(), Asset::Loading);

                if let Some(key) = fetch_key.clone() {
                    // Matrix avatar: fetch bytes from the server, then decode.
                    // spawn_forever keeps the task alive even if the component
                    // scrolls out of view, so the AssetCacher entry is always
                    // updated and the next remount hits the cache immediately.
                    let asset_config = asset_config.clone();
                    spawn_forever(async move {
                        let (tx, rx) =
                            futures::channel::oneshot::channel::<Result<Vec<u8>, ()>>();
                        let key2 = key.clone();
                        tokio::spawn(async move {
                            let _ = tx.send(fetch_avatar_for_key(&key2).await);
                        });

                        let Ok(Ok(bytes_vec)) = rx.await else {
                            asset_cacher
                                .update_asset(asset_config, Asset::Error("fetch failed".into()));
                            return;
                        };

                        // Decode via the ImageSource path (handles blocking decode correctly).
                        let decode_source: ImageSource =
                            (key, Bytes::from(bytes_vec)).into();
                        match decode_source.bytes().await {
                            Ok((sk_image, bytes)) => {
                                let holder = ImageHolder {
                                    image: Rc::new(RefCell::new(sk_image)),
                                    bytes,
                                };
                                asset_cacher
                                    .update_asset(asset_config, Asset::Cached(Rc::new(holder)));
                            }
                            Err(_) => {
                                asset_cacher.update_asset(
                                    asset_config,
                                    Asset::Error("decode failed".into()),
                                );
                            }
                        }
                    });
                } else if has_bytes {
                    // Pre-fetched bytes: decode normally.
                    let source = source.clone();
                    let asset_config = asset_config.clone();
                    let task = spawn(async move {
                        match source.bytes().await {
                            Ok((sk_image, bytes)) => {
                                let holder = ImageHolder {
                                    image: Rc::new(RefCell::new(sk_image)),
                                    bytes,
                                };
                                asset_cacher
                                    .update_asset(asset_config, Asset::Cached(Rc::new(holder)));
                            }
                            Err(_) => {
                                asset_cacher.update_asset(
                                    asset_config,
                                    Asset::Error("decode failed".into()),
                                );
                            }
                        }
                    });
                    tasks.write().push(task);
                }
                // No bytes and no fetch_key → stay as placeholder.
            },
        );

        match asset {
            Asset::Cached(holder) => {
                let holder = holder
                    .downcast_ref::<ImageHolder>()
                    .unwrap()
                    .clone();
                freya_core::elements::image::image(holder)
                    .width(Size::px(size))
                    .height(Size::px(size))
                    .corner_radius(radius)
                    .into_element()
            }
            _ => initial_disc(size, &initial, color),
        }
    }
}

/// Two circular avatars arranged diagonally (Messenger-style) for group rooms
/// without a room-level avatar.
#[derive(Clone, PartialEq)]
pub struct StackedAvatar {
    pub size: f32,
    pub initial1: String,
    pub color1: (u8, u8, u8),
    pub initial2: String,
    pub color2: (u8, u8, u8),
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
        let font_size = (circle_size * 0.38).floor();
        let r = circle_size / 2.;
        // A 2-px ring drawn as a slightly larger circle in the surface color
        // creates a visual gap between the two overlapping avatar circles.
        let border = 2.0_f32;
        let ring_size = circle_size + border * 2.;
        let ring_r = ring_size / 2.;

        let mk_circle = |color: (u8, u8, u8), initial: String, ring: bool| {
            let inner = rect()
                .width(Size::px(circle_size))
                .height(Size::px(circle_size))
                .corner_radius(r)
                .background(color)
                .center()
                .child(
                    label()
                        .text(initial)
                        .font_size(font_size)
                        .color((255u8, 255u8, 255u8)),
                );
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
                inner.into_element()
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
                    .child(mk_circle(self.color1, self.initial1.clone(), false)),
            )
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .height(Size::px(ring_size))
                    .content(Content::Flex)
                    .child(rect().width(Size::flex(1.0)).height(Size::px(1.)))
                    .child(mk_circle(self.color2, self.initial2.clone(), true)),
            )
    }
}
