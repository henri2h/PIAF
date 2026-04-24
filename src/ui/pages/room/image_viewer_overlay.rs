use std::sync::Arc;

use freya::prelude::*;

use crate::ui::components::{TopAppBar, TopAppBarTitle};

pub(super) fn image_viewer_overlay(
    key: String,
    bytes: Vec<u8>,
    image_viewer: State<Option<(String, Vec<u8>)>>,
) -> Element {
    use bytes::Bytes as FBytes;
    rect()
        .expanded()
        .background((10, 10, 10))
        .vertical()
        .content(Content::Flex)
        .child(TopAppBar {
            title: TopAppBarTitle::Text("Image viewer".to_string()),
            on_back: Some(Arc::new(move || {
                let mut iv = image_viewer;
                *iv.write() = None;
            })),
            actions: vec![],
        })
        .child(
            rect()
                .width(Size::fill())
                .height(Size::flex(1.0))
                .center()
                .child(
                    ImageViewer::new((key, FBytes::from(bytes)))
                        .width(Size::fill())
                        .height(Size::fill()),
                ),
        )
        .into()
}
