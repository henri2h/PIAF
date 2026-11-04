use freya::prelude::*;
use freya_material_design::prelude::Ripple;

use super::HoverableExt;

/// Round icon button with hover and ripple feedback and an optional tooltip.
/// The press doesn't reach the parent (rows, bubbles).
pub struct IconButton {
    pub icon: Bytes,
    pub tooltip: Option<&'static str>,
    /// Diameter.
    pub size: f32,
    pub icon_size: f32,
    pub color: (u8, u8, u8),
    pub background: Option<(u8, u8, u8)>,
    pub on_press: EventHandler<()>,
}

impl IconButton {
    pub fn new(icon: Bytes, color: (u8, u8, u8), on_press: impl FnMut(()) + 'static) -> Self {
        Self {
            icon,
            tooltip: None,
            size: 32.,
            icon_size: 16.,
            color,
            background: None,
            on_press: EventHandler::new(on_press),
        }
    }

    pub fn tooltip(mut self, tooltip: &'static str) -> Self {
        self.tooltip = Some(tooltip);
        self
    }

    pub fn size(mut self, size: f32, icon_size: f32) -> Self {
        self.size = size;
        self.icon_size = icon_size;
        self
    }

    pub fn background(mut self, background: (u8, u8, u8)) -> Self {
        self.background = Some(background);
        self
    }
}

/// The handler is left out: buttons only re-render on what they show.
impl PartialEq for IconButton {
    fn eq(&self, other: &Self) -> bool {
        self.icon == other.icon
            && self.tooltip == other.tooltip
            && self.size == other.size
            && self.icon_size == other.icon_size
            && self.color == other.color
            && self.background == other.background
    }
}

impl Component for IconButton {
    fn render(&self) -> impl IntoElement {
        let on_press = self.on_press.clone();
        let size = Size::px(self.size);
        let button = rect()
            .width(size.clone())
            .height(size.clone())
            .maybe(self.background.is_some(), |r| {
                r.background(self.background.unwrap_or_default())
            })
            .on_press(move |e: Event<PressEventData>| {
                e.stop_propagation();
                on_press.call(());
            })
            .child(
                Ripple::new().color(self.color).expanded().child(
                    rect().center().expanded().child(
                        SvgViewer::new(self.icon.clone())
                            .color(self.color)
                            .width(Size::px(self.icon_size))
                            .height(Size::px(self.icon_size)),
                    ),
                ),
            )
            .hoverable(size.clone(), size, self.size / 2.);
        match self.tooltip {
            Some(text) => TooltipContainer::new(Tooltip::new_text(text))
                .position(AttachedPosition::Top)
                .child(button)
                .into_element(),
            None => button,
        }
    }
}
