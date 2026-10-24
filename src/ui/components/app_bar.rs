use std::sync::Arc;

use freya::prelude::*;

use super::HoverableExt;
use super::use_color_transition;

use crate::ui::components::IconButton;

use crate::utils::avatars::AvatarSource;

use crate::ui::components::Avatar;
use crate::utils::insets::status_bar_inset;
use crate::utils::use_app_colors;

// MD3 Small Top App Bar constants
const HEIGHT: f32 = 64.;
const ICON_SIZE: f32 = 24.;
const BTN_SIZE: f32 = 48.;

// ---------------------------------------------------------------------------
// TopAppBarTitle
// ---------------------------------------------------------------------------

#[derive(Clone)]
pub enum TopAppBarTitle {
    Text(String),
    /// Avatar + name — shares fetch logic with RoomListItem via `fetch_key`.
    Room {
        name: String,
        room_id: String,
        color: (u8, u8, u8),
        /// Tapping the avatar and name (opens the room's info).
        on_press: Option<Arc<dyn Fn()>>,
    },
}

impl PartialEq for TopAppBarTitle {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::Text(a), Self::Text(b)) => a == b,
            (
                Self::Room {
                    name: a,
                    room_id: ra,
                    ..
                },
                Self::Room {
                    name: b,
                    room_id: rb,
                    ..
                },
            ) => a == b && ra == rb,
            _ => false,
        }
    }
}

// ---------------------------------------------------------------------------
// TopAppBarAction
// ---------------------------------------------------------------------------

pub enum TopAppBarAction {
    /// Standard icon button (SVG bytes + callback).
    IconButton {
        icon: Bytes,
        on_press: Arc<dyn Fn()>,
    },
}

impl Clone for TopAppBarAction {
    fn clone(&self) -> Self {
        match self {
            Self::IconButton { icon, on_press } => Self::IconButton {
                icon: icon.clone(),
                on_press: Arc::clone(on_press),
            },
        }
    }
}

impl PartialEq for TopAppBarAction {
    fn eq(&self, _: &Self) -> bool {
        false
    }
}

// ---------------------------------------------------------------------------
// TopAppBar
// ---------------------------------------------------------------------------

/// Provided by a page whose content scrolls under its [`TopAppBar`]: `true`
/// while it does, and the bar takes the tinted surface.
#[derive(Clone, Copy)]
pub struct AppBarTint(pub State<bool>);

/// Provides [`AppBarTint`]: on while `scroll` is away from its top.
pub fn use_app_bar_tint(scroll: ScrollController) {
    let mut tint = use_state(|| false);
    use_provide_context(|| AppBarTint(tint));
    use_side_effect(move || {
        let (_, y): (i32, i32) = scroll.into();
        let scrolled_under = y < -1;
        if *tint.peek() != scrolled_under {
            tint.set(scrolled_under);
        }
    });
}

pub struct TopAppBar {
    pub title: TopAppBarTitle,
    /// If `Some`, a leading back-arrow button is shown.
    pub on_back: Option<Arc<dyn Fn()>>,
    /// Trailing action buttons, rendered right-to-left (first = rightmost).
    pub actions: Vec<TopAppBarAction>,
}

impl TopAppBar {
    /// A page's bar: `title` and a back button ([`go_back_or_home`]).
    ///
    /// [`go_back_or_home`]: crate::app::navigation::go_back_or_home
    pub fn new(title: impl Into<String>) -> Self {
        Self {
            title: TopAppBarTitle::Text(title.into()),
            on_back: Some(Arc::new(crate::app::navigation::go_back_or_home)),
            actions: vec![],
        }
    }

    pub fn action(mut self, icon: Bytes, on_press: impl Fn() + 'static) -> Self {
        self.actions.push(TopAppBarAction::IconButton {
            icon,
            on_press: Arc::new(on_press),
        });
        self
    }
}

impl PartialEq for TopAppBar {
    fn eq(&self, other: &Self) -> bool {
        self.title == other.title && self.on_back.is_some() == other.on_back.is_some()
    }
}

impl Component for TopAppBar {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let tinted = try_consume_context::<AppBarTint>().is_some_and(|tint| *tint.0.read());
        let background = use_color_transition(
            if tinted {
                c.surface_container
            } else {
                c.surface
            },
            200,
        );
        let on_back = self.on_back.clone();
        let actions = self.actions.clone();

        let leading = if let Some(cb) = on_back {
            IconButton::new(
                freya_icons::lucide::arrow_left(),
                c.on_surface_variant,
                move |_| {
                    cb();
                },
            )
            .size(BTN_SIZE, ICON_SIZE)
            .into_element()
        } else {
            // No back button: add a 12px start inset so the title aligns nicely.
            rect().width(Size::px(12.)).into_element()
        };

        // A tappable room title takes the space up to the actions.
        let title_fills = matches!(
            &self.title,
            TopAppBarTitle::Room {
                on_press: Some(_),
                ..
            }
        );
        let title_el = match self.title.clone() {
            TopAppBarTitle::Text(t) => label()
                .text(t)
                .font_size(22.)
                .font_weight(FontWeight::MEDIUM)
                .color(c.on_surface)
                .into_element(),
            TopAppBarTitle::Room {
                name,
                room_id,
                color,
                on_press,
            } => {
                let title = rect()
                    .horizontal()
                    .content(Content::Flex)
                    .spacing(10.)
                    .padding(Gaps::new(6., 8., 6., 4.))
                    .cross_align(Alignment::Center)
                    .child(Avatar {
                        size: 36.,
                        source: Some(AvatarSource::Room(room_id.clone())),
                        name: name.clone(),
                        color,
                    })
                    .child(
                        label()
                            .width(Size::flex(1.))
                            .text(name)
                            .max_lines(1)
                            .text_overflow(TextOverflow::Ellipsis)
                            .font_size(18.)
                            .font_weight(FontWeight::MEDIUM)
                            .color(c.on_surface),
                    );
                match on_press {
                    Some(on_press) => title
                        .width(Size::fill())
                        .on_press(move |_| on_press())
                        .hoverable(Size::flex(1.), Size::px(48.), 12.),
                    None => title.into_element(),
                }
            }
        };

        let trailing: Vec<Element> = actions
            .into_iter()
            .map(|action| match action {
                TopAppBarAction::IconButton { icon, on_press } => {
                    IconButton::new(icon, c.on_surface_variant, move |_| on_press())
                        .size(BTN_SIZE, ICON_SIZE)
                        .into_element()
                }
            })
            .collect();

        rect()
            .vertical()
            .width(Size::fill())
            .background(background)
            // Status-bar spacer (non-zero only on Android)
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::px(status_bar_inset())),
            )
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .content(Content::Flex)
                    .height(Size::px(HEIGHT))
                    .cross_align(Alignment::Center)
                    .padding(Gaps::new(0., 4., 0., 0.))
                    .child(leading)
                    .child(title_el)
                    .maybe_child((!title_fills).then(|| rect().width(Size::flex(1.0))))
                    .children(trailing),
            )
    }
}
