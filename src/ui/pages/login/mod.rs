mod field;
mod user_id;

use std::time::Duration;

use freya::prelude::*;

use crate::ui::components::{
    AUTH_SHORT_MAX_HEIGHT, AUTH_WIDE_MIN_WIDTH, IconButton, brand_hero, brand_logo,
};

use freya_icons::lucide;
use freya_material_design::prelude::ButtonRippleExt;
use freya_router::prelude::RouterContext;

use crate::utils::const_values::AppColors;
use crate::utils::insets::status_bar_inset;
use crate::utils::use_app_colors;
use crate::{REQUESTER, Route};
use field::{field, icon};
use user_id::normalize_user_id;

const FORM_MAX_WIDTH: f32 = 400.;
/// Typing pause before the server in the user ID is looked up.
const SERVER_CHECK_DELAY: Duration = Duration::from_millis(600);

/// Lookup of the server in the user ID, shown under the field.
#[derive(Clone, PartialEq)]
enum ServerCheck {
    None,
    Checking(String),
    Found(String),
    NotFound(String),
}

impl ServerCheck {
    fn server(&self) -> Option<&str> {
        match self {
            Self::None => None,
            Self::Checking(s) | Self::Found(s) | Self::NotFound(s) => Some(s),
        }
    }
}

#[derive(PartialEq)]
pub struct LoginPage {}

impl Component for LoginPage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut size = use_state(|| (0.0f32, 0.0f32));
        let login = use_state(String::new);
        let password = use_state(String::new);
        let mut show_password = use_state(|| false);
        let mut error: State<Option<String>> = use_state(|| None);
        let mut logging_in = use_state(|| false);
        let user_a11y = use_a11y();
        let password_a11y = use_a11y();
        let user_focus = use_focus(user_a11y);
        let password_focus = use_focus(password_a11y);
        let mut server_check = use_state(|| ServerCheck::None);

        // Looks the server up once typing pauses; a newer server supersedes it.
        use_side_effect(move || {
            let server = normalize_user_id(&login.read())
                .and_then(|id| id.split_once(':').map(|(_, s)| s.to_string()));
            let Some(server) = server else {
                if *server_check.peek() != ServerCheck::None {
                    server_check.set(ServerCheck::None);
                }
                return;
            };
            if server_check.peek().server() == Some(server.as_str()) {
                return;
            }
            server_check.set(ServerCheck::Checking(server.clone()));
            spawn(async move {
                timer(SERVER_CHECK_DELAY).await;
                if *server_check.peek() != ServerCheck::Checking(server.clone()) {
                    return;
                }
                let lookup = server.clone();
                let found = crate::utils::on_tokio(async move {
                    crate::utils::matrix::homeserver_exists(&lookup).await
                })
                .await
                .unwrap_or(false);
                if *server_check.peek() == ServerCheck::Checking(server.clone()) {
                    server_check.set(if found {
                        ServerCheck::Found(server)
                    } else {
                        ServerCheck::NotFound(server)
                    });
                }
            });
        });

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

        let user_helper = match (&user_id, server_check.read().clone()) {
            (Some(_), ServerCheck::Checking(server)) => {
                Some((format!("Checking {server}…"), c.on_surface_muted))
            }
            (Some(_), ServerCheck::Found(server)) => {
                Some((format!("✓ Server found: {server}"), c.status_online))
            }
            (Some(_), ServerCheck::NotFound(server)) => {
                Some((format!("No Matrix server found at {server}"), c.error))
            }
            (Some(_), ServerCheck::None) => None,
            (None, _) if !login.read().trim().is_empty() => Some((
                "Include your server, e.g. @you:matrix.org".into(),
                c.on_surface_muted,
            )),
            (None, _) => None,
        };

        let hidden = !*show_password.read();
        let eye_toggle = IconButton::new(
            if hidden {
                lucide::eye()
            } else {
                lucide::eye_off()
            },
            c.on_surface_variant,
            move |_| show_password.toggle(),
        )
        .tooltip(if hidden {
            "Show password"
        } else {
            "Hide password"
        })
        .size(32., 18.)
        .into_element();

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
                    .a11y_id(user_a11y)
                    .leading(icon(lucide::at_sign(), c.on_surface_muted))
                    // Enter moves on to the password, as Tab does.
                    .on_submit(move |_| password_a11y.request_focus()),
                user_focus() != Focus::Not,
                None,
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
                    .a11y_id(password_a11y)
                    .leading(icon(lucide::lock(), c.on_surface_muted))
                    .on_submit(move |_| submit()),
                password_focus() != Focus::Not,
                Some(eye_toggle),
                None,
            ))
            .maybe_child(error.read().clone().map(|msg| error_box(c, msg)))
            .child(
                Button::new()
                    .filled()
                    .expanded()
                    .width(Size::fill())
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

        let (width, height) = *size.read();
        let is_wide = width >= AUTH_WIDE_MIN_WIDTH;
        let is_short = height > 0. && height < AUTH_SHORT_MAX_HEIGHT;
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
                        .vertical()
                        .width(Size::flex(1.))
                        .height(Size::fill())
                        .content(Content::Flex)
                        .child(top_bar(c))
                        // Centered; scrolls from the top when too short for it.
                        .child(if is_short {
                            ScrollView::new()
                                .width(Size::fill())
                                .height(Size::flex(1.))
                                .child(
                                    rect()
                                        .width(Size::fill())
                                        .cross_align(Alignment::Center)
                                        .padding(Gaps::new(8., 48., 24., 48.))
                                        .child(form),
                                )
                                .into_element()
                        } else {
                            rect()
                                .width(Size::fill())
                                .height(Size::flex(1.))
                                .center()
                                .padding(Gaps::new_symmetric(24., 48.))
                                .child(form)
                                .into_element()
                        }),
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
                                .child(brand_mark(is_short))
                                .child(form),
                        ),
                )
                .into_element()
        };

        rect()
            .expanded()
            .background(c.surface)
            .on_sized(move |e: Event<SizedEventData>| {
                let area = (e.area.width(), e.area.height());
                if *size.peek() != area {
                    size.set(area);
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
        .padding(Gaps::new(status_bar_inset() + 8., 8., 0., 8.))
        .maybe_child(can_go_back.then(|| {
            IconButton::new(lucide::arrow_left(), c.on_surface, |_| {
                crate::app::navigation::go_back_or_home()
            })
            .size(40., 18.)
        }))
}

/// Narrow layout: the logo, centered above the form.
fn brand_mark(short: bool) -> Rect {
    rect()
        .width(Size::fill())
        .max_width(Size::px(FORM_MAX_WIDTH))
        .cross_align(Alignment::Center)
        .child(brand_logo(if short { 64. } else { 96. }))
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
