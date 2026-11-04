//! What the composer sends: markdown text with mention pills.

use matrix_sdk::ruma::OwnedUserId;
use matrix_sdk::ruma::events::Mentions;
use matrix_sdk::ruma::events::room::message::{
    FormattedBody, RoomMessageEventContentWithoutRelation,
};

/// A person picked from the mention suggestions; the text holds `@{name}`.
#[derive(Debug, Clone, PartialEq)]
pub(crate) struct Mention {
    pub user_id: String,
    pub name: String,
}

/// The composer's text and the people mentioned in it.
#[derive(Debug, Clone, Default, PartialEq)]
pub(crate) struct Draft {
    pub text: String,
    pub mentions: Vec<Mention>,
}

impl Draft {
    #[cfg(test)]
    pub fn text(text: impl Into<String>) -> Self {
        Self {
            text: text.into(),
            mentions: vec![],
        }
    }

    /// The message content: markdown rendered to HTML when it has any
    /// formatting, each mention a pill (`body` keeps the name alone).
    pub fn content(&self) -> RoomMessageEventContentWithoutRelation {
        // Still in the text (it may have been edited since), longest names
        // first so one name being the prefix of another doesn't split it.
        let mut mentions: Vec<&Mention> = self
            .mentions
            .iter()
            .filter(|m| self.text.contains(&format!("@{}", m.name)))
            .collect();
        mentions.sort_by_key(|m| std::cmp::Reverse(m.name.len()));
        mentions.dedup_by(|a, b| a.user_id == b.user_id);

        let mut body = self.text.clone();
        let mut markdown = self.text.clone();
        for m in &mentions {
            let tag = format!("@{}", m.name);
            body = body.replace(&tag, &m.name);
            markdown = markdown.replace(
                &tag,
                &format!("[{}](https://matrix.to/#/{})", m.name, m.user_id),
            );
        }
        let content = match FormattedBody::markdown(&markdown) {
            Some(html) => RoomMessageEventContentWithoutRelation::text_html(body, html.body),
            None => RoomMessageEventContentWithoutRelation::text_plain(body),
        };
        let ids = mentions
            .iter()
            .filter_map(|m| OwnedUserId::try_from(m.user_id.as_str()).ok());
        content.add_mentions(Mentions::with_user_ids(ids))
    }
}

#[cfg(test)]
mod tests {
    use matrix_sdk::ruma::events::room::message::MessageType;

    use super::*;

    fn text_of(draft: &Draft) -> (String, Option<String>) {
        let MessageType::Text(t) = draft.content().msgtype else {
            panic!("not text");
        };
        (t.body, t.formatted.map(|f| f.body))
    }

    #[test]
    fn plain_text_stays_plain() {
        assert_eq!(text_of(&Draft::text("hello")), ("hello".into(), None));
    }

    #[test]
    fn markdown_gets_html() {
        let (body, html) = text_of(&Draft::text("**hi**"));
        assert_eq!(body, "**hi**");
        assert_eq!(html.as_deref(), Some("<strong>hi</strong>"));
    }

    #[test]
    fn mentions_become_pills() {
        let draft = Draft {
            text: "@Ann and @Annabel: hi".into(),
            mentions: vec![
                Mention {
                    user_id: "@ann:x.org".into(),
                    name: "Ann".into(),
                },
                Mention {
                    user_id: "@annabel:x.org".into(),
                    name: "Annabel".into(),
                },
            ],
        };
        let content = draft.content();
        let ids: Vec<String> = content
            .mentions
            .as_ref()
            .unwrap()
            .user_ids
            .iter()
            .map(|u| u.to_string())
            .collect();
        assert_eq!(ids.len(), 2);
        let (body, html) = text_of(&draft);
        assert_eq!(body, "Ann and Annabel: hi");
        let html = html.unwrap();
        assert!(html.contains(r#"<a href="https://matrix.to/#/@ann:x.org">Ann</a>"#));
        assert!(html.contains(r#"<a href="https://matrix.to/#/@annabel:x.org">Annabel</a>"#));
    }

    #[test]
    fn removed_mentions_are_dropped() {
        let draft = Draft {
            text: "hi".into(),
            mentions: vec![Mention {
                user_id: "@ann:x.org".into(),
                name: "Ann".into(),
            }],
        };
        assert!(draft.content().mentions.unwrap().user_ids.is_empty());
    }
}
