use freya::prelude::*;

use crate::utils::use_app_colors;

/// Hover feedback for anything pressable: tints `child` with a translucent
/// state layer while the pointer is over it. The layer ignores pointer
/// events, so presses still reach `child`. Give it the child's size and
/// corner radius.
#[derive(PartialEq)]
pub struct Hoverable {
    pub width: Size,
    pub height: Size,
    pub corner_radius: f32,
    pub child: Element,
}

impl Hoverable {
    pub fn new(child: impl IntoElement) -> Self {
        Self {
            width: Size::auto(),
            height: Size::auto(),
            corner_radius: 0.,
            child: child.into_element(),
        }
    }

    pub fn width(mut self, width: Size) -> Self {
        self.width = width;
        self
    }

    pub fn height(mut self, height: Size) -> Self {
        self.height = height;
        self
    }

    pub fn corner_radius(mut self, corner_radius: f32) -> Self {
        self.corner_radius = corner_radius;
        self
    }
}

impl Component for Hoverable {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut hovered = use_state(|| false);
        let (r, g, b) = c.on_surface;
        rect()
            .width(self.width.clone())
            .height(self.height.clone())
            .corner_radius(self.corner_radius)
            .overflow(Overflow::Clip)
            .on_pointer_enter(move |_| hovered.set(true))
            .on_pointer_leave(move |_| hovered.set(false))
            .child(self.child.clone())
            .maybe_child(hovered.read().then(|| {
                rect()
                    .position(Position::new_absolute().top(0.).left(0.))
                    .width(Size::fill())
                    .height(Size::fill())
                    .corner_radius(self.corner_radius)
                    .background((r, g, b, 20))
                    .interactive(false)
            }))
    }
}

/// `rect()...on_press(..).hoverable(w, h, radius)`: wraps in a [`Hoverable`]
/// of the same size and corner radius.
pub trait HoverableExt: IntoElement + Sized {
    fn hoverable(self, width: Size, height: Size, corner_radius: f32) -> Element {
        Hoverable::new(self)
            .width(width)
            .height(height)
            .corner_radius(corner_radius)
            .into_element()
    }
}

impl<T: IntoElement> HoverableExt for T {}
