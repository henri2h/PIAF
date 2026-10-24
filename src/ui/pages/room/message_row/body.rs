//! A text message's body: markdown, kept line by line, with mention pills.

use freya::prelude::*;

use crate::ui::components::{HoverableExt, UserPopupInfo};
use crate::ui::pages::room::ui_ctx::use_room_ui_ctx;
use crate::utils::avatars::AvatarSource;
use crate::utils::matrix::my_user_id;
use crate::utils::mentions::{self, Segment};
use crate::utils::queries::use_member_name;
use crate::utils::use_app_colors;

/// Text of a message: `formatted` is its HTML body, if any. A formatted
/// message's `body` is its markdown source (what clients send); a plain one
/// is escaped so `*` or `_` stay as typed.
pub(super) fn text_body(
    room_id: &str,
    body: &str,
    formatted: Option<&str>,
    color: (u8, u8, u8),
) -> Element {
    let pills = formatted.map(mentions::html_pills).unwrap_or_default();
    let markdown: String = mentions::segments(body, &pills)
        .into_iter()
        .map(|segment| match segment {
            Segment::Text(text) if formatted.is_some() => text,
            Segment::Text(text) => escape_markdown(&text),
            Segment::User(user_id) => format!("<mention user=\"{user_id}\"/>"),
            Segment::Room => "<mention room/>".to_string(),
        })
        .collect();
    let room_id = room_id.to_string();
    rect()
        .vertical()
        .color(color)
        .children(blocks(&markdown).into_iter().map(|block| {
            if block.is_empty() {
                return rect().height(Size::px(8.)).into_element();
            }
            let room_id = room_id.clone();
            // A line that is only a tag would be an HTML block, not shown.
            let block = if block.starts_with('<') {
                format!("\u{200B}{block}")
            } else {
                block
            };
            MarkdownViewer::new(block)
                .color(color)
                .inline_element(move |html: String| mention_pill(&room_id, &html))
                .into_element()
        }))
        .into_element()
}

/// The pill for a `<mention …/>` tag of [`text_body`].
fn mention_pill(room_id: &str, html: &str) -> Option<MentionPill> {
    let rest = html.strip_prefix("<mention")?;
    let user_id = rest
        .split_once("user=\"")
        .and_then(|(_, r)| r.split_once('"'))
        .map(|(id, _)| id.to_string());
    if user_id.is_none() && !rest.contains("room") {
        return None;
    }
    Some(MentionPill {
        room_id: room_id.to_string(),
        user_id,
    })
}

/// `@Name` (a member, by display name) or `@room`; a mention of us stands out.
#[derive(PartialEq)]
struct MentionPill {
    room_id: String,
    /// `None`: `@room`.
    user_id: Option<String>,
}

impl Component for MentionPill {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut user_popup = use_room_ui_ctx().user_popup;
        let user_id = self.user_id.clone().unwrap_or_default();
        let name = use_member_name(&self.room_id, &user_id);
        let is_me = self.user_id.is_none() || my_user_id().as_deref() == Some(user_id.as_str());
        let shown = match &self.user_id {
            None => "@room".to_string(),
            Some(id) => format!(
                "@{}",
                name.unwrap_or_else(|| id
                    .trim_start_matches('@')
                    .split(':')
                    .next()
                    .unwrap_or(id)
                    .to_string())
            ),
        };
        let (bg, fg) = if is_me {
            (c.primary, c.on_primary)
        } else {
            (c.primary_container, c.on_primary_container)
        };
        let pill = rect()
            .padding(Gaps::new(0., 6., 0., 6.))
            .corner_radius(8.)
            .background(bg)
            .child(
                label()
                    .text(shown.clone())
                    .font_weight(FontWeight::MEDIUM)
                    .color(fg),
            );
        match self.user_id.clone() {
            None => pill.into_element(),
            Some(user_id) => {
                let avatar = AvatarSource::member(&self.room_id, &user_id);
                pill.on_press(move |e: Event<PressEventData>| {
                    e.stop_propagation();
                    user_popup.set(Some(UserPopupInfo {
                        user_id: user_id.clone(),
                        display_name: shown.trim_start_matches('@').to_string(),
                        avatar: Some(avatar.clone()),
                    }));
                })
                .hoverable(Size::auto(), Size::auto(), 8.)
            }
        }
    }
}

/// Markdown cut into blocks rendered one under the other: each line (the
/// viewer would join them with spaces), fenced code kept whole; `""` for a
/// blank line.
fn blocks(markdown: &str) -> Vec<String> {
    let mut blocks = vec![];
    let mut fence: Option<String> = None;
    for line in markdown.lines() {
        if let Some(code) = fence.as_mut() {
            code.push('\n');
            code.push_str(line);
            if line.trim_start().starts_with("```") {
                blocks.extend(fence.take());
            }
        } else if line.trim_start().starts_with("```") {
            fence = Some(line.to_string());
        } else {
            blocks.push(line.to_string());
        }
    }
    blocks.extend(fence);
    // No blank space before or after the text.
    while blocks.last().is_some_and(|b| b.trim().is_empty()) {
        blocks.pop();
    }
    let start = blocks.iter().take_while(|b| b.trim().is_empty()).count();
    blocks.drain(..start);
    blocks
}

/// Backslash-escapes what markdown would format in plain text.
fn escape_markdown(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut line_start = true;
    for c in text.chars() {
        let block_marker = line_start && "-+>=".contains(c);
        if "\\`*_~[]<>#|".contains(c) || block_marker {
            out.push('\\');
        }
        out.push(c);
        line_start = c == '\n' || (line_start && c == ' ');
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn lines_become_blocks() {
        assert_eq!(blocks("a\nb\n\nc"), vec!["a", "b", "", "c"]);
        assert_eq!(
            blocks("x\n```\nfn a() {}\n\n```\ny"),
            vec!["x", "```\nfn a() {}\n\n```", "y"]
        );
        assert_eq!(blocks("\n a \n\n"), vec![" a "]);
    }

    #[test]
    fn plain_text_is_escaped() {
        assert_eq!(escape_markdown("2*3*4 snake_case"), r"2\*3\*4 snake\_case");
        assert_eq!(escape_markdown("- not a list"), r"\- not a list");
        assert_eq!(escape_markdown("a - b"), "a - b");
        assert_eq!(escape_markdown("# no title"), r"\# no title");
    }

    #[test]
    fn mention_tags() {
        let pill = mention_pill("!r:x", r#"<mention user="@a:x.org"/>"#).unwrap();
        assert_eq!(pill.user_id.as_deref(), Some("@a:x.org"));
        assert!(
            mention_pill("!r:x", "<mention room/>")
                .unwrap()
                .user_id
                .is_none()
        );
        assert!(mention_pill("!r:x", "<b>").is_none());
    }
}

#[cfg(test)]
mod render_tests {
    use freya::prelude::*;
    use freya_testing::prelude::launch_test;

    use crate::ui::pages::room::ui_ctx::use_provide_room_ui_ctx;

    /// Lines stay apart; `@room` alone on a line and an inline user ID both
    /// become pills (inline elements, not text).
    #[test]
    fn mentions_render_as_pills() {
        fn app() -> impl IntoElement {
            use_init_theme(light_theme);
            let scroll = use_scroll_controller(ScrollConfig::default);
            use_provide_room_ui_ctx(scroll);
            rect().width(Size::px(320.)).child(super::text_body(
                "!r:x.org",
                "@room\nhi @ann:x.org, see *this*\n\nbye",
                None,
                (0, 0, 0),
            ))
        }
        // Member names are fetched on tokio.
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let _guard = runtime.enter();
        let mut test = launch_test(app);
        test.sync_and_update();
        if let Ok(path) = std::env::var("PIAF_RENDER") {
            test.render_to_file(path);
        }
        let labels =
            test.find_many(|_, element| Label::try_downcast(element).map(|l| l.text.to_string()));
        assert_eq!(labels.len(), 2, "{labels:?}");
        assert!(labels.contains(&"@room".to_string()), "{labels:?}");
        assert!(labels.contains(&"@ann".to_string()), "{labels:?}");
        let paragraphs = test.find_many(|node, element| {
            Paragraph::try_downcast(element).map(|_| node.layout().area.min_y())
        });
        // One per line ("@room", "hi …", "bye"); the blank line is a gap.
        assert_eq!(paragraphs.len(), 3, "{paragraphs:?}");
    }
}
