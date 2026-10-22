use freya::animation::*;
use freya::prelude::*;
use freya_material_design::prelude::Ripple;

use super::HoverableExt;
use crate::utils::const_values::AppColors;
use crate::utils::haptics::{self, Haptic};
use crate::utils::use_app_colors;

/// Pill toggle for filters, tabs and option pickers: filled primary when
/// selected, its colours easing on change.
pub struct Chip {
    pub label: String,
    pub icon: Option<Bytes>,
    pub selected: bool,
    /// `Size::auto()` sizes the chip to its label.
    pub width: Size,
    pub height: f32,
    pub on_press: EventHandler<()>,
}

impl Chip {
    pub fn new(
        label: impl Into<String>,
        selected: bool,
        on_press: impl FnMut(()) + 'static,
    ) -> Self {
        Self {
            label: label.into(),
            icon: None,
            selected,
            width: Size::auto(),
            height: 30.,
            on_press: EventHandler::new(on_press),
        }
    }

    pub fn icon(mut self, icon: Bytes) -> Self {
        self.icon = Some(icon);
        self
    }

    pub fn width(mut self, width: Size) -> Self {
        self.width = width;
        self
    }

    pub fn height(mut self, height: f32) -> Self {
        self.height = height;
        self
    }
}

/// The handler is left out: chips only re-render on what they show.
impl PartialEq for Chip {
    fn eq(&self, other: &Self) -> bool {
        self.label == other.label
            && self.icon == other.icon
            && self.selected == other.selected
            && self.width == other.width
            && self.height == other.height
    }
}

fn colors(c: AppColors, selected: bool) -> ((u8, u8, u8), (u8, u8, u8)) {
    if selected {
        (c.primary_container, c.on_primary_container)
    } else {
        (c.surface_container, c.on_surface_variant)
    }
}

impl Component for Chip {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let selected = self.selected;
        let animation = use_animation_with_dependencies(&(selected, c), |conf, &(selected, c)| {
            conf.on_creation(OnCreation::Finish);
            conf.on_change(OnChange::Rerun);
            let (from_bg, from_fg) = colors(c, !selected);
            let (to_bg, to_fg) = colors(c, selected);
            (
                AnimColor::new(from_bg, to_bg).time(150).ease(Ease::Out),
                AnimColor::new(from_fg, to_fg).time(150).ease(Ease::Out),
            )
        });
        let (bg, fg) = {
            let values = animation.get();
            (values.0.value(), values.1.value())
        };
        let on_press = self.on_press.clone();
        let inner_width = if self.width == Size::auto() {
            Size::auto()
        } else {
            Size::fill()
        };
        let radius = self.height / 2.;

        rect()
            .width(inner_width.clone())
            .height(Size::fill())
            .background(bg)
            .on_press(move |_| {
                haptics::play(Haptic::Click);
                on_press.call(())
            })
            .child(
                Ripple::new()
                    .color(c.primary)
                    .width(inner_width.clone())
                    .height(Size::fill())
                    .child(
                        rect()
                            .horizontal()
                            .width(inner_width)
                            .height(Size::fill())
                            .main_align(Alignment::Center)
                            .cross_align(Alignment::Center)
                            .padding(Gaps::new(0., 14., 0., 14.))
                            .spacing(6.)
                            // Selected and no icon of its own: a check, like Material filter chips.
                            .maybe_child(
                                self.icon
                                    .clone()
                                    .or_else(|| selected.then(freya_icons::lucide::check))
                                    .map(|icon| {
                                        SvgViewer::new(icon)
                                            .color(fg)
                                            .width(Size::px(15.))
                                            .height(Size::px(15.))
                                    }),
                            )
                            .child(
                                // One line at its full width: in a scrolling row the
                                // space left would otherwise wrap it.
                                label()
                                    .text(self.label.clone())
                                    .max_lines(1)
                                    .font_size(13.)
                                    .font_weight(FontWeight::MEDIUM)
                                    .color(fg),
                            ),
                    ),
            )
            .hoverable(self.width.clone(), Size::px(self.height), radius)
    }
}
