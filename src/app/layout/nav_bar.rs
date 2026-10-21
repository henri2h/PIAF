use freya::prelude::*;
use freya_icons::lucide;
use freya_router::prelude::use_route;

use crate::app::Route;
use crate::app::navigation::push;
use crate::ui::components::HoverableExt;
use crate::utils::const_values::AppColors;
use crate::utils::insets::use_insets;
use crate::utils::use_app_colors;

/// Android bottom navigation (Material 3): tabs on their own surface, the
/// selected one marked by a tonal pill behind its icon. Settings is reached
/// from the avatar in the home app bar.
#[derive(PartialEq)]
pub struct NavBar;

impl Component for NavBar {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let current = use_route::<Route>();
        let system_bar = use_insets().read().bottom;
        let tab = |route: Route, label: &'static str, icon: fn() -> bytes::Bytes, sub: &[Route]| {
            let on_root = current == route;
            let active = on_root || sub.contains(&current);
            nav_tab(c, route, label, icon(), active, on_root)
        };

        rect()
            .horizontal()
            .width(Size::fill())
            .content(Content::Flex)
            // Extends under the system navigation bar.
            .padding(Gaps::new(10., 8., 8. + system_bar, 8.))
            .background(c.surface_container)
            .child(tab(Route::HomePage, "Chats", lucide::message_circle, &[]))
            .child(tab(
                Route::MorePage,
                "More",
                lucide::ellipsis,
                &[
                    Route::RecontactPage,
                    Route::ArchivedPage,
                    Route::ReactionsPage,
                    Route::BookmarksPage,
                ],
            ))
    }
}

/// `active`: this tab or one of its pages is shown; `on_root`: the tab's own page is.
fn nav_tab(
    c: AppColors,
    route: Route,
    label_text: &'static str,
    icon: bytes::Bytes,
    active: bool,
    on_root: bool,
) -> Element {
    let pill = rect()
        .width(Size::px(64.))
        .height(Size::px(32.))
        .corner_radius(16.)
        .center()
        .maybe(active, |el| el.background(c.primary_container))
        .child(
            SvgViewer::new(icon)
                .width(Size::px(22.))
                .height(Size::px(22.))
                .color(if active {
                    c.on_primary_container
                } else {
                    c.on_surface_variant
                }),
        )
        .hoverable(Size::px(64.), Size::px(32.), 16.);

    rect()
        .width(Size::flex(1.))
        .vertical()
        .cross_align(Alignment::Center)
        .spacing(4.)
        // From one of the tab's pages, tapping it goes back to its root.
        .on_press(move |_| {
            if !on_root {
                push(route.clone());
            }
        })
        .child(pill)
        .child(
            label()
                .text(label_text)
                .font_size(12.)
                .font_weight(if active {
                    FontWeight::MEDIUM
                } else {
                    FontWeight::NORMAL
                })
                .color(if active {
                    c.on_surface
                } else {
                    c.on_surface_variant
                }),
        )
        .into()
}
