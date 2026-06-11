use freya::prelude::*;
use freya_material_design::prelude::ButtonRippleExt;
use freya_router::prelude::RouterContext;

use crate::{
    REQUESTER, Route,
    utils::{const_values::STATUS_BAR_INSET, use_app_colors},
};

mod labeled_input;
use labeled_input::labeled_input;

#[derive(PartialEq)]
pub struct LoginPage {}

impl Component for LoginPage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let login = use_state(String::new);
        let password = use_state(String::new);
        let mut error_string: State<Option<String>> = use_state(|| None);
        let mut logging_in: State<bool> = use_state(|| false);

        let is_logging_in = *logging_in.read();

        let mut submit = move || {
            if is_logging_in {
                return;
            }
            let username = login.read().clone();
            let pwd = password.read().clone();
            if username.is_empty() || pwd.is_empty() {
                *error_string.write() = Some("Please enter your username and password.".into());
                return;
            }
            *error_string.write() = None;
            *logging_in.write() = true;
            spawn(async move {
                let result = REQUESTER.get().unwrap().login(username, pwd).await;
                *logging_in.write() = false;
                match result {
                    Ok(()) => {
                        let _ = RouterContext::get().replace(Route::HomePage);
                    }
                    Err(e) => {
                        *error_string.write() = Some(e.to_string());
                    }
                }
            });
        };

        rect()
            .vertical()
            .expanded()
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::percent(38.))
                    .background(c.splash_bg)
                    .vertical()
                    .child(
                        rect()
                            .width(Size::fill())
                            .padding(Gaps::new(STATUS_BAR_INSET + 12., 12., 0., 12.))
                            .child(
                                rect()
                                    .width(Size::px(40.))
                                    .height(Size::px(40.))
                                    .corner_radius(20.)
                                    .center()
                                    .overflow(Overflow::Clip)
                                    .on_press(|_| {
                                        let _ = RouterContext::get().go_back();
                                    })
                                    .child(
                                        svg(freya_icons::lucide::arrow_left())
                                            .width(Size::px(22.))
                                            .height(Size::px(22.))
                                            .color(c.on_primary),
                                    ),
                            ),
                    )
                    .child(
                        rect()
                            .width(Size::fill())
                            .height(Size::flex(1.0))
                            .center()
                            .vertical()
                            .spacing(10.)
                            .child(
                                rect()
                                    .width(Size::px(72.))
                                    .height(Size::px(72.))
                                    .corner_radius(36.)
                                    .center()
                                    .background((255, 255, 255, 30u8))
                                    .child(
                                        svg(freya_icons::lucide::message_circle())
                                            .width(Size::px(38.))
                                            .height(Size::px(38.))
                                            .color(c.on_primary),
                                    ),
                            )
                            .child(
                                label()
                                    .text("Sign in")
                                    .font_size(26.)
                                    .font_weight(FontWeight::BOLD)
                                    .color(c.on_primary),
                            )
                            .child(
                                label()
                                    .text("Connect to your Matrix account")
                                    .font_size(14.)
                                    .color((255, 255, 255, 180u8)),
                            ),
                    ),
            )
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .background(c.surface)
                    .corner_radius(24.)
                    .margin(Gaps::new(-24., 0., 0., 0.))
                    .child(
                        ScrollView::new()
                            .width(Size::fill())
                            .height(Size::fill())
                            .child(
                                rect()
                                    .vertical()
                                    .width(Size::fill())
                                    .padding(Gaps::new(32., 24., 32., 24.))
                                    .spacing(20.)
                                    .child(labeled_input(
                                        "Username",
                                        Input::new(login)
                                            .flat()
                                            .placeholder("@you:matrix.org")
                                            .auto_focus(true)
                                            .width(Size::fill()),
                                        false,
                                    ))
                                    .child(labeled_input(
                                        "Password",
                                        Input::new(password)
                                            .flat()
                                            .placeholder("Your password")
                                            .mode(InputMode::Hidden('•'))
                                            .on_submit(move |_| submit())
                                            .width(Size::fill()),
                                        false,
                                    ))
                                    .child(if let Some(err) = error_string.read().clone() {
                                        rect()
                                            .width(Size::fill())
                                            .padding(Gaps::new_all(12.))
                                            .corner_radius(10.)
                                            .background((c.error.0, c.error.1, c.error.2, 18u8))
                                            .border(
                                                Border::new()
                                                    .fill((c.error.0, c.error.1, c.error.2, 60u8))
                                                    .width(1.)
                                                    .alignment(BorderAlignment::Inner),
                                            )
                                            .child(
                                                rect()
                                                    .horizontal()
                                                    .spacing(8.)
                                                    .cross_align(Alignment::center())
                                                    .child(
                                                        svg(freya_icons::lucide::circle_alert())
                                                            .width(Size::px(16.))
                                                            .height(Size::px(16.))
                                                            .color(c.error),
                                                    )
                                                    .child(
                                                        label()
                                                            .text(err)
                                                            .font_size(13.)
                                                            .color(c.error),
                                                    ),
                                            )
                                            .into_element()
                                    } else {
                                        rect().into_element()
                                    })
                                    .child(
                                        Button::new()
                                            .filled()
                                            .expanded()
                                            .enabled(!is_logging_in)
                                            .on_press(move |_| submit())
                                            .ripple()
                                            .child(if is_logging_in {
                                                rect()
                                                    .horizontal()
                                                    .center()
                                                    .spacing(10.)
                                                    .child(CircularLoader::new().size(18.))
                                                    .child(
                                                        label().text("Signing in…").font_size(16.),
                                                    )
                                                    .into_element()
                                            } else {
                                                rect()
                                                    .horizontal()
                                                    .center()
                                                    .spacing(10.)
                                                    .child(
                                                        svg(freya_icons::lucide::log_in())
                                                            .width(Size::px(20.))
                                                            .height(Size::px(20.)),
                                                    )
                                                    .child(label().text("Sign in").font_size(16.))
                                                    .into_element()
                                            }),
                                    )
                                    .child(
                                        rect()
                                            .width(Size::fill())
                                            .height(Size::px(1.))
                                            .background(c.outline_variant)
                                            .margin(Gaps::new(4., 0., 4., 0.)),
                                    )
                                    .child(
                                        rect()
                                            .width(Size::fill())
                                            .center()
                                            .horizontal()
                                            .spacing(4.)
                                            .child(
                                                label()
                                                    .text("New to Matrix?")
                                                    .font_size(14.)
                                                    .color(c.on_surface_muted),
                                            )
                                            .child(
                                                label()
                                                    .text("Create an account")
                                                    .font_size(14.)
                                                    .font_weight(FontWeight::BOLD)
                                                    .color(c.primary),
                                            ),
                                    ),
                            ),
                    ),
            )
    }
}
