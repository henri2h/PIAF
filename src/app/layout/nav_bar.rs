use std::collections::HashSet;

use freya::prelude::*;
use freya_icons::lucide;
use freya_router::prelude::use_route;

use crate::app::Route;
use crate::app::navigation::push;
use crate::ui::components::HoverableExt;
use crate::ui::pages::home::room_list_model::unread_conversations;
use crate::utils::const_values::AppColors;
use crate::utils::insets::use_insets;
use crate::utils::{room_list, spaces, use_app_colors, use_watch, use_watch_tick};

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
        let snapshot = use_watch(room_list::receiver());
        let _mailbox = use_watch_tick(crate::ROOM_MAILBOX_RX.get().expect("not initialized"));
        let unread = {
            let mailbox = crate::ROOM_MAILBOX_RX
                .get()
                .expect("not initialized")
                .borrow();
            unread_conversations(&snapshot.read().rooms, &mailbox, None)
        };
        let spaces = use_watch(spaces::receiver());
        // Unread conversations inside any space.
        let space_unread = {
            let rooms: HashSet<String> = spaces
                .read()
                .iter()
                .flat_map(|s| s.rooms.iter().cloned())
                .collect();
            let mailbox = crate::ROOM_MAILBOX_RX
                .get()
                .expect("not initialized")
                .borrow();
            unread_conversations(&snapshot.read().rooms, &mailbox, Some(&rooms))
        };
        // Sub-pages of a tab keep it selected.
        let in_space = matches!(current, Route::SpacePage { .. });
        let tab = |route: Route,
                   label: &'static str,
                   icon: fn() -> bytes::Bytes,
                   sub: &[Route],
                   badge: usize| {
            let on_root = current == route;
            let active =
                on_root || sub.contains(&current) || (route == Route::SpacesPage && in_space);
            nav_tab(c, route, label, icon(), active, on_root, badge)
        };

        rect()
            .horizontal()
            .width(Size::fill())
            .content(Content::Flex)
            // Extends under the system navigation bar.
            .padding(Gaps::new(10., 8., 8. + system_bar, 8.))
            .background(c.surface_container)
            .child(tab(
                Route::HomePage,
                "Chats",
                lucide::message_circle,
                &[],
                unread,
            ))
            .child(tab(
                Route::SpacesPage,
                "Spaces",
                lucide::layers,
                &[],
                space_unread,
            ))
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
                0,
            ))
    }
}

/// `active`: this tab or one of its pages is shown; `on_root`: the tab's own
/// page is. `badge`: unread count on the icon, hidden at 0.
fn nav_tab(
    c: AppColors,
    route: Route,
    label_text: &'static str,
    icon: bytes::Bytes,
    active: bool,
    on_root: bool,
    badge: usize,
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
    // Material badge: over the icon's top right corner.
    let pill = rect()
        .width(Size::px(64.))
        .height(Size::px(32.))
        .child(pill)
        .maybe_child((badge > 0).then(|| {
            rect()
                .position(Position::new_absolute().top(1.).left(36.))
                // Above the pill, which the hover layer raises.
                .layer(Layer::Relative(10))
                .min_width(Size::px(16.))
                .height(Size::px(16.))
                .corner_radius(8.)
                .padding(Gaps::new(0., 4., 0., 4.))
                .center()
                .background(c.error)
                .child(
                    label()
                        .text(if badge > 99 {
                            "99+".to_string()
                        } else {
                            badge.to_string()
                        })
                        .font_size(10.)
                        .font_weight(FontWeight::MEDIUM)
                        .color(c.on_primary),
                )
        }));

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
