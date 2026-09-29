use freya::prelude::*;
use matrix_sdk::ruma::events::room::MediaSource;

use crate::ui::components::{MediaThumbnail, ViewerSource};

#[derive(Clone)]
pub(super) struct MediaThumb {
    pub item_key: String,
    pub source: MediaSource,
    pub blurhash: Option<String>,
    pub thumbnail_source: Option<MediaSource>,
    pub cell_size: f32,
    pub selected_key: State<Option<String>>,
}

impl PartialEq for MediaThumb {
    fn eq(&self, other: &Self) -> bool {
        self.item_key == other.item_key
            && self.cell_size == other.cell_size
            && self.selected_key == other.selected_key
    }
}

impl Component for MediaThumb {
    fn render(&self) -> impl IntoElement {
        let mut selected_key = self.selected_key;
        let mut hovered: State<bool> = use_state(|| false);
        let cell_size = self.cell_size;
        let item_key = self.item_key.clone();
        let blurhash = self.blurhash.clone();
        let thumbnail_source = self
            .thumbnail_source
            .as_ref()
            .map(|s| ViewerSource::Remote(s.clone()));
        let fallback_source = Some(ViewerSource::Remote(self.source.clone()));
        let is_hovered = *hovered.read();

        rect()
            .key(item_key.clone())
            .width(Size::flex(1.0))
            .height(Size::px(cell_size))
            .overflow(Overflow::Clip)
            .on_pointer_enter(move |_| *hovered.write() = true)
            .on_pointer_leave(move |_| *hovered.write() = false)
            .on_press(move |_| {
                *selected_key.write() = Some(item_key.clone());
            })
            .child(MediaThumbnail {
                item_key: self.item_key.clone(),
                blurhash,
                thumbnail_source,
                fallback_source,
                thumb_size: Some((240, 240)),
            })
            .child(
                rect()
                    .position(Position::new_absolute().top(0.).left(0.))
                    .layer(1)
                    .width(Size::fill())
                    .height(Size::fill())
                    .background((0u8, 0u8, 0u8, 80u8))
                    .opacity(if is_hovered { 1.0 } else { 0.0 }),
            )
    }
}
