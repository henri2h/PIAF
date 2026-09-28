mod field;
mod user_id;

use freya::prelude::*;
use freya_icons::lucide;
use freya_material_design::prelude::ButtonRippleExt;
use freya_router::prelude::RouterContext;

use crate::utils::const_values::{AppColors, STATUS_BAR_INSET};
use crate::utils::use_app_colors;
use crate::{REQUESTER, Route};
use field::{field, icon};
use user_id::normalize_user_id;

/// Two panes (brand | form) from this width, one scrolling column below.
const WIDE_MIN_WIDTH: f32 = 720.;
const FORM_MAX_WIDTH: f32 = 400.;

#[derive(PartialEq)]
pub struct LoginPage {}

impl Component for LoginPage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut width = use_state(|| 0.0f32);
        let login = use_state(String::new);
        let password = use_state(String::new);
        let mut show_password = use_state(|| false);
        let mut error: State<Option<String>> = use_state(|| None);
        let mut logging_in = use_state(|| false);

        let is_logging_in = *logging_in.read();
        let user_id = normalize_user_id(&login.read());

        let mut submit = move || {
            if *logging_in.peek() {
                return;
            }
            let Some(user_id) = normalize_user_id(&login.peek()) else {
                error.set(Some(
                    "Enter your full user ID, like @you:matrix.org.".into(),
                ));
                return;
            };
            let pwd = password.peek().clone();
            if pwd.is_empty() {
                error.set(Some("Enter your password.".into()));
                return;
            }
            error.set(None);
            logging_in.set(true);
            spawn(async move {
                let result = REQUESTER
                    .get()
                    .expect("not initialized")
                    .login(user_id, pwd)
                    .await;
                logging_in.set(false);
                match result {
                    Ok(()) => {
                        let _ = RouterContext::get().replace(Route::HomePage);
                    }
                    Err(e) => error.set(Some(e.to_string())),
                }
            });
        };

        let user_helper = match &user_id {
            Some(id) => id
                .split_once(':')
                .map(|(_, server)| (format!("Server: {server}"), false)),
            None if !login.read().trim().is_empty() => {
                Some(("Include your server, e.g. @you:matrix.org".into(), false))
            }
            None => None,
        };

        let hidden = !*show_password.read();
        let eye_toggle = rect()
            .width(Size::px(32.))
            .height(Size::px(32.))
            .corner_radius(16.)
            .center()
            .on_press(move |_| show_password.toggle())
            .child(icon(
                if hidden {
                    lucide::eye()
                } else {
                    lucide::eye_off()
                },
                c.on_surface_variant,
            ));

        let form = rect()
            .vertical()
            .width(Size::fill())
            .max_width(Size::px(FORM_MAX_WIDTH))
            .spacing(20.)
            .child(
                rect()
                    .vertical()
                    .spacing(6.)
                    .child(
                        label()
                            .text("Sign in")
                            .font_size(28.)
                            .font_weight(FontWeight::BOLD)
                            .color(c.on_surface),
                    )
                    .child(
                        label()
                            .text("Use your Matrix account.")
                            .font_size(14.)
                            .color(c.on_surface_muted),
                    ),
            )
            .child(field(
                c,
                "User ID",
                Input::new(login)
                    .flat()
                    .placeholder("@you:matrix.org")
                    .auto_focus(true)
                    .width(Size::fill())
                    .leading(icon(lucide::at_sign(), c.on_surface_muted))
                    .on_submit(move |_| submit()),
                user_helper,
            ))
            .child(field(
                c,
                "Password",
                Input::new(password)
                    .flat()
                    .placeholder("Your password")
                    .mode(if hidden {
                        InputMode::Hidden('•')
                    } else {
                        InputMode::Shown
                    })
                    .width(Size::fill())
                    .leading(icon(lucide::lock(), c.on_surface_muted))
                    .trailing(eye_toggle)
                    .on_submit(move |_| submit()),
                None,
            ))
            .maybe_child(error.read().clone().map(|msg| error_box(c, msg)))
            .child(
                Button::new()
                    .filled()
                    .expanded()
                    .enabled(!is_logging_in)
                    .on_press(move |_| submit())
                    .ripple()
                    .child(
                        rect()
                            .horizontal()
                            .center()
                            .spacing(10.)
                            .child(if is_logging_in {
                                CircularLoader::new().size(18.).into_element()
                            } else {
                                icon(lucide::log_in(), c.on_primary).into_element()
                            })
                            .child(
                                label()
                                    .text(if is_logging_in {
                                        "Signing in…"
                                    } else {
                                        "Sign in"
                                    })
                                    .font_size(16.),
                            ),
                    ),
            );

        let is_wide = *width.read() >= WIDE_MIN_WIDTH;
        let body = if is_wide {
            rect()
                .horizontal()
                .expanded()
                .content(Content::Flex)
                .child(brand_panel(c))
                .child(
                    rect()
                        .vertical()
                        .width(Size::flex(1.))
                        .height(Size::fill())
                        .content(Content::Flex)
                        .child(top_bar(c))
                        .child(
                            rect()
                                .width(Size::fill())
                                .height(Size::flex(1.))
                                .center()
                                .padding(Gaps::new_symmetric(24., 48.))
                                .child(form),
                        ),
                )
                .into_element()
        } else {
            rect()
                .vertical()
                .expanded()
                .content(Content::Flex)
                .child(top_bar(c))
                .child(
                    ScrollView::new()
                        .width(Size::fill())
                        .height(Size::flex(1.))
                        .child(
                            rect()
                                .vertical()
                                .width(Size::fill())
                                .cross_align(Alignment::Center)
                                .padding(Gaps::new(8., 24., 32., 24.))
                                .spacing(32.)
                                .child(brand_mark(c))
                                .child(form),
                        ),
                )
                .into_element()
        };

        rect()
            .expanded()
            .background(c.surface)
            .on_sized(move |e: Event<SizedEventData>| {
                let w = e.area.width();
                if (*width.peek() - w).abs() > 0.5 {
                    width.set(w);
                }
            })
            .child(body)
    }
}

/// Back button, when there is somewhere to go back to.
fn top_bar(c: AppColors) -> Rect {
    let can_go_back = RouterContext::get().can_go_back();
    rect()
        .width(Size::fill())
        .padding(Gaps::new(STATUS_BAR_INSET + 8., 8., 0., 8.))
        .maybe_child(can_go_back.then(|| {
            rect()
                .width(Size::px(40.))
                .height(Size::px(40.))
                .corner_radius(20.)
                .center()
                .on_press(|_| RouterContext::get().go_back())
                .child(icon(lucide::arrow_left(), c.on_surface))
        }))
}

/// Wide layout: full-height brand pane.
fn brand_panel(c: AppColors) -> Rect {
    rect()
        .vertical()
        .width(Size::flex(1.))
        .height(Size::fill())
        .center()
        .spacing(12.)
        .background(c.splash_bg)
        .child(
            rect()
                .width(Size::px(88.))
                .height(Size::px(88.))
                .corner_radius(44.)
                .center()
                .background((255, 255, 255, 30u8))
                .child(
                    SvgViewer::new(lucide::message_circle())
                        .width(Size::px(44.))
                        .height(Size::px(44.))
                        .color(c.on_primary),
                ),
        )
        .child(
            label()
                .text("PIAF")
                .font_size(48.)
                .font_weight(FontWeight::BOLD)
                .color(c.on_primary),
        )
        .child(
            label()
                .text("A Matrix client")
                .font_size(16.)
                .color((255, 255, 255, 190u8)),
        )
}

/// Narrow layout: small logo above the form.
fn brand_mark(c: AppColors) -> Rect {
    rect()
        .horizontal()
        .width(Size::fill())
        .max_width(Size::px(FORM_MAX_WIDTH))
        .spacing(10.)
        .cross_align(Alignment::Center)
        .child(
            rect()
                .width(Size::px(40.))
                .height(Size::px(40.))
                .corner_radius(20.)
                .center()
                .background(c.primary)
                .child(icon(lucide::message_circle(), c.on_primary)),
        )
        .child(
            label()
                .text("PIAF")
                .font_size(20.)
                .font_weight(FontWeight::BOLD)
                .color(c.primary),
        )
}

fn error_box(c: AppColors, message: String) -> Rect {
    let (r, g, b) = c.error;
    rect()
        .horizontal()
        .width(Size::fill())
        .padding(Gaps::new_all(12.))
        .spacing(8.)
        .corner_radius(12.)
        .cross_align(Alignment::Center)
        .background((r, g, b, 20u8))
        .border(
            Border::new()
                .fill((r, g, b, 70u8))
                .width(1.)
                .alignment(BorderAlignment::Inner),
        )
        .child(icon(lucide::circle_alert(), c.error))
        .child(label().text(message).font_size(13.).color(c.error))
}
