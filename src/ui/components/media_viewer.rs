use std::rc::Rc;

use bytes::Bytes;
use freya::prelude::*;
use freya_query::prelude::QueryCapability;
use matrix_sdk::ruma::events::room::MediaSource;

use crate::utils::{matrix::save_image_to_downloads, queries::{FetchMediaContent, media_source_key}};

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
}

// ── Internal: renders one image ───────────────────────────────────────────────

#[derive(PartialEq)]
struct ViewerImage {
    item_key: String,
    source: ViewerSource,
}

impl Component for ViewerImage {
    fn render(&self) -> impl IntoElement {
        let mut remote_bytes: State<Option<Vec<u8>>> = use_state(|| None);
        let fetch_source = match &self.source {
            ViewerSource::Remote(s) => Some(s.clone()),
            ViewerSource::Bytes(_) => None,
        };
        let key = self.item_key.clone();

        use_hook(move || {
            if let Some(source) = fetch_source {
                let fetch_key = media_source_key(&source);
                spawn(async move {
                    if let Ok(b) = FetchMediaContent.run(&fetch_key).await {
                        *remote_bytes.write() = Some(b);
                    }
                });
            }
        });

        let display_bytes = match &self.source {
            ViewerSource::Bytes(b) => Some(b.clone()),
            ViewerSource::Remote(_) => remote_bytes.read().clone(),
        };

        match display_bytes {
            Some(b) => ImageViewer::new((key, Bytes::from(b)))
                .width(Size::fill())
                .height(Size::fill())
                .into_element(),
            None => rect()
                .width(Size::fill())
                .height(Size::fill())
                .center()
                .child(CircularLoader::new())
                .into_element(),
        }
    }
}

// ── Public: full-screen viewer with prev/next navigation ──────────────────────

pub struct MediaViewer {
    pub items: Vec<MediaViewerItem>,
    /// The key of the currently selected item.
    pub selected_key: State<Option<String>>,
    /// Called when the user tries to navigate before the first item (load older).
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

        // Track bytes for the current item so the download button can use them.
        let mut current_bytes: State<Option<Vec<u8>>> = use_state(|| None);

        let items_for_effect = items.clone();
        use_side_effect(move || {
            let key = selected_key.read().clone();
            *current_bytes.write() = None;
            if let Some(k) = key {
                if let Some(item) = items_for_effect.iter().find(|i| i.key == k) {
                    match &item.source {
                        ViewerSource::Bytes(b) => {
                            *current_bytes.write() = Some(b.clone());
                        }
                        ViewerSource::Remote(s) => {
                            let fetch_key = media_source_key(s);
                            spawn(async move {
                                if let Ok(b) = FetchMediaContent.run(&fetch_key).await {
                                    *current_bytes.write() = Some(b);
                                }
                            });
                        }
                    }
                }
            }
        });

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

        let items_kd = items.clone();
        let on_load_more_kd: Option<Rc<dyn Fn()>> = on_load_more.clone();
        let on_key_down = move |e: Event<KeyboardEventData>| match &e.key {
            Key::Named(NamedKey::ArrowLeft) | Key::Named(NamedKey::ArrowUp) => {
                if has_prev {
                    *selected_key.write() = Some(items_kd[idx - 1].key.clone());
                } else if let Some(f) = &on_load_more_kd {
                    f();
                }
            }
            Key::Named(NamedKey::ArrowRight) | Key::Named(NamedKey::ArrowDown) if has_next => {
                *selected_key.write() = Some(items_kd[idx + 1].key.clone());
            }
            Key::Named(NamedKey::Escape) => {
                *selected_key.write() = None;
            }
            _ => {
                let _ = &items_kd;
            }
        };

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

        let items_prev = items.clone();
        let items_next = items.clone();
        let on_load_more_btn = on_load_more.clone();
        let dl_bytes = current_bytes.read().clone();
        let dl_available = dl_bytes.is_some();
        let caption = item.caption.clone();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .on_global_key_down(on_key_down)
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .height(Size::px(56.))
                    .background((20u8, 20u8, 20u8))
                    .padding(Gaps::new(0., 8., 0., 8.))
                    .cross_align(Alignment::Center)
                    .spacing(8.)
                    .child(
                        Button::new()
                            .on_press(move |_| *selected_key.write() = None)
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
                                        save_image_to_downloads(&b).await;
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
                    )
                    .child(if has_prev {
                        Button::new()
                            .on_press(move |_| {
                                *selected_key.write() = Some(items_prev[idx - 1].key.clone());
                            })
                            .child(
                                svg(freya_icons::lucide::chevron_left())
                                    .width(Size::px(20.))
                                    .height(Size::px(20.))
                                    .color((255u8, 255u8, 255u8)),
                            )
                            .into_element()
                    } else if can_load_more {
                        Button::new()
                            .on_press(move |_| {
                                if let Some(f) = &on_load_more_btn {
                                    f();
                                }
                            })
                            .child(
                                svg(freya_icons::lucide::chevron_left())
                                    .width(Size::px(20.))
                                    .height(Size::px(20.))
                                    .color((100u8, 100u8, 100u8)),
                            )
                            .into_element()
                    } else {
                        rect().width(Size::px(40.)).into_element()
                    })
                    .child(if has_next {
                        Button::new()
                            .on_press(move |_| {
                                *selected_key.write() = Some(items_next[idx + 1].key.clone());
                            })
                            .child(
                                svg(freya_icons::lucide::chevron_right())
                                    .width(Size::px(20.))
                                    .height(Size::px(20.))
                                    .color((255u8, 255u8, 255u8)),
                            )
                            .into_element()
                    } else {
                        rect().width(Size::px(40.)).into_element()
                    }),
            )
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .vertical()
                    .content(Content::Flex)
                    .background((10u8, 10u8, 10u8))
                    .child(
                        rect()
                            .width(Size::fill())
                            .height(Size::flex(1.0))
                            .center()
                            .child(ViewerImage {
                                item_key: item.key.clone(),
                                source: item.source.clone(),
                            }),
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
            .into()
    }
}
