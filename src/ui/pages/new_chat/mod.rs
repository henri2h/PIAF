use std::sync::Arc;

use freya::prelude::*;
use freya_router::prelude::RouterContext;

use crate::Route;
use crate::ui::components::{TopAppBar, TopAppBarTitle};
use crate::utils::use_app_colors;

mod dm_tab;
mod room_tab;
mod tab_btn;
use dm_tab::dm_tab;
use room_tab::room_tab;
use tab_btn::tab_btn;

#[derive(PartialEq)]
pub struct NewChat;

impl Component for NewChat {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let tab: State<u8> = use_state(|| 0u8);

        let dm_search: State<String> = use_state(String::new);
        let dm_results: State<Vec<(String, String)>> = use_state(Vec::new);
        let dm_searching: State<bool> = use_state(|| false);
        let dm_status: State<Option<String>> = use_state(|| None);

        let room_name: State<String> = use_state(String::new);
        let room_creating: State<bool> = use_state(|| false);
        let room_status: State<Option<String>> = use_state(|| None);

        let current_tab = *tab.read();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("New Chat".to_string()),
                on_back: Some(Arc::new(|| {
                    let _ = RouterContext::get().push(Route::HomePage);
                })),
                actions: vec![],
            })
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .background(c.surface)
                    .child(tab_btn("Direct Message", 0, current_tab, tab, c))
                    .child(tab_btn("New Room", 1, current_tab, tab, c)),
            )
            .child(if current_tab == 0 {
                dm_tab(dm_search, dm_results, dm_searching, dm_status, c).into_element()
            } else {
                room_tab(room_name, room_creating, room_status, c).into_element()
            })
    }
}
