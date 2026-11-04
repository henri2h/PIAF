use freya::prelude::*;
use freya_icons::lucide;
use freya_material_design::prelude::ButtonRippleExt;
use freya_router::prelude::RouterContext;

use crate::ui::components::{HoverableExt, brand_hero, use_auth_size};
use crate::utils::const_values::AppColors;
use crate::utils::insets::status_bar_inset;
use crate::{
    Route, SYNC_RX,
    utils::{matrix::CLIENT, use_app_colors},
};

/// Where "Create an account" leads: PIAF has no sign-up of its own.
const REGISTER_URL: &str = "https://app.element.io/#/register";
const ACTIONS_MAX_WIDTH: f32 = 360.;

#[derive(PartialEq)]
pub struct WelcomePage {}
impl Component for WelcomePage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let mut loading: State<bool> = use_state(|| true);
        let size = use_auth_size();

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
                    // `changed()` must be awaited on tokio, not on Freya's executor.
                    crate::utils::on_tokio(async move {
                        let _ = rx.changed().await;
                    })
                    .await;
                }
                if CLIENT.get().is_some() {
                    let _ = RouterContext::get().push(Route::HomePage);
                } else {
                    *loading.write() = false;
                }
            });
        });

        let is_loading = *loading.read();
        let (is_wide, is_short) = (size.is_wide(), size.is_short());

        let actions = if is_loading {
            CircularLoader::new().size(36.).into_element()
        } else {
            actions(c, is_wide).into_element()
        };

        let body = if is_wide {
            rect()
                .horizontal()
                .expanded()
                .content(Content::Flex)
                .child(
                    brand_hero(c, is_short, 0.)
                        .width(Size::flex(1.))
                        .height(Size::fill()),
                )
                .child(
                    rect()
                        .width(Size::flex(1.))
                        .height(Size::fill())
                        .center()
                        .padding(Gaps::new_symmetric(24., 48.))
                        .child(actions),
                )
        } else {
            // Actions at the bottom, within thumb reach.
            rect()
                .vertical()
                .expanded()
                .content(Content::Flex)
                .child(
                    brand_hero(c, is_short, status_bar_inset())
                        .width(Size::fill())
                        .height(Size::flex(1.))
                        .corner_radius(CornerRadius::new(0., 0., 28., 28.)),
                )
                .child(
                    rect()
                        .width(Size::fill())
                        .center()
                        .padding(if is_short {
                            Gaps::new(16., 24., 16., 24.)
                        } else {
                            Gaps::new(40., 24., 40., 24.)
                        })
                        .child(actions),
                )
        };

        size.page(body, c)
    }
}

/// Sign in, and a link to create an account elsewhere. `heading`: with a title
/// (wide layout, where the brand sits in its own pane).
fn actions(c: AppColors, heading: bool) -> Rect {
    rect()
        .vertical()
        .width(Size::fill())
        .max_width(Size::px(ACTIONS_MAX_WIDTH))
        .spacing(20.)
        .maybe_child(heading.then(|| {
            rect()
                .vertical()
                .spacing(6.)
                .child(
                    label()
                        .text("Welcome")
                        .font_size(28.)
                        .font_weight(FontWeight::BOLD)
                        .color(c.on_surface),
                )
                .child(
                    label()
                        .text("Sign in with your Matrix account to start chatting.")
                        .font_size(14.)
                        .color(c.on_surface_muted),
                )
        }))
        .child(
            Button::new()
                .filled()
                .expanded()
                .width(Size::fill())
                .on_press(|_| crate::app::navigation::push(Route::LoginPage))
                .ripple()
                .child(
                    rect()
                        .horizontal()
                        .center()
                        .spacing(10.)
                        .child(
                            SvgViewer::new(lucide::log_in())
                                .width(Size::px(20.))
                                .height(Size::px(20.)),
                        )
                        .child(label().text("Sign in").font_size(16.)),
                ),
        )
        .child(
            rect()
                .horizontal()
                .width(Size::fill())
                .main_align(Alignment::Center)
                .cross_align(Alignment::Center)
                .spacing(4.)
                .child(
                    label()
                        .text("New to Matrix?")
                        .font_size(14.)
                        .color(c.on_surface_muted),
                )
                .child(
                    rect()
                        .padding(Gaps::new_symmetric(6., 8.))
                        .on_press(|_| Platform::get().open_url(REGISTER_URL.to_string()))
                        .child(
                            label()
                                .text("Create an account")
                                .font_size(14.)
                                .font_weight(FontWeight::MEDIUM)
                                .color(c.primary),
                        )
                        .hoverable(Size::auto(), Size::auto(), 8.),
                ),
        )
}
