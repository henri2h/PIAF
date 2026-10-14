use std::sync::Arc;

use freya::prelude::*;

use crate::ui::components::IconButton;

use crate::utils::avatars::AvatarSource;

use crate::ui::components::Avatar;
use crate::utils::const_values::STATUS_BAR_INSET;
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
    },
    /// Replaces the title with an inline search input (MD3 search bar).
    SearchInput {
        state: State<String>,
        placeholder: &'static str,
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

pub struct TopAppBar {
    pub title: TopAppBarTitle,
    /// If `Some`, a leading back-arrow button is shown.
    pub on_back: Option<Arc<dyn Fn()>>,
    /// Trailing action buttons, rendered right-to-left (first = rightmost).
    pub actions: Vec<TopAppBarAction>,
}

impl PartialEq for TopAppBar {
    fn eq(&self, other: &Self) -> bool {
        self.title == other.title && self.on_back.is_some() == other.on_back.is_some()
    }
}

impl Component for TopAppBar {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
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
            } => rect()
                .horizontal()
                .spacing(10.)
                .cross_align(Alignment::Center)
                .child(Avatar {
                    size: 36.,
                    source: Some(AvatarSource::Room(room_id.clone())),
                    name: name.clone(),
                    color,
                })
                .child(
                    label()
                        .text(name)
                        .font_size(18.)
                        .font_weight(FontWeight::MEDIUM)
                        .color(c.on_surface),
                )
                .into_element(),
            TopAppBarTitle::SearchInput { state, placeholder } => rect()
                .horizontal()
                .width(Size::flex(1.0))
                .height(Size::px(40.))
                .corner_radius(20.)
                .background(c.surface_container)
                .padding(Gaps::new(0., 12., 0., 12.))
                .cross_align(Alignment::Center)
                .spacing(6.)
                .child(
                    SvgViewer::new(freya_icons::lucide::search())
                        .color(c.on_surface_variant)
                        .width(Size::px(18.))
                        .height(Size::px(18.)),
                )
                .child(
                    Input::new(state)
                        .flat()
                        .placeholder(placeholder)
                        .width(Size::fill()),
                )
                .into_element(),
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
            .background(c.surface)
            // Status-bar spacer (non-zero only on Android)
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::px(STATUS_BAR_INSET)),
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
                    .child(rect().width(Size::flex(1.0)))
                    .children(trailing),
            )
    }
}
