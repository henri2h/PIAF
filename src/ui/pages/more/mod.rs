use freya::prelude::*;

use crate::Route;
use crate::app::navigation::push;
use crate::ui::components::{M3ListItem, TopAppBar, TopAppBarTitle};
use crate::utils::use_app_colors;

/// Android "More" tab: the places that are not the inbox.
#[derive(PartialEq)]
pub struct MorePage;

impl Component for MorePage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let row = |icon: bytes::Bytes, title: &str, subtitle: &str, route: Route| M3ListItem {
            icon,
            item_label: title.to_string(),
            sublabel: Some(subtitle.to_string()),
            icon_color: c.on_surface_variant,
            destructive: false,
            on_press: EventHandler::new(move |_| push(route.clone())),
        };

        rect()
            .vertical()
            .expanded()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("More".to_string()),
                on_back: None,
                actions: vec![],
            })
            .child(
                ScrollView::new()
                    .width(Size::fill())
                    .height(Size::flex(1.))
                    .child(
                        rect()
                            .vertical()
                            .width(Size::fill())
                            .padding(Gaps::new(8., 0., 8., 0.))
                            .child(row(
                                freya_icons::lucide::heart(),
                                "Reactions",
                                "Reactions to your messages",
                                Route::ReactionsPage,
                            ))
                            .child(row(
                                freya_icons::lucide::bookmark(),
                                "Bookmarks",
                                "Messages you saved",
                                Route::BookmarksPage,
                            ))
                            .child(row(
                                freya_icons::lucide::user_check(),
                                "Recontact",
                                "Rooms to get back to",
                                Route::RecontactPage,
                            ))
                            .child(row(
                                freya_icons::lucide::archive(),
                                "Archived",
                                "Rooms you are done with",
                                Route::ArchivedPage,
                            )),
                    ),
            )
    }
}
