use freya::prelude::*;

use crate::ui::components::HoverableExt;
use crate::utils::{extract_urls, use_app_colors};

const COLLAPSED_LINES: usize = 3;
/// Longer topics (or more lines) get a "More" toggle.
const LONG_TOPIC_CHARS: usize = 140;

/// The room topic: links highlighted, clamped to a few lines until expanded,
/// then one tappable row per link.
#[derive(PartialEq)]
pub(super) struct RoomTopic {
    pub topic: String,
}

impl Component for RoomTopic {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut expanded = use_state(|| false);
        let is_expanded = *expanded.read();
        let urls = extract_urls(&self.topic);
        let long = self.topic.chars().count() > LONG_TOPIC_CHARS
            || self.topic.lines().count() > COLLAPSED_LINES;

        let text = topic_spans(&self.topic, &urls)
            .into_iter()
            .fold(paragraph(), |p, (text, is_url)| {
                let span = Span::new(text);
                p.span(if is_url { span.color(c.primary) } else { span })
            })
            .width(Size::fill())
            .font_size(14.)
            .color(c.on_surface_variant)
            .text_align(TextAlign::Center)
            // Skia's ellipsis without a line limit cuts to one line.
            .maybe(long && !is_expanded, |p| {
                p.max_lines(COLLAPSED_LINES)
                    .text_overflow(TextOverflow::Ellipsis)
            });

        rect()
            .vertical()
            .width(Size::fill())
            .padding(Gaps::new(4., 0., 0., 0.))
            .spacing(4.)
            .cross_align(Alignment::Center)
            .child(text)
            .maybe_child(long.then(|| {
                rect()
                    .padding(Gaps::new(2., 8., 2., 8.))
                    .on_press(move |_| expanded.set(!is_expanded))
                    .child(
                        label()
                            .text(if is_expanded { "Less" } else { "More" })
                            .font_size(13.)
                            .font_weight(FontWeight::MEDIUM)
                            .color(c.primary),
                    )
                    .hoverable(Size::auto(), Size::auto(), 8.)
            }))
            .children(urls.into_iter().map(|url| {
                let url_open = url.clone();
                rect()
                    .horizontal()
                    .max_width(Size::fill())
                    .padding(Gaps::new(6., 8., 6., 8.))
                    .spacing(6.)
                    .cross_align(Alignment::Center)
                    .on_press(move |_| Platform::get().open_url(url_open.clone()))
                    .child(
                        SvgViewer::new(freya_icons::lucide::external_link())
                            .color(c.primary)
                            .width(Size::px(14.))
                            .height(Size::px(14.)),
                    )
                    .child(
                        label()
                            .text(display_url(&url).to_string())
                            .max_lines(1)
                            .text_overflow(TextOverflow::Ellipsis)
                            .font_size(13.)
                            .color(c.primary),
                    )
                    .hoverable(Size::auto(), Size::auto(), 8.)
            }))
    }
}

/// `text` cut into `(piece, is_url)` around each of `urls`, in order.
fn topic_spans(text: &str, urls: &[String]) -> Vec<(String, bool)> {
    let mut spans = vec![];
    let mut rest = text;
    for url in urls {
        let Some(start) = rest.find(url.as_str()) else {
            continue;
        };
        if start > 0 {
            spans.push((rest[..start].to_string(), false));
        }
        spans.push((url.clone(), true));
        rest = &rest[start + url.len()..];
    }
    if !rest.is_empty() {
        spans.push((rest.to_string(), false));
    }
    spans
}

/// A link without its scheme and trailing slash.
fn display_url(url: &str) -> &str {
    url.trim_start_matches("https://")
        .trim_start_matches("http://")
        .trim_end_matches('/')
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn spans_split_around_urls() {
        let text = "Rules: https://a.org/rules, chat at https://b.org.";
        let urls = extract_urls(text);
        assert_eq!(
            topic_spans(text, &urls),
            vec![
                ("Rules: ".to_string(), false),
                ("https://a.org/rules".to_string(), true),
                (", chat at ".to_string(), false),
                ("https://b.org".to_string(), true),
                (".".to_string(), false),
            ]
        );
    }

    #[test]
    fn spans_without_urls() {
        assert_eq!(
            topic_spans("hello", &[]),
            vec![("hello".to_string(), false)]
        );
    }

    /// "More" shows the whole topic, "Less" clamps it again.
    #[test]
    fn more_toggles_the_clamp() {
        use freya_testing::prelude::launch_test;

        fn app() -> impl IntoElement {
            use_init_theme(light_theme);
            rect().width(Size::px(300.)).child(RoomTopic {
                topic: "A long topic about the room. ".repeat(20),
            })
        }
        fn heights(test: &freya_testing::prelude::TestingRunner) -> (f32, (f32, f32)) {
            let text = test
                .find(|node, element| {
                    Paragraph::try_downcast(element).map(|_| node.layout().area.height())
                })
                .unwrap();
            let more = test
                .find(|node, element| {
                    Label::try_downcast(element).map(|_| {
                        let center = node.layout().area.center();
                        (center.x, center.y)
                    })
                })
                .unwrap();
            (text, more)
        }

        let mut test = launch_test(app);
        test.sync_and_update();
        let (collapsed, more) = heights(&test);
        test.click_cursor((more.0 as f64, more.1 as f64));
        test.sync_and_update();
        let (expanded, less) = heights(&test);
        assert!(expanded > collapsed * 2., "{collapsed} -> {expanded}");
        test.click_cursor((less.0 as f64, less.1 as f64));
        test.sync_and_update();
        assert_eq!(heights(&test).0, collapsed);
    }

    /// A long link ends with an ellipsis instead of leaving the column.
    #[test]
    fn long_link_stays_in_width() {
        use freya_testing::prelude::launch_test;

        fn app() -> impl IntoElement {
            use_init_theme(light_theme);
            rect().width(Size::px(200.)).child(RoomTopic {
                topic: format!("https://example.org/{}", "a".repeat(200)),
            })
        }
        let mut test = launch_test(app);
        test.sync_and_update();
        let right = test
            .find_many(|node, element| {
                Label::try_downcast(element).map(|_| node.layout().area.max_x())
            })
            .into_iter()
            .fold(0f32, f32::max);
        assert!(right <= 200., "link ends at {right}");
    }

    #[test]
    fn display_url_drops_scheme() {
        assert_eq!(display_url("https://example.org/"), "example.org");
        assert_eq!(display_url("http://example.org/a"), "example.org/a");
    }
}
