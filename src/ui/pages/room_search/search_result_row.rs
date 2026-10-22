use freya::prelude::*;

use crate::app::navigation::navigate_to_room_at_event;
use crate::ui::components::{Avatar, ListItem};
use crate::ui::pages::home::search::find_match;
use crate::utils::avatars::AvatarSource;
use crate::utils::room_search::Hit;
use crate::utils::{format_timestamp, id_color, use_app_colors};

/// One matching message: its text (the match in bold), sender and time; a tap
/// opens the room at it.
#[derive(PartialEq)]
pub struct SearchResultRow {
    pub room_id: String,
    pub hit: Hit,
    pub query: String,
}

impl Component for SearchResultRow {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let hit = &self.hit;
        let body = hit.body.replace('\n', " ");
        let text = match find_match(&body, &self.query) {
            Some((start, end)) => paragraph()
                .span(Span::new(body[..start].to_string()))
                .span(Span::new(body[start..end].to_string()).font_weight(FontWeight::BOLD))
                .span(Span::new(body[end..].to_string())),
            None => paragraph().span(body.clone()),
        }
        .width(Size::fill())
        .max_lines(2)
        .text_overflow(TextOverflow::Ellipsis)
        .font_size(15.)
        .color(c.on_surface);

        let sender = hit.sender.to_string();
        let (room_id, event_id) = (self.room_id.clone(), hit.event_id.to_string());
        ListItem::with_headline(text)
            .supporting(format!(
                "{} · {}",
                hit.sender_name,
                format_timestamp(hit.ts)
            ))
            .leading(Avatar {
                size: 40.,
                source: Some(AvatarSource::member(&self.room_id, &sender)),
                name: hit.sender_name.clone(),
                color: id_color(&sender),
            })
            .on_press(move |_| navigate_to_room_at_event(room_id.clone(), event_id.clone()))
    }
}
