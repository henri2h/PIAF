use bytes::Bytes;
use freya::prelude::*;

use freya_query::prelude::QueryCapability;

use crate::utils::queries::{FetchMediaContent, media_source_key};

use super::MediaSource;

#[derive(Clone)]
pub(super) struct ViewerImage {
    pub item_key: String,
    pub source: MediaSource,
}

impl PartialEq for ViewerImage {
    fn eq(&self, other: &Self) -> bool {
        self.item_key == other.item_key
    }
}

impl Component for ViewerImage {
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

        let key = self.item_key.clone();

        match bytes_data.read().clone() {
            Some(b) => ImageViewer::new((key, Bytes::from(b)))
                .width(Size::fill())
                .height(Size::fill())
                .into_element(),
            None => rect()
                .width(Size::fill())
                .height(Size::fill())
                .background((10u8, 10u8, 10u8))
                .center()
                .child(CircularLoader::new())
                .into_element(),
        }
    }
}
