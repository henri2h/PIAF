use std::collections::HashMap;

use freya::prelude::*;

use super::message_row::MessageRow;
use crate::utils::use_app_colors;

/// One measured row of the timeline. A component, so a timeline update
/// rebuilds only the rows whose props changed.
#[derive(PartialEq)]
pub(super) struct TimelineRow {
    pub row_key: String,
    pub highlighted: bool,
    pub heights: State<HashMap<String, f32>>,
    pub row: MessageRow,
}

impl Component for TimelineRow {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let key = self.row_key.clone();
        let mut heights = self.heights;
        rect()
            .width(Size::fill())
            .maybe(self.highlighted, |r| r.background(c.primary_container))
            .on_sized(move |e: Event<SizedEventData>| {
                let h = e.area.height();
                if heights.peek().get(&key) != Some(&h) {
                    heights.write().insert(key.clone(), h);
                }
            })
            .child(self.row.clone())
    }
}
