use freya::prelude::*;

use super::{MediaItem, viewer_image::ViewerImage};

#[derive(Clone, PartialEq)]
pub(super) struct MediaViewer {
    pub items: Vec<MediaItem>,
    pub idx: usize,
    pub selected_idx: State<Option<usize>>,
}

impl Component for MediaViewer {
    fn render(&self) -> impl IntoElement {
        let items = self.items.clone();
        let idx = self.idx;
        let mut selected_idx = self.selected_idx;

        let item = &items[idx];
        let has_older = idx + 1 < items.len();
        let has_newer = idx > 0;

        rect()
            .expanded()
            .vertical()
            .on_global_key_down(move |e: Event<KeyboardEventData>| match e.key {
                Key::Named(NamedKey::ArrowLeft) if has_older => {
                    *selected_idx.write() = Some(idx + 1);
                }
                Key::Named(NamedKey::ArrowRight) if has_newer => {
                    *selected_idx.write() = Some(idx - 1);
                }
                Key::Named(NamedKey::Escape) => {
                    *selected_idx.write() = None;
                }
                _ => {}
            })
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
                            .on_press(move |_| {
                                *selected_idx.write() = None;
                            })
                            .child(
                                svg(freya_icons::lucide::arrow_left())
                                    .width(Size::px(20.))
                                    .height(Size::px(20.))
                                    .color((255u8, 255u8, 255u8)),
                            ),
                    )
                    .child(
                        rect()
                            .vertical()
                            .spacing(2.)
                            .width(Size::flex(1.0))
                            .child(
                                label()
                                    .text(item.sender_name.clone())
                                    .font_weight(FontWeight::MEDIUM)
                                    .font_size(14.)
                                    .color((255u8, 255u8, 255u8)),
                            )
                            .child(
                                label()
                                    .text(item.timestamp.clone())
                                    .font_size(12.)
                                    .color((150u8, 150u8, 150u8)),
                            ),
                    )
                    .child(if has_older {
                        Button::new()
                            .on_press(move |_| {
                                *selected_idx.write() = Some(idx + 1);
                            })
                            .child(
                                svg(freya_icons::lucide::chevron_left())
                                    .width(Size::px(20.))
                                    .height(Size::px(20.))
                                    .color((255u8, 255u8, 255u8)),
                            )
                            .into_element()
                    } else {
                        rect().width(Size::px(40.)).into_element()
                    })
                    .child(if has_newer {
                        Button::new()
                            .on_press(move |_| {
                                *selected_idx.write() = Some(idx - 1);
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
                    .background((10u8, 10u8, 10u8))
                    .center()
                    .child(ViewerImage {
                        item_key: item.key.clone(),
                        source: item.source.clone(),
                    }),
            )
    }
}
