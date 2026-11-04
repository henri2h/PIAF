use freya::prelude::*;

use super::HoverableExt;
use crate::utils::use_app_colors;

/// One list row: `leading` (avatar, icon), a headline and an optional
/// supporting line, `trailing` (icon, button, meta). The text takes the space
/// left and ends with an ellipsis, so it never runs under `trailing`.
/// Pressable when `on_press` is set.
pub struct ListItem {
    headline: Element,
    badge: Option<Element>,
    supporting: Option<String>,
    leading: Option<Element>,
    trailing: Option<Element>,
    on_press: Option<EventHandler<()>>,
}

impl ListItem {
    pub fn new(headline: impl Into<String>) -> Self {
        Self::with_headline(headline_label(headline.into()))
    }

    /// A custom headline (e.g. styled spans); keep it one line, ellipsized.
    pub fn with_headline(headline: impl IntoElement) -> Self {
        Self {
            headline: headline.into_element(),
            badge: None,
            supporting: None,
            leading: None,
            trailing: None,
            on_press: None,
        }
    }

    /// Small label after the headline, e.g. "Admin".
    pub fn badge(mut self, badge: impl IntoElement) -> Self {
        self.badge = Some(badge.into_element());
        self
    }

    pub fn supporting(mut self, supporting: impl Into<String>) -> Self {
        self.supporting = Some(supporting.into());
        self
    }

    pub fn leading(mut self, leading: impl IntoElement) -> Self {
        self.leading = Some(leading.into_element());
        self
    }

    pub fn trailing(mut self, trailing: impl IntoElement) -> Self {
        self.trailing = Some(trailing.into_element());
        self
    }

    pub fn on_press(mut self, on_press: impl FnMut(()) + 'static) -> Self {
        self.on_press = Some(EventHandler::new(on_press));
        self
    }
}

/// The handler is left out: rows only re-render on what they show.
impl PartialEq for ListItem {
    fn eq(&self, other: &Self) -> bool {
        self.headline == other.headline
            && self.badge == other.badge
            && self.supporting == other.supporting
            && self.leading == other.leading
            && self.trailing == other.trailing
            && self.on_press.is_some() == other.on_press.is_some()
    }
}

/// The default headline: one line, ellipsized, filling the text column.
fn headline_label(text: String) -> Label {
    label()
        .width(Size::fill())
        .text(text)
        .max_lines(1)
        .text_overflow(TextOverflow::Ellipsis)
        .font_size(15.)
        .font_weight(FontWeight::MEDIUM)
}

impl Component for ListItem {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let headline = rect()
            .horizontal()
            .width(Size::fill())
            .content(Content::Flex)
            .spacing(6.)
            .cross_align(Alignment::Center)
            .color(c.on_surface)
            .child(rect().width(Size::flex(1.)).child(self.headline.clone()))
            .maybe_child(self.badge.clone());
        let text = rect()
            .vertical()
            .width(Size::flex(1.))
            .spacing(2.)
            .child(headline)
            .maybe_child(self.supporting.clone().map(|supporting| {
                label()
                    .width(Size::fill())
                    .text(supporting)
                    .max_lines(1)
                    .text_overflow(TextOverflow::Ellipsis)
                    .font_size(13.)
                    .color(c.on_surface_variant)
            }));
        let row = rect()
            .horizontal()
            .width(Size::fill())
            .content(Content::Flex)
            .padding(Gaps::new(10., 16., 10., 16.))
            .spacing(12.)
            .cross_align(Alignment::Center)
            .maybe_child(self.leading.clone())
            .child(text)
            .maybe_child(self.trailing.clone());
        match self.on_press.clone() {
            Some(on_press) => {
                row.on_press(move |_| on_press.call(()))
                    .hoverable(Size::fill(), Size::auto(), 0.)
            }
            None => row.into_element(),
        }
    }
}

#[cfg(test)]
mod tests {
    use freya::prelude::*;
    use freya_testing::prelude::launch_test;

    use super::ListItem;

    /// A long headline and supporting line stop before the trailing element.
    #[test]
    fn long_text_stays_clear_of_trailing() {
        fn app() -> impl IntoElement {
            use_init_theme(light_theme);
            rect().width(Size::px(300.)).child(
                ListItem::new("A very long display name that does not fit in the row at all")
                    .supporting("@a.very.long.user.id:some-really-long-server.example.org")
                    .leading(rect().width(Size::px(40.)).height(Size::px(40.)))
                    .trailing(
                        rect()
                            .a11y_id(AccessibilityId(77))
                            .width(Size::px(24.))
                            .height(Size::px(24.)),
                    ),
            )
        }
        let mut test = launch_test(app);
        test.sync_and_update();
        let trailing_left = test
            .find(|node, element| {
                (node.layout().area.width() == 24.)
                    .then(|| node.layout().area.min_x())
                    .filter(|_| Rect::try_downcast(element).is_some())
            })
            .unwrap();
        let text_right = test
            .find_many(|node, element| {
                Label::try_downcast(element).map(|_| node.layout().area.max_x())
            })
            .into_iter()
            .fold(0f32, f32::max);
        assert!(
            text_right <= trailing_left,
            "text ends at {text_right}, trailing starts at {trailing_left}"
        );
    }
}
