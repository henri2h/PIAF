use std::sync::atomic::Ordering;
use std::time::Duration;

use freya::prelude::*;
use freya_query::prelude::*;
use freya_router::prelude::RouterContext;

use crate::ui::components::Avatar;
use crate::utils::const_values::AppColors;
use crate::utils::queries::FetchUserDisplayName;
use crate::utils::use_app_colors;
use crate::{Route, WIDE_MODE};

/// Home top bar: avatar → settings, title or inline search (wide mode),
/// search toggle + reactions + new-chat actions (narrow mode). On narrow
/// screens, toggling search also opens a search row below the bar.
pub struct HomeAppBar {
    pub search: State<String>,
    pub search_open: State<bool>,
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

        let name_query =
            use_query(Query::new((), FetchUserDisplayName).stale_time(Duration::from_secs(3600)));
        let initial = name_query
            .read()
            .state()
            .ok()
            .and_then(|n| n.chars().next())
            .map(|c| c.to_uppercase().to_string())
            .unwrap_or_else(|| "?".to_string());

        rect()
            .vertical()
            .width(Size::fill())
            .background(c.surface)
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::px(crate::utils::const_values::STATUS_BAR_INSET)),
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
                                let _ = RouterContext::get().push(Route::Settings);
                            })
                            .child(Avatar {
                                size: 36.,
                                bytes: None,
                                fetch_key: Some("__self__".to_string()),
                                initial,
                                color: c.primary,
                                image_key: "__self__".to_string(),
                            }),
                    )
                    // Wide: inline search input; narrow: "Chats" title
                    .child(if is_wide {
                        rect()
                            .width(Size::flex(1.0))
                            .padding(Gaps::new(0., 8., 0., 8.))
                            .child(search_input(search, c))
                            .into_element()
                    } else {
                        label()
                            .text("Chats")
                            .font_size(22.)
                            .font_weight(FontWeight::MEDIUM)
                            .color(c.on_surface)
                            .width(Size::flex(1.0))
                            .padding(Gaps::new(0., 8., 0., 8.))
                            .into_element()
                    })
                    // Narrow: search toggle icon
                    .maybe_child(if !is_wide {
                        Some(
                            rect()
                                .width(Size::px(48.))
                                .height(Size::px(48.))
                                .corner_radius(24.)
                                .center()
                                .on_press(move |_| {
                                    let new_val = !*search_open.read();
                                    if !new_val {
                                        *search.write() = String::new();
                                    }
                                    *search_open.write() = new_val;
                                })
                                .child(
                                    SvgViewer::new(if is_search_open {
                                        freya_icons::lucide::x()
                                    } else {
                                        freya_icons::lucide::search()
                                    })
                                    .color(c.on_surface_variant)
                                    .width(Size::px(22.))
                                    .height(Size::px(22.)),
                                ),
                        )
                    } else {
                        None
                    })
                    // Reactions button (both modes)
                    .child(
                        rect()
                            .width(Size::px(48.))
                            .height(Size::px(48.))
                            .corner_radius(24.)
                            .center()
                            .on_press(|_| {
                                let _ = RouterContext::get().push(crate::Route::ReactionsPage);
                            })
                            .child(
                                SvgViewer::new(freya_icons::lucide::heart())
                                    .color(c.on_surface_variant)
                                    .width(Size::px(22.))
                                    .height(Size::px(22.)),
                            ),
                    )
                    // Pencil button (both modes)
                    .child(
                        rect()
                            .width(Size::px(48.))
                            .height(Size::px(48.))
                            .corner_radius(24.)
                            .center()
                            .on_press(|_| {
                                let _ = RouterContext::get().push(crate::Route::NewChat);
                            })
                            .child(
                                SvgViewer::new(freya_icons::lucide::pencil())
                                    .color(c.on_surface_variant)
                                    .width(Size::px(22.))
                                    .height(Size::px(22.)),
                            ),
                    ),
            )
            // Narrow: search row below the bar, shown while toggled open.
            .maybe_child(if !is_wide && is_search_open {
                Some(
                    rect()
                        .width(Size::fill())
                        .padding(Gaps::new(6., 16., 6., 16.))
                        .background(c.surface)
                        .child(search_input(search, c)),
                )
            } else {
                None
            })
    }
}

fn search_input(search: State<String>, c: AppColors) -> Input {
    Input::new(search)
        .leading(
            SvgViewer::new(freya_icons::lucide::search())
                .color(c.on_surface_variant)
                .width(Size::px(15.))
                .height(Size::px(15.)),
        )
        .placeholder("Search conversations, people…")
        .width(Size::fill())
        .theme_colors(InputColorsThemePartial {
            background: Some(Preference::Specific(Color::from(c.surface_container))),
            focus_background: Some(Preference::Specific(Color::from(c.surface_container))),
            border_fill: Some(Preference::Specific(Color::TRANSPARENT)),
            focus_border_fill: Some(Preference::Specific(Color::from(c.primary))),
            ..Default::default()
        })
        .theme_layout(InputLayoutThemePartial {
            corner_radius: Some(Preference::Specific(CornerRadius::new_all(8.))),
            inner_margin: Some(Preference::Specific(Gaps::new(10., 10., 10., 10.))),
        })
}
