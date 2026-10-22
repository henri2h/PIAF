use std::sync::atomic::Ordering;
use std::time::Duration;

use freya::prelude::*;

use crate::ui::components::IconButton;

use crate::utils::avatars::AvatarSource;
use freya_query::prelude::*;

use crate::app::keys::{KeyCommand, use_key_commands};
use crate::ui::components::{Avatar, HoverableExt, search_input, use_color_transition};
use crate::utils::queries::FetchUserDisplayName;
use crate::utils::use_app_colors;
use crate::{Route, WIDE_MODE};

/// Home top bar: avatar → settings, title or inline search (wide mode),
/// search toggle + reactions + new-chat actions (narrow mode). On narrow
/// screens, toggling search also opens a search row below the bar.
pub struct HomeAppBar {
    pub search: State<String>,
    pub search_open: State<bool>,
    /// Content is scrolled under the bar: use the tinted surface.
    pub tinted: State<bool>,
}

impl PartialEq for HomeAppBar {
    fn eq(&self, _: &Self) -> bool {
        false
    }
}

impl Component for HomeAppBar {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut search = self.search;
        let mut search_open = self.search_open;
        let is_wide = WIDE_MODE.load(Ordering::Relaxed);
        let is_search_open = *search_open.read();
        let search_a11y = use_a11y();
        use_search_key(search_open, search_a11y);

        let name_query =
            use_query(Query::new((), FetchUserDisplayName).stale_time(Duration::from_secs(3600)));
        let my_name = name_query.read().state().ok().cloned().unwrap_or_default();

        let background = use_color_transition(
            if *self.tinted.read() {
                c.surface_container
            } else {
                c.surface
            },
            200,
        );

        rect()
            .vertical()
            .width(Size::fill())
            .background(background)
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::px(crate::utils::insets::status_bar_inset())),
            )
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .height(Size::px(64.))
                    .content(Content::Flex)
                    .cross_align(Alignment::Center)
                    .padding(Gaps::new(0., 8., 0., 8.))
                    // Avatar — taps to Settings
                    .child(
                        rect()
                            .width(Size::px(48.))
                            .height(Size::px(48.))
                            .corner_radius(24.)
                            .center()
                            .on_press(move |_| {
                                crate::app::navigation::push(Route::Settings);
                            })
                            .child(Avatar {
                                size: 36.,
                                source: Some(AvatarSource::Me),
                                name: my_name,
                                color: c.primary,
                            })
                            .hoverable(Size::px(48.), Size::px(48.), 24.),
                    )
                    // Wide: inline search input; narrow: "Chats" title
                    .child(if is_wide {
                        rect()
                            .width(Size::flex(1.0))
                            .padding(Gaps::new(0., 8., 0., 8.))
                            .child(
                                // Short: the field is narrow beside the avatar and icons.
                                search_input(search, "Search…", c).a11y_id(search_a11y),
                            )
                            .into_element()
                    } else {
                        label()
                            .text("Chats")
                            .font_size(24.)
                            .font_weight(FontWeight::MEDIUM)
                            .color(c.on_surface)
                            .width(Size::flex(1.0))
                            .padding(Gaps::new(0., 8., 0., 8.))
                            .into_element()
                    })
                    // Narrow: search toggle icon
                    .maybe_child(if !is_wide {
                        Some(
                            IconButton::new(
                                if is_search_open {
                                    freya_icons::lucide::x()
                                } else {
                                    freya_icons::lucide::search()
                                },
                                c.on_surface_variant,
                                move |_| {
                                    // Android: search mode is its own page.
                                    if cfg!(target_os = "android") {
                                        crate::app::navigation::push(Route::SearchPage);
                                        return;
                                    }
                                    let new_val = !*search_open.read();
                                    if !new_val {
                                        *search.write() = String::new();
                                    }
                                    *search_open.write() = new_val;
                                },
                            )
                            .tooltip("Search")
                            .size(48., 22.)
                            .into_element(),
                        )
                    } else {
                        None
                    })
                    // Bookmarks button (desktop; Android: More tab)
                    .maybe_child((!cfg!(target_os = "android")).then(|| {
                        IconButton::new(
                            freya_icons::lucide::bookmark(),
                            c.on_surface_variant,
                            move |_| {
                                crate::app::navigation::push(crate::Route::BookmarksPage);
                            },
                        )
                        .tooltip("Bookmarks")
                        .size(48., 22.)
                        .into_element()
                    }))
                    // Reactions button (desktop; Android: More tab)
                    .maybe_child((!cfg!(target_os = "android")).then(|| {
                        IconButton::new(
                            freya_icons::lucide::heart(),
                            c.on_surface_variant,
                            move |_| {
                                crate::app::navigation::push(crate::Route::ReactionsPage);
                            },
                        )
                        .tooltip("Reactions")
                        .size(48., 22.)
                        .into_element()
                    })),
            )
            // Narrow: search row below the bar, shown while toggled open.
            .maybe_child(if !is_wide && is_search_open {
                Some(
                    rect()
                        .width(Size::fill())
                        .padding(Gaps::new(6., 16., 6., 16.))
                        .background(background)
                        .child(
                            search_input(search, "Search conversations, people…", c)
                                .a11y_id(search_a11y)
                                .auto_focus(true),
                        ),
                )
            } else {
                None
            })
    }
}

/// `/` opens (narrow) and focuses the search field.
fn use_search_key(mut search_open: State<bool>, search_a11y: AccessibilityId) {
    use_key_commands(move |_, command| {
        if command == KeyCommand::Search {
            search_open.set(true);
            search_a11y.request_focus();
        }
    });
}
