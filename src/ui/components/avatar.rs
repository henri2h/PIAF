use bytes::Bytes;
use freya::prelude::*;
use freya_components::{
    cache::{Asset, AssetAge, AssetCacher, AssetConfiguration, use_asset},
    image_viewer::ImageSource,
};

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
/// Uses a custom asset loader that falls back to the initial-letter placeholder
/// while the image is loading or if decoding fails, instead of showing a spinner.
#[derive(Clone, PartialEq)]
pub struct Avatar {
    pub size: f32,
    pub bytes: Option<Vec<u8>>,
    pub initial: String,
    pub color: (u8, u8, u8),
    /// Cache key; must be unique per image (e.g. room_id or user_id).
    pub image_key: String,
}

impl Component for Avatar {
    fn render(&self) -> impl IntoElement {
        let size = self.size;
        let radius = size / 2.;
        let initial = self.initial.clone();
        let color = self.color;

        // Build a source from bytes if present; use an empty sentinel when there are none
        // so the hooks below are always called at the same positions (hooks rule).
        let source: ImageSource = match &self.bytes {
            Some(b) => (self.image_key.clone(), Bytes::from(b.clone())).into(),
            None => ("__avatar_none__".to_string(), Bytes::new()).into(),
        };
        let has_bytes = self.bytes.is_some();

        let asset_config = AssetConfiguration::new(&source, AssetAge::default());
        let asset = use_asset(&asset_config);
        let mut asset_cacher = use_hook(AssetCacher::get);
        let mut tasks: State<Vec<TaskHandle>> = use_state(Vec::new);

        use_side_effect_with_deps(
            &(source.clone(), asset_config.clone()),
            move |(source, asset_config)| {
                // No bytes → nothing to load; placeholder is shown directly.
                if !has_bytes {
                    return;
                }
                for t in tasks.write().drain(..) {
                    t.cancel();
                }
                if matches!(
                    asset_cacher.read_asset(asset_config),
                    Some(Asset::Pending) | Some(Asset::Error(_))
                ) {
                    asset_cacher.update_asset(asset_config.clone(), Asset::Loading);
                    let asset_config = asset_config.clone();
                    let source = source.clone();
                    let task = spawn(async move {
                        match source.bytes().await {
                            Ok((sk_image, bytes)) => {
                                use std::{cell::RefCell, rc::Rc};
                                let holder = freya_core::elements::image::ImageHolder {
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
            },
        );

        if !has_bytes {
            return initial_disc(size, &initial, color);
        }

        match asset {
            Asset::Cached(holder) => {
                let holder = holder
                    .downcast_ref::<freya_core::elements::image::ImageHolder>()
                    .unwrap()
                    .clone();
                freya_core::elements::image::image(holder)
                    .width(Size::px(size))
                    .height(Size::px(size))
                    .corner_radius(radius)
                    .into_element()
            }
            Asset::Pending | Asset::Loading | Asset::Error(_) => {
                initial_disc(size, &initial, color)
            }
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
                // Wrap in a slightly larger circle that acts as the border ring.
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
            // Top strip: circle1 left-aligned, overflows downward.
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .height(Size::px(offset))
                    .child(mk_circle(self.color1, self.initial1.clone(), false)),
            )
            // Bottom strip: circle2 right-aligned with a border ring so it
            // visually separates from the overlapping circle1.
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
