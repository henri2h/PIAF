use std::sync::Mutex;

use freya::prelude::*;

use crate::app::navigation::go_back_or_home;
use crate::ui::components::{IconButton, empty_state, search_input};
use crate::ui::pages::home::SearchResults;
use crate::utils::insets::status_bar_inset;
use crate::utils::use_app_colors;

/// Query kept across a result's round trip (search → room → back), so the
/// results are still there. Cleared when the room list shows again.
static LAST_QUERY: Mutex<String> = Mutex::new(String::new());

/// Leaves search mode: the next search starts empty.
pub fn clear_last_query() {
    if let Ok(mut query) = LAST_QUERY.lock() {
        query.clear();
    }
}

/// Android search mode: its own page, so entering it is obvious. Field at the
/// top (focused on open), results below, back arrow to leave.
#[derive(PartialEq)]
pub struct SearchPage;

impl Component for SearchPage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let search = use_state(|| LAST_QUERY.lock().map(|q| q.clone()).unwrap_or_default());
        use_side_effect(move || {
            let query = search.read().clone();
            if let Ok(mut last) = LAST_QUERY.lock() {
                *last = query;
            }
        });
        let has_query = !search.read().trim().is_empty();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::px(status_bar_inset())),
            )
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .height(Size::px(64.))
                    .content(Content::Flex)
                    .cross_align(Alignment::Center)
                    .padding(Gaps::new(0., 16., 0., 4.))
                    .spacing(4.)
                    .child(
                        IconButton::new(
                            freya_icons::lucide::arrow_left(),
                            c.on_surface_variant,
                            |_| go_back_or_home(),
                        )
                        .size(48., 22.),
                    )
                    .child(
                        rect().width(Size::flex(1.)).child(
                            search_input(search, "Search conversations, people…", c)
                                .auto_focus(true),
                        ),
                    ),
            )
            .child(if has_query {
                SearchResults { search }.into_element()
            } else {
                empty_state(
                    freya_icons::lucide::search(),
                    "Search",
                    Some("Conversations, people and messages"),
                    c,
                )
                .into_element()
            })
    }
}
