use freya::prelude::*;
use freya_router::prelude::{RouterContext, use_route};

use super::Layout;
use super::nav_bar::NavBar;
use crate::app::Route;
use crate::app::page_transition::PageTransition;
use crate::app::theme::effective_theme;
use crate::utils::insets::use_insets;
use crate::utils::use_app_colors;

/// Android: single panel with bottom navigation bar; double back press to exit.
impl Component for Layout {
    fn render(&self) -> impl IntoElement {
        use_init_theme(|| effective_theme(crate::app::theme::load_is_dark()));
        let c = use_app_colors();
        let mut back_pressed: State<bool> = use_state(|| false);

        let route = use_route::<Route>();
        // A tapped notification opens its room once the session is restored.
        crate::app::navigation::use_open_room_requests(!matches!(
            route,
            Route::WelcomePage | Route::LoginPage
        ));
        let insets = *use_insets().read();
        // Tabs only on the top-level pages: conversations and their pages get
        // the full height, and the keyboard covers the tab bar's spot anyway.
        let show_navbar = !insets.keyboard_open()
            && !matches!(
                route,
                Route::WelcomePage
                    | Route::LoginPage
                    | Route::BookmarksPage
                    | Route::SearchPage
                    | Route::RoomPage { .. }
                    | Route::RoomSearch { .. }
                    | Route::RoomSettings { .. }
                    | Route::RoomMediaPage { .. }
                    | Route::RoomMembers { .. }
                    | Route::PendingDm { .. }
                    | Route::PendingGroup
            );
        // Keep the content above the keyboard and the system navigation bar
        // (the tab bar pads itself for the latter).
        let bottom_padding = if show_navbar {
            0.
        } else {
            insets.content_bottom()
        };

        rect()
            .vertical()
            .expanded()
            // The page is `Size::flex`: without this it takes the whole height
            // and pushes the tab bar off the screen.
            .content(Content::Flex)
            .padding(Gaps::new(0., 0., bottom_padding, 0.))
            // Behind the page while it fades in: without it the window's
            // clear colour (white) shows through.
            .background(c.surface)
            .native_router()
            .child(ContextMenuViewer::new())
            .on_global_key_down(move |e: Event<KeyboardEventData>| {
                if e.key != Key::Named(NamedKey::BrowserBack) {
                    return;
                }
                let router = RouterContext::get();
                if router.can_go_back() {
                    router.go_back();
                } else if *back_pressed.read() {
                    std::process::exit(0);
                } else {
                    *back_pressed.write() = true;
                    let rx = crate::utils::on_tokio::<(), _>(async move {
                        tokio::time::sleep(std::time::Duration::from_secs(2)).await;
                        ()
                    });
                    spawn(async move {
                        let _ = rx.await;
                        *back_pressed.write() = false;
                    });
                }
            })
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .child(PageTransition),
            )
            .maybe_child(back_pressed.read().then(|| {
                rect()
                    .width(Size::fill())
                    .height(Size::px(36.))
                    .background(c.surface_container)
                    .center()
                    .child(
                        label()
                            .text("Press back again to exit")
                            .font_size(13.)
                            .color(c.on_surface_muted),
                    )
            }))
            .child(if show_navbar {
                NavBar.into_element()
            } else {
                rect().into_element()
            })
    }
}
