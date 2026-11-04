use std::time::Duration;

use freya::prelude::*;

use super::use_fading;
use crate::utils::use_app_colors;

const SHOWN_FOR: Duration = Duration::from_secs(4);

/// A short message on a dark pill, cleared after a few seconds. Place it
/// where it should appear (e.g. above a composer).
#[derive(PartialEq)]
pub struct Snackbar {
    pub message: State<Option<String>>,
}

impl Component for Snackbar {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut message = self.message;
        let current = message.read().clone();
        use_side_effect_with_deps(&current, move |shown| {
            let Some(shown) = shown.clone() else { return };
            spawn(async move {
                timer(SHOWN_FOR).await;
                // Not if a newer message replaced it meanwhile.
                if message.peek().as_ref() == Some(&shown) {
                    message.set(None);
                }
            });
        });
        let fading = use_fading(current, 150);
        rect()
            .width(Size::fill())
            .center()
            .maybe_child(fading.map(|(text, opacity)| {
                rect()
                    .opacity(opacity)
                    .margin(Gaps::new(4., 16., 4., 16.))
                    .padding(Gaps::new(10., 16., 10., 16.))
                    .corner_radius(8.)
                    .background(c.on_surface)
                    .child(label().text(text).font_size(14.).color(c.surface))
            }))
    }
}
