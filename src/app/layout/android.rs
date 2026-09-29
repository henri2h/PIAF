use freya::prelude::*;
use freya_icons::lucide;
use freya_material_design::prelude::FloatingTabRippleExt;
use freya_router::prelude::{Outlet, RouterContext, use_route};

use super::Layout;
use crate::app::Route;
use crate::app::theme::effective_theme;
use crate::utils::{matrix::load_theme_is_dark, use_app_colors};

/// Android: single panel with bottom navigation bar; double back press to exit.
impl Component for Layout {
    fn render(&self) -> impl IntoElement {
        use_init_theme(|| effective_theme(load_theme_is_dark()));
        let c = use_app_colors();
        let mut back_pressed: State<bool> = use_state(|| false);

        let route = use_route::<Route>();
        let show_navbar = !matches!(
            route,
            Route::WelcomePage
                | Route::LoginPage
                | Route::BookmarksPage
                | Route::RecontactPage
                | Route::ArchivedPage
        );

        rect()
            .vertical()
            .expanded()
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
                    let (tx, rx) = futures::channel::oneshot::channel::<()>();
                    tokio::task::spawn(async move {
                        tokio::time::sleep(std::time::Duration::from_secs(2)).await;
                        let _ = tx.send(());
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
                    .child(Outlet::<Route>::new()),
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
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .main_align(Alignment::center())
                    .padding(Gaps::new(4., 4., 20., 4.))
                    .spacing(4.)
                    .background(c.surface)
                    .child(navbar_tab(Route::HomePage, "Chats", lucide::message_circle))
                    .child(navbar_tab(Route::Settings, "Settings", lucide::settings))
                    .into_element()
            } else {
                rect().into_element()
            })
    }
}

fn navbar_tab(
    route: Route,
    tab_label: &'static str,
    icon: fn() -> bytes::Bytes,
) -> ActivableRoute<Route> {
    ActivableRoute::new(
        route.clone(),
        Link::new(route).child(
            FloatingTab::new().ripple().child(
                rect()
                    .center()
                    .vertical()
                    .spacing(2.)
                    .child(
                        SvgViewer::new(icon())
                            .width(Size::px(22.))
                            .height(Size::px(22.)),
                    )
                    .child(label().text(tab_label).font_size(11.)),
            ),
        ),
    )
    .routes(vec![])
}
