use freya::prelude::*;

use crate::ui::components::use_fading;
use crate::utils::use_app_colors;

/// "Ann is typing…" above the composer; its own component so typing
/// updates don't re-render the room.
#[derive(PartialEq)]
pub(super) struct TypingIndicator {
    pub users: State<Vec<String>>,
}

impl Component for TypingIndicator {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let typing = use_fading(typing_label(&self.users.read()), 150);
        rect()
            .width(Size::fill())
            .maybe_child(typing.map(|(text, opacity)| {
                rect()
                    .opacity(opacity)
                    .width(Size::fill())
                    .padding(Gaps::new(2., 16., 2., 16.))
                    .child(
                        label()
                            .text(text)
                            .max_lines(1)
                            .text_overflow(TextOverflow::Ellipsis)
                            .font_size(12.)
                            .color(c.on_surface_variant),
                    )
            }))
    }
}

fn typing_label(users: &[String]) -> Option<String> {
    match users {
        [] => None,
        [a] => Some(format!("{a} is typing…")),
        [a, b] => Some(format!("{a} and {b} are typing…")),
        _ => Some("Several people are typing…".to_string()),
    }
}
