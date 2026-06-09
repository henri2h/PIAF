use std::rc::Rc;

use bytes::Bytes;
use freya::prelude::*;
use freya_query::prelude::QueryCapability;
use matrix_sdk::ruma::events::room::MediaSource;

use crate::utils::{
    const_values::STATUS_BAR_INSET,
    matrix::save_media_to_downloads,
    queries::{FetchMediaContent, media_source_key},
};

use super::MediaThumbnail;

#[derive(Clone)]
pub enum ViewerSource {
    Bytes(Vec<u8>),
    Remote(MediaSource),
}

impl PartialEq for ViewerSource {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::Bytes(a), Self::Bytes(b)) => a == b,
            (Self::Remote(a), Self::Remote(b)) => media_source_key(a) == media_source_key(b),
            _ => false,
        }
    }
}

#[derive(Clone, PartialEq)]
pub struct MediaViewerItem {
    pub key: String,
    pub source: ViewerSource,
    /// (sender_name, timestamp) shown in the viewer header.
    pub info: Option<(String, String)>,
    pub caption: Option<String>,
    pub blurhash: Option<String>,
    pub thumbnail_source: Option<ViewerSource>,
}

// ── Public: full-screen viewer with prev/next navigation ──────────────────────

const PREFETCH_AHEAD: usize = 2;

pub struct MediaViewer {
    pub items: Vec<MediaViewerItem>,
    pub selected_key: State<Option<String>>,
    pub on_load_more: Option<Rc<dyn Fn()>>,
}

impl PartialEq for MediaViewer {
    fn eq(&self, other: &Self) -> bool {
        self.items == other.items && self.selected_key == other.selected_key
    }
}

impl Component for MediaViewer {
    fn render(&self) -> impl IntoElement {
        let items = self.items.clone();
        let mut selected_key = self.selected_key;
        let on_load_more = self.on_load_more.clone();

        // ── current_bytes: full-res image bytes for the selected item ────────
        //
        // WHY two states instead of just clearing in the effect:
        // Effects fire *after* the render that detects the dep change. Clearing
        // bytes there means the current render still draws the old image (one
        // stale frame). Instead we clear inline during the render, using
        // `last_fetched_key` to detect when the selection changed. The write
        // happens before `dl_bytes` is read further down, so the old bytes are
        // invisible from the very first render after navigation.
        let mut current_bytes: State<Option<Vec<u8>>> = use_state(|| None);
        let mut last_fetched_key: State<Option<String>> = use_state(|| None);

        let current_key = selected_key.read().clone();    // Ref dropped at ;
        let prev_key = last_fetched_key.read().clone();   // Ref dropped at ;
        if current_key != prev_key {
            *current_bytes.write() = None;
            *last_fetched_key.write() = current_key.clone();
        }

        // Start the fetch whenever the selection changes.
        // The in-flight stale guard prevents a slow earlier fetch from
        // overwriting bytes that a faster later fetch already wrote.
        let key_dep = current_key;
        let items_for_fetch = items.clone();
        use_side_effect_with_deps(&key_dep, move |key| {
            let Some(k) = key.as_deref() else { return };
            if let Some(item) = items_for_fetch.iter().find(|i| i.key == k) {
                match &item.source {
                    ViewerSource::Bytes(b) => {
                        *current_bytes.write() = Some(b.clone());
                    }
                    ViewerSource::Remote(s) => {
                        let fetch_key = media_source_key(s);
                        let expected_key = item.key.clone();
                        spawn(async move {
                            if let Ok(b) = FetchMediaContent.run(&fetch_key).await {
                                // Extract to bool before write() so the Ref is dropped.
                                let still_current = selected_key.read().as_deref()
                                    == Some(expected_key.as_str());
                                if still_current {
                                    *current_bytes.write() = Some(b);
                                }
                            }
                        });
                    }
                }
            }
        });

        // Preemptively load more when near the beginning of the loaded list.
        // Dep on selected key so this fires only on navigation, not on every render.
        let items_for_prefetch = items.clone();
        let on_load_more_prefetch = on_load_more.clone();
        let prefetch_key_dep = selected_key.read().clone();
        use_side_effect_with_deps(&prefetch_key_dep, move |key| {
            if let Some(k) = key.as_deref() {
                if let Some(i) = items_for_prefetch.iter().position(|it| it.key == k) {
                    if i < PREFETCH_AHEAD {
                        if let Some(f) = &on_load_more_prefetch {
                            f();
                        }
                    }
                }
            }
        });

        // "Want next" state: user pressed right at the boundary, waiting for new items.
        // known_count is initialised to the current item count so we only react to growth.
        let mut want_next: State<bool> = use_state(|| false);
        let items_len = items.len();
        let mut known_count: State<usize> = use_state(move || items_len);

        let prev_count = *known_count.read();
        let cur_count = items.len();
        if cur_count > prev_count {
            let items_snap = items.clone();
            let want = *want_next.read();
            spawn(async move {
                *known_count.write() = cur_count;
                if want {
                    // Navigate to the first newly-loaded item.
                    if let Some(item) = items_snap.get(prev_count) {
                        *selected_key.write() = Some(item.key.clone());
                    }
                    *want_next.write() = false;
                }
            });
        }

        let key_str = selected_key.read().clone();
        let idx = key_str
            .as_deref()
            .and_then(|k| items.iter().position(|i| i.key == k));

        let Some(idx) = idx else {
            return rect().into_element();
        };

        let total = items.len();
        let item = &items[idx];
        let has_prev = idx > 0;
        let has_next = idx + 1 < total;
        let can_load_more = on_load_more.is_some();
        let is_waiting_next = *want_next.read();

        // ── Keyboard handler ─────────────────────────────────────────────────
        let items_kd = items.clone();
        let on_load_more_kd = on_load_more.clone();
        let on_key_down = move |e: Event<KeyboardEventData>| match &e.key {
            Key::Named(NamedKey::ArrowLeft) | Key::Named(NamedKey::ArrowUp) => {
                *want_next.write() = false;
                if has_prev {
                    *selected_key.write() = Some(items_kd[idx - 1].key.clone());
                } else if let Some(f) = &on_load_more_kd {
                    f();
                }
            }
            Key::Named(NamedKey::ArrowRight) | Key::Named(NamedKey::ArrowDown) => {
                if has_next {
                    *want_next.write() = false;
                    *selected_key.write() = Some(items_kd[idx + 1].key.clone());
                } else if let Some(f) = &on_load_more_kd {
                    f();
                    *want_next.write() = true;
                }
            }
            Key::Named(NamedKey::Escape) => {
                *selected_key.write() = None;
                *want_next.write() = false;
            }
            _ => {
                let _ = &items_kd;
            }
        };

        // ── Header center ────────────────────────────────────────────────────
        let header_center = if let Some((sender, ts)) = &item.info {
            rect()
                .vertical()
                .spacing(2.)
                .width(Size::flex(1.0))
                .child(
                    label()
                        .text(sender.clone())
                        .font_weight(FontWeight::MEDIUM)
                        .font_size(14.)
                        .color((255u8, 255u8, 255u8)),
                )
                .child(
                    label()
                        .text(ts.clone())
                        .font_size(12.)
                        .color((150u8, 150u8, 150u8)),
                )
                .into_element()
        } else {
            label()
                .text(if total > 1 {
                    format!("{} / {}", idx + 1, total)
                } else {
                    "Image".to_string()
                })
                .font_size(14.)
                .color((255u8, 255u8, 255u8))
                .width(Size::flex(1.0))
                .into_element()
        };

        // ── Side nav arrows ──────────────────────────────────────────────────
        let items_prev = items.clone();
        let items_next = items.clone();
        let on_load_more_next = on_load_more.clone();

        let prev_arrow = if has_prev {
            Button::new()
                .on_press(move |_| {
                    *want_next.write() = false;
                    *selected_key.write() = Some(items_prev[idx - 1].key.clone());
                })
                .child(
                    svg(freya_icons::lucide::chevron_left())
                        .width(Size::px(28.))
                        .height(Size::px(28.))
                        .color((255u8, 255u8, 255u8)),
                )
                .into_element()
        } else if can_load_more {
            Button::new()
                .on_press(move |_| {
                    if let Some(f) = &on_load_more.clone() {
                        f();
                    }
                })
                .child(
                    svg(freya_icons::lucide::chevron_left())
                        .width(Size::px(28.))
                        .height(Size::px(28.))
                        .color((80u8, 80u8, 80u8)),
                )
                .into_element()
        } else {
            rect().width(Size::px(48.)).into_element()
        };

        let next_arrow = if has_next {
            Button::new()
                .on_press(move |_| {
                    *want_next.write() = false;
                    *selected_key.write() = Some(items_next[idx + 1].key.clone());
                })
                .child(
                    svg(freya_icons::lucide::chevron_right())
                        .width(Size::px(28.))
                        .height(Size::px(28.))
                        .color((255u8, 255u8, 255u8)),
                )
                .into_element()
        } else if can_load_more {
            Button::new()
                .on_press(move |_| {
                    if let Some(f) = &on_load_more_next {
                        f();
                        *want_next.write() = true;
                    }
                })
                .child(
                    svg(freya_icons::lucide::chevron_right())
                        .width(Size::px(28.))
                        .height(Size::px(28.))
                        .color((80u8, 80u8, 80u8)),
                )
                .into_element()
        } else {
            rect().width(Size::px(48.)).into_element()
        };

        // ── Image area ───────────────────────────────────────────────────────
        let dl_bytes = current_bytes.read().clone();
        let dl_available = dl_bytes.is_some();
        let caption = item.caption.clone();

        let image_el = if is_waiting_next {
            rect()
                .width(Size::fill())
                .height(Size::fill())
                .center()
                .child(CircularLoader::new())
                .into_element()
        } else if let Some(b) = dl_bytes.clone() {
            ImageViewer::new((item.key.clone(), Bytes::from(b)))
                .width(Size::fill())
                .height(Size::fill())
                .aspect_ratio(AspectRatio::Min)
                .image_cover(ImageCover::Center)
                .into_element()
        } else {
            // Keyed rect ensures MediaThumbnail remounts on every navigation.
            rect()
                .key(format!("{}-ph", item.key))
                .width(Size::fill())
                .height(Size::fill())
                .child(MediaThumbnail {
                    item_key: item.key.clone(),
                    blurhash: item.blurhash.clone(),
                    thumbnail_source: item.thumbnail_source.clone(),
                    fallback_source: None,
                    thumb_size: None,
                })
                .into_element()
        };

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .on_global_key_down(on_key_down)
            // ── Header bar ───────────────────────────────────────────────────
            .child(
                rect()
                    .vertical()
                    .width(Size::fill())
                    .background((20u8, 20u8, 20u8))
                    .child(
                        rect()
                            .width(Size::fill())
                            .height(Size::px(STATUS_BAR_INSET)),
                    )
                    .child(
                        rect()
                            .horizontal()
                            .width(Size::fill())
                            .height(Size::px(56.))
                            .content(Content::Flex)
                            .padding(Gaps::new(0., 8., 0., 8.))
                            .cross_align(Alignment::Center)
                            .spacing(8.)
                            .child(
                                Button::new()
                                    .on_press(move |_| {
                                        *selected_key.write() = None;
                                        *want_next.write() = false;
                                    })
                                    .child(
                                        svg(freya_icons::lucide::arrow_left())
                                            .width(Size::px(20.))
                                            .height(Size::px(20.))
                                            .color((255u8, 255u8, 255u8)),
                                    ),
                            )
                            .child(header_center)
                            .child(
                                Button::new()
                                    .on_press(move |_| {
                                        if let Some(b) = dl_bytes.clone() {
                                            tokio::task::spawn(async move {
                                                save_media_to_downloads(&b).await;
                                            });
                                        }
                                    })
                                    .child(
                                        svg(freya_icons::lucide::download())
                                            .width(Size::px(20.))
                                            .height(Size::px(20.))
                                            .color(if dl_available {
                                                (255u8, 255u8, 255u8)
                                            } else {
                                                (80u8, 80u8, 80u8)
                                            }),
                                    ),
                            ),
                    ),
            )
            // ── Image area with side arrows ───────────────────────────────────
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .content(Content::Flex)
                    .background((10u8, 10u8, 10u8))
                    .cross_align(Alignment::Center)
                    .child(prev_arrow)
                    .child(
                        rect()
                            .vertical()
                            .width(Size::flex(1.0))
                            .height(Size::fill())
                            .content(Content::Flex)
                            .child(
                                rect()
                                    .width(Size::fill())
                                    .height(Size::flex(1.0))
                                    .center()
                                    .child(image_el),
                            )
                            .maybe_child(caption.map(|cap| {
                                rect()
                                    .width(Size::fill())
                                    .padding(Gaps::new(8., 16., 12., 16.))
                                    .child(
                                        label()
                                            .text(cap)
                                            .font_size(13.)
                                            .color((200u8, 200u8, 200u8)),
                                    )
                            })),
                    )
                    .child(next_arrow),
            )
            .into()
    }
}
