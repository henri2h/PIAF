use std::sync::Arc;

use freya::prelude::*;
use matrix_sdk_ui::timeline::TimelineItem;

use super::focus::row_key;
use crate::ui::components::IconButton;
use crate::utils::use_app_colors;

const BUTTON: f32 = 44.;
const FLOATING_LAYER: i16 = 1000;

/// Scrolled this far above the latest message: the button shows.
fn shown(distance: f32, viewport: f32) -> bool {
    distance > viewport / 2.
}

/// Distance in px between the view and the timeline's end.
pub(super) fn distance_to_end(scroll: ScrollController, content: f32, viewport: f32) -> f32 {
    let (_, y) = Into::<(i32, i32)>::into(scroll);
    let max = (content - viewport).max(0.);
    max + y as f32
}

/// Round button over the timeline's corner while scrolled up, with how many
/// messages from others arrived since; scrolls to the end. Its own
/// component: it re-renders on every scroll step.
#[derive(PartialEq)]
pub(super) struct JumpToLatest {
    pub scroll: ScrollController,
    pub content_height: State<f32>,
    pub viewport_height: State<f32>,
    pub messages: State<Vec<Arc<TimelineItem>>>,
    pub my_user_id: Option<String>,
}

impl Component for JumpToLatest {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut scroll = self.scroll;
        let (content, viewport) = (*self.content_height.read(), *self.viewport_height.read());
        let distance = distance_to_end(scroll, content, viewport);
        // The latest message seen: the last one, while at the end. By key,
        // as older pages load in front of it.
        let last_key = self.messages.read().last().map(|item| row_key(item));
        let mut seen = use_state(|| last_key.clone());
        let at_end = distance < 24.;
        use_side_effect_with_deps(&(at_end, last_key), move |(at_end, last_key)| {
            if *at_end && *seen.peek() != *last_key {
                seen.set(last_key.clone());
            }
        });
        let unread = {
            let messages = self.messages.read();
            let seen = seen.read();
            let from = messages
                .iter()
                .rposition(|item| Some(row_key(item)) == *seen)
                .map_or(messages.len(), |i| i + 1);
            messages[from..]
                .iter()
                .filter_map(|item| item.as_event())
                .filter(|e| self.my_user_id.as_deref() != Some(e.sender().as_str()))
                .filter(|e| e.content().as_msglike().is_some())
                .count()
        };
        if !shown(distance, viewport) {
            return rect().into_element();
        }
        let button = rect()
            .corner_radius(BUTTON / 2.)
            .shadow(Shadow::new().y(2.).blur(6.).color((0, 0, 0, 60)))
            .child(
                IconButton::new(
                    freya_icons::lucide::chevron_down(),
                    c.on_surface,
                    // At the next layout, from the real content height (rows
                    // may have grown since this render).
                    move |_| scroll.scroll_to(ScrollPosition::End, Direction::Vertical),
                )
                .tooltip("Jump to latest")
                .background(c.surface_container_high)
                .size(BUTTON, 22.),
            );
        // Over the button's top right corner.
        let badge = (unread > 0).then(|| {
            rect()
                .position(Position::new_absolute().top(-6.).right(-6.))
                .layer(1)
                .min_width(Size::px(20.))
                .height(Size::px(20.))
                .padding(Gaps::new(0., 6., 0., 6.))
                .center()
                .corner_radius(10.)
                .background(c.primary)
                .child(
                    label()
                        .text(if unread > 99 {
                            "99+".to_string()
                        } else {
                            unread.to_string()
                        })
                        .font_size(11.)
                        .font_weight(FontWeight::BOLD)
                        .color(c.on_primary),
                )
        });
        rect()
            .position(Position::new_absolute().bottom(12.).right(12.))
            // Layers add up with nesting: above everything inside the rows.
            .layer(FLOATING_LAYER)
            .child(button)
            .maybe_child(badge)
            .into_element()
    }
}

#[cfg(test)]
mod tests {
    use super::shown;

    #[test]
    fn shows_after_half_a_screen() {
        assert!(!shown(100., 600.));
        assert!(shown(400., 600.));
    }
}
