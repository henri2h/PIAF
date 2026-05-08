use freya::prelude::*;
use freya_material_design::prelude::Ripple;
use matrix_sdk::Room;

use crate::utils::use_app_colors;

// ---------------------------------------------------------------------------
// RoomFilter
// ---------------------------------------------------------------------------

#[derive(Clone, PartialEq, Debug)]
pub enum RoomFilter {
    All,
    Groups,
    Dms,
    Unread,
}

impl RoomFilter {
    pub fn label(&self) -> &'static str {
        match self {
            Self::All => "All",
            Self::Groups => "Groups",
            Self::Dms => "DMs",
            Self::Unread => "Unread",
        }
    }

    pub fn matches(&self, room: &Room) -> bool {
        match self {
            Self::All => true,
            Self::Groups => !room.is_dm(),
            Self::Dms => room.is_dm(),
            Self::Unread => room.num_unread_messages() > 0 || room.num_unread_notifications() > 0,
        }
    }
}

// ---------------------------------------------------------------------------
// FilterChip — Signal-style compact pill
// ---------------------------------------------------------------------------

pub struct FilterChip {
    pub chip_label: &'static str,
    pub selected: bool,
    pub filter: State<RoomFilter>,
    pub value: RoomFilter,
}

impl PartialEq for FilterChip {
    fn eq(&self, other: &Self) -> bool {
        self.chip_label == other.chip_label && self.selected == other.selected
    }
}

impl Component for FilterChip {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut filter = self.filter;
        let selected = self.selected;
        let chip_label = self.chip_label;
        let value = self.value.clone();

        // Selected: filled primary pill. Unselected: subtle surface_container pill, no border.
        let bg = if selected {
            c.primary
        } else {
            c.surface_container
        };
        let text_color = if selected {
            c.on_primary
        } else {
            c.on_surface_variant
        };

        rect()
            .width(Size::flex(1.0))
            .height(Size::px(30.))
            .corner_radius(15.)
            .background(bg)
            .on_press(move |_| {
                *filter.write() = value.clone();
            })
            .overflow(Overflow::Clip)
            .child(
                Ripple::new()
                    .color(if selected { (255, 255, 255) } else { c.primary })
                    .width(Size::fill_minimum())
                    .height(Size::fill())
                    .child(
                        rect()
                            .horizontal()
                            .height(Size::fill())
                            .padding(Gaps::new(0., 14., 0., 14.))
                            .cross_align(Alignment::Center)
                            .child(
                                label()
                                    .text(chip_label)
                                    .font_size(13.)
                                    .font_weight(FontWeight::MEDIUM)
                                    .color(text_color),
                            ),
                    ),
            )
    }
}
