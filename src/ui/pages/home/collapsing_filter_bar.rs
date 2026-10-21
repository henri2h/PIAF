use freya::prelude::*;

use super::filter_bar::RoomFilterBar;
use super::room_list_model::{Mailbox, RoomFilter};

/// The filter bar overlaid on top of the room list, pushed up by `hidden`
/// pixels as the list scrolls down (see `RoomList`). Moving with the scroll
/// instead of appearing and disappearing keeps the list from jumping.
#[derive(PartialEq)]
pub struct CollapsingFilterBar {
    pub hidden: State<f32>,
    /// The list is scrolled under the bars: tinted surface, like the app bar.
    pub tinted: State<bool>,
    pub mailbox: State<Mailbox>,
    pub filter: State<RoomFilter>,
}

impl Component for CollapsingFilterBar {
    fn render(&self) -> impl IntoElement {
        let c = crate::utils::use_app_colors();
        let tinted = *self.tinted.read();
        rect()
            .position(Position::new_absolute().top(0.).left(0.))
            // Layers grow by one per nesting level, so the list rows sit far
            // above this shallow bar: jump past them (below overlays), like the FAB.
            .layer(1000)
            .width(Size::fill())
            .offset_y(-*self.hidden.read())
            .child(RoomFilterBar {
                mailbox: self.mailbox,
                filter: self.filter,
                tinted,
            })
            // Hairline separating the bar from rows scrolled under it.
            .maybe_child(tinted.then(|| {
                rect()
                    .width(Size::fill())
                    .height(Size::px(1.))
                    .background(c.outline_variant_light)
            }))
    }
}
