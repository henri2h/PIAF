use freya::prelude::*;
use freya_material_design::prelude::ButtonRippleExt;
use freya_router::prelude::RouterContext;

use crate::{
    Route, SYNC_RX,
    utils::{const_values::STATUS_BAR_INSET, matrix::CLIENT, use_app_colors},
};

#[derive(PartialEq)]
pub struct WelcomePage {}
impl Component for WelcomePage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let mut loading: State<bool> = use_state(|| true);

        use_hook(|| {
            spawn(async move {
                // Already logged in (restore was instant)
                if CLIENT.get().is_some() {
                    let _ = RouterContext::get().push(Route::HomePage);
                    return;
                }
                // Wait for restore to finish. Use a tokio task to run
                // changed() — calling it from a Freya spawn triggers tokio's
                // coop waker immediately, causing a spin loop.
                if let Some(rx) = SYNC_RX.get() {
                    let mut rx = rx.clone();
                    // Second check covers the race between the first check and clone
                    if CLIENT.get().is_some() {
                        let _ = RouterContext::get().push(Route::HomePage);
                        return;
                    }
                    let (tx, delay_rx) = futures::channel::oneshot::channel::<()>();
                    tokio::task::spawn(async move {
                        let _ = rx.changed().await;
                        let _ = tx.send(());
                    });
                    let _ = delay_rx.await;
                }
                if CLIENT.get().is_some() {
                    let _ = RouterContext::get().push(Route::HomePage);
                } else {
                    *loading.write() = false;
                }
            });
        });

        let is_loading = *loading.read();

        let header = rect()
            .width(Size::fill())
            .height(Size::percent(50.))
            .vertical()
            .spacing(8.)
            .color(c.on_primary)
            .background(c.splash_bg)
            .shadow((0., 4., 20., 4., (0, 0, 0, 80)))
            // Push content below the status bar; center the rest
            .padding(Gaps::new(STATUS_BAR_INSET, 0., 0., 0.))
            .cross_align(Alignment::center())
            .main_align(Alignment::center())
            .child(
                label()
                    .text("PIAF")
                    .font_weight(FontWeight::BOLD)
                    .font_size(64.),
            )
            .child(
                label()
                    .text("Matrix client")
                    .font_size(16.)
                    .color((255, 255, 255, 180u8)),
            );

        let bottom = if is_loading {
            rect()
                .vertical()
                .width(Size::fill())
                .height(Size::percent(50.))
                .center()
                .child(CircularLoader::new().size(36.))
                .into_element()
        } else {
            rect()
                .vertical()
                .width(Size::fill())
                .height(Size::percent(50.))
                .center()
                .spacing(16.)
                .padding(Gaps::new_symmetric(0., 40.))
                .child(
                    Button::new()
                        .filled()
                        .expanded()
                        .on_press(|_| {
                            let _ = RouterContext::get().push(Route::LoginPage);
                        })
                        .ripple()
                        .child(
                            rect()
                                .horizontal()
                                .center()
                                .spacing(10.)
                                .child(
                                    svg(freya_icons::lucide::log_in())
                                        .width(Size::px(20.))
                                        .height(Size::px(20.)),
                                )
                                .child(label().text("Sign in").font_size(16.)),
                        ),
                )
                .child(
                    Button::new().outline().expanded().ripple().child(
                        rect()
                            .horizontal()
                            .center()
                            .spacing(10.)
                            .child(
                                svg(freya_icons::lucide::user_plus())
                                    .width(Size::px(20.))
                                    .height(Size::px(20.)),
                            )
                            .child(label().text("Create account").font_size(16.)),
                    ),
                )
                .into_element()
        };

        rect().vertical().expanded().child(header).child(bottom)
    }
}
