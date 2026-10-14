use std::sync::Arc;

use freya::prelude::*;

use crate::ui::components::{MediaThumbnail, ViewerSource, use_fade};
use crate::utils::timeline_media::{MediaContent, MediaEntry};

/// Grid cell: image thumbnail; on hover, a scrim with sender and time.
pub(super) struct MediaThumb {
    pub entry: Arc<MediaEntry>,
    pub cell_size: f32,
    pub selected_key: State<Option<String>>,
}

/// By identity: entries are immutable once extracted.
impl PartialEq for MediaThumb {
    fn eq(&self, other: &Self) -> bool {
        Arc::ptr_eq(&self.entry, &other.entry)
            && self.cell_size == other.cell_size
            && self.selected_key == other.selected_key
    }
}

impl Component for MediaThumb {
    fn render(&self) -> impl IntoElement {
        let mut selected_key = self.selected_key;
        let mut hovered = use_state(|| false);
        let scrim = use_fade(*hovered.read(), 120);
        let MediaContent::Image {
            source,
            blurhash,
            thumbnail_source,
            ..
        } = &self.entry.content
        else {
            return rect();
        };
        let key = self.entry.key.clone();

        rect()
            .width(Size::fill())
            .height(Size::px(self.cell_size))
            .overflow(Overflow::Clip)
            .on_pointer_enter(move |_| hovered.set(true))
            .on_pointer_leave(move |_| hovered.set(false))
            .on_press(move |_| selected_key.set(Some(key.clone())))
            .child(MediaThumbnail {
                item_key: self.entry.key.clone(),
                blurhash: blurhash.clone(),
                thumbnail_source: thumbnail_source.clone().map(ViewerSource::Remote),
                fallback_source: Some(ViewerSource::Remote(source.clone())),
                thumb_size: Some((240, 240)),
            })
            .maybe_child((scrim > 0.).then(|| {
                rect()
                    .position(Position::new_absolute().top(0.).left(0.))
                    .layer(1)
                    .width(Size::fill())
                    .height(Size::fill())
                    .main_align(Alignment::End)
                    .padding(Gaps::new_all(6.))
                    .opacity(scrim)
                    .background((0u8, 0u8, 0u8, 110u8))
                    .interactive(false)
                    .child(
                        label()
                            .text(self.entry.sender_name.clone())
                            .font_size(11.)
                            .font_weight(FontWeight::MEDIUM)
                            .color((255u8, 255u8, 255u8))
                            .max_lines(1),
                    )
                    .child(
                        label()
                            .text(self.entry.timestamp.clone())
                            .font_size(10.)
                            .color((220u8, 220u8, 220u8)),
                    )
            }))
    }
}
