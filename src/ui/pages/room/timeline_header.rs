use freya::prelude::*;

use super::room_start_banner::RoomStartBanner;
use super::use_room_timeline::TimelineState;
use crate::utils::use_app_colors;

/// Above the messages: the room's start banner, else a loader while a page
/// loads. Its own component so a page starting or ending doesn't re-render
/// the whole timeline.
#[derive(PartialEq)]
pub(super) struct TimelineHeader {
    pub room_id: String,
    pub state: TimelineState,
}

impl Component for TimelineHeader {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let st = self.state;
        if *st.at_start.read() {
            return RoomStartBanner {
                room_id: self.room_id.clone(),
                room_name: st.room_name.read().clone(),
                c,
            }
            .into_element();
        }
        rect()
            .center()
            .width(Size::fill())
            .padding(Gaps::new_all(8.))
            .maybe_child(st.paginating.read().then(CircularLoader::new))
            .into_element()
    }
}
