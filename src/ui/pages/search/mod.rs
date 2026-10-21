use std::sync::Mutex;

use freya::prelude::*;

mod empty_search;
mod search_field;

use crate::app::navigation::go_back_or_home;
use crate::ui::components::{Chip, IconButton};
use crate::ui::pages::home::{SearchFilter, SearchResults};
use crate::utils::insets::status_bar_inset;
use crate::utils::{recent_searches, use_app_colors};
use empty_search::EmptySearch;
use search_field::SearchField;

/// Query kept across a result's round trip (search → room → back), so the
/// results are still there. Cleared when the room list shows again.
static LAST_QUERY: Mutex<String> = Mutex::new(String::new());

/// Leaves search mode: the next search starts empty.
pub fn clear_last_query() {
    if let Ok(mut query) = LAST_QUERY.lock() {
        query.clear();
    }
}

/// Android search mode: its own page, so entering it is obvious. The field is
/// the app bar (focused on open, keyboard search key), filter chips below it,
/// then results, or recent chats and searches before typing.
#[derive(PartialEq)]
pub struct SearchPage;

impl Component for SearchPage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let search = use_state(|| LAST_QUERY.lock().map(|q| q.clone()).unwrap_or_default());
        let mut filter = use_state(|| SearchFilter::All);
        // Set when the results scroll: the field hides the keyboard.
        let dismiss = use_state(|| false);
        use_side_effect(move || {
            let query = search.read().clone();
            if let Ok(mut last) = LAST_QUERY.lock() {
                *last = query;
            }
        });
        // Leaving with a query (a result opened, or back): it was a search.
        use_drop(move || recent_searches::add(&search.peek()));
        let has_query = !search.read().trim().is_empty();
        let current = *filter.read();

        let chips = rect()
            .horizontal()
            .width(Size::fill())
            .padding(Gaps::new(8., 16., 8., 16.))
            .spacing(8.)
            .children(SearchFilter::ALL.into_iter().map(|f| {
                Chip::new(f.label(), current == f, move |_| filter.set(f)).into_element()
            }));

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
                    .padding(Gaps::new(0., 8., 0., 4.))
                    .spacing(4.)
                    .child(
                        IconButton::new(
                            freya_icons::lucide::arrow_left(),
                            c.on_surface_variant,
                            |_| go_back_or_home(),
                        )
                        .size(48., 22.),
                    )
                    .child(SearchField {
                        value: search,
                        placeholder: "Search chats, people, messages",
                        on_submit: EventHandler::new(|query: String| recent_searches::add(&query)),
                        dismiss,
                    }),
            )
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::px(1.))
                    .background(c.outline_variant_light),
            )
            .child(chips)
            .child(if has_query {
                SearchResults {
                    search,
                    filter: current,
                    on_scroll: Some(dismiss),
                }
                .into_element()
            } else {
                EmptySearch { query: search }.into_element()
            })
    }
}
