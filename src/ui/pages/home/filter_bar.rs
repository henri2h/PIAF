use freya::prelude::*;

use super::filter_chip::FilterChip;
use super::room_list_model::RoomFilter;
use crate::utils::use_app_colors;

/// Horizontal row of room filter chips, each sized to its label.
pub struct RoomFilterBar {
    pub filter: State<RoomFilter>,
}

impl PartialEq for RoomFilterBar {
    fn eq(&self, _: &Self) -> bool {
        false
    }
}

impl Component for RoomFilterBar {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let filter = self.filter;

        let mut row = rect()
            .horizontal()
            .width(Size::fill())
            .padding(Gaps::new(6., 16., 6., 16.))
            .spacing(6.)
            .background(c.surface);
        for f in &RoomFilter::ALL {
            let is_selected = *filter.read() == *f;
            row = row.child(FilterChip {
                chip_label: f.label(),
                selected: is_selected,
                filter,
                value: f.clone(),
            });
        }
        row
    }
}
