use bytes::Bytes;
use freya::prelude::*;

use freya_query::prelude::QueryCapability;

use crate::utils::queries::{FetchMediaContent, media_source_key};

use super::MediaSource;

#[derive(Clone)]
pub(super) struct MediaThumb {
    pub item_key: String,
    pub source: MediaSource,
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
        let mut bytes_data: State<Option<Vec<u8>>> = use_state(|| None);

        let source = self.source.clone();
        use_hook(|| {
            let key = media_source_key(&source);
            spawn(async move {
                if let Ok(b) = FetchMediaContent.run(&key).await {
                    *bytes_data.write() = Some(b);
                }
            });
        });

        let mut selected_key = self.selected_key;
        let cell_size = self.cell_size;
        let item_key = self.item_key.clone();

        rect()
            .key(item_key.clone())
            .width(Size::flex(1.0))
            .height(Size::px(cell_size))
            .overflow(Overflow::Clip)
            .on_press(move |_| {
                *selected_key.write() = Some(item_key.clone());
            })
            .child(match bytes_data.read().clone() {
                Some(b) => ImageViewer::new((self.item_key.clone(), Bytes::from(b)))
                    .width(Size::fill())
                    .height(Size::fill())
                    .image_cover(ImageCover::Center)
                    .into_element(),
                None => rect()
                    .background((20u8, 20u8, 20u8))
                    .width(Size::fill())
                    .height(Size::fill())
                    .center()
                    .child(CircularLoader::new().size(20.))
                    .into_element(),
            })
    }
}
