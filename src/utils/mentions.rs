//! Mentions in a message body: `@room`, user IDs, and the pills of its
//! formatted (HTML) body.

/// A piece of a message body.
#[derive(Debug, Clone, PartialEq)]
pub enum Segment {
    Text(String),
    /// A user, by ID.
    User(String),
    /// `@room`: everyone in the room.
    Room,
}

const MATRIX_TO: &str = "https://matrix.to/#/";

/// The user pills of an HTML body: `(user_id, link text)`, in order.
pub fn html_pills(html: &str) -> Vec<(String, String)> {
    let mut pills = vec![];
    let mut rest = html;
    while let Some(start) = rest.find(MATRIX_TO) {
        rest = &rest[start + MATRIX_TO.len()..];
        let Some(end) = rest.find(['"', '\'']) else {
            break;
        };
        let target = percent_decode(&rest[..end]);
        // `@user:server`, maybe followed by `?via=…`.
        let user_id = target.split('?').next().unwrap_or_default().to_string();
        let Some(text_start) = rest[end..].find('>').map(|i| end + i + 1) else {
            break;
        };
        let Some(text_end) = rest[text_start..].find("</a>").map(|i| text_start + i) else {
            break;
        };
        let text = rest[text_start..text_end].to_string();
        rest = &rest[text_end..];
        if user_id.starts_with('@') && !text.is_empty() {
            pills.push((user_id, text));
        }
    }
    pills
}

/// `body` cut into text and mentions: each pill's text (first occurrence,
/// in order), then user IDs and `@room` written out.
pub fn segments(body: &str, pills: &[(String, String)]) -> Vec<Segment> {
    let mut out = vec![];
    let mut rest = body;
    for (user_id, text) in pills {
        let Some(at) = rest.find(text.as_str()) else {
            continue;
        };
        push_plain(&mut out, &rest[..at]);
        out.push(Segment::User(user_id.clone()));
        rest = &rest[at + text.len()..];
    }
    push_plain(&mut out, rest);
    out
}

/// Text with the user IDs and `@room` it spells out.
fn push_plain(out: &mut Vec<Segment>, text: &str) {
    let mut last = 0;
    let mut i = 0;
    while let Some(offset) = text[i..].find('@') {
        let at = i + offset;
        // Not inside a word (e-mail addresses).
        let starts_word = text[..at]
            .chars()
            .next_back()
            .is_none_or(|c| !c.is_alphanumeric());
        let found = if !starts_word {
            None
        } else if let Some(len) = user_id_len(&text[at..]) {
            Some((Segment::User(text[at..at + len].to_string()), len))
        } else if is_room_mention(&text[at..]) {
            Some((Segment::Room, "@room".len()))
        } else {
            None
        };
        match found {
            Some((segment, len)) => {
                push_text(out, &text[last..at]);
                out.push(segment);
                i = at + len;
                last = i;
            }
            None => i = at + 1,
        }
    }
    push_text(out, &text[last..]);
}

fn push_text(out: &mut Vec<Segment>, text: &str) {
    if text.is_empty() {
        return;
    }
    match out.last_mut() {
        Some(Segment::Text(prev)) => prev.push_str(text),
        _ => out.push(Segment::Text(text.to_string())),
    }
}

fn is_room_mention(s: &str) -> bool {
    s.strip_prefix("@room")
        .is_some_and(|rest| rest.chars().next().is_none_or(|c| !c.is_alphanumeric()))
}

/// Length of the user ID `s` starts with (`@localpart:server`), if any.
fn user_id_len(s: &str) -> Option<usize> {
    let local = s[1..]
        .find(|c: char| !(c.is_ascii_alphanumeric() || "._=-/+".contains(c)))
        .map_or(s.len(), |i| i + 1);
    if local == 1 || !s[local..].starts_with(':') {
        return None;
    }
    let server = &s[local + 1..];
    let server_len = server
        .find(|c: char| !(c.is_ascii_alphanumeric() || ".-:[]".contains(c)))
        .unwrap_or(server.len());
    // A sentence's full stop or colon isn't part of the server name.
    let server_len = server[..server_len].trim_end_matches(['.', ':']).len();
    (server_len > 0).then_some(local + 1 + server_len)
}

fn percent_decode(s: &str) -> String {
    s.replace("%40", "@")
        .replace("%3A", ":")
        .replace("%3a", ":")
}

#[cfg(test)]
mod tests {
    use super::*;

    fn text(s: &str) -> Segment {
        Segment::Text(s.to_string())
    }

    fn user(s: &str) -> Segment {
        Segment::User(s.to_string())
    }

    #[test]
    fn user_ids_and_room() {
        assert_eq!(
            segments("hi @ann:x.org and @room.", &[]),
            vec![
                text("hi "),
                user("@ann:x.org"),
                text(" and "),
                Segment::Room,
                text(".")
            ]
        );
    }

    #[test]
    fn trailing_punctuation_and_emails() {
        assert_eq!(
            segments("ask @bob:matrix.org: ok", &[]),
            vec![text("ask "), user("@bob:matrix.org"), text(": ok")]
        );
        assert_eq!(segments("me@x.org", &[]), vec![text("me@x.org")]);
        assert_eq!(segments("@roomy", &[]), vec![text("@roomy")]);
    }

    #[test]
    fn pills_replace_their_text() {
        let html = r#"<a href="https://matrix.to/#/@ann:x.org">Ann</a>: look"#;
        let pills = html_pills(html);
        assert_eq!(pills, vec![("@ann:x.org".into(), "Ann".into())]);
        assert_eq!(
            segments("Ann: look", &pills),
            vec![user("@ann:x.org"), text(": look")]
        );
    }

    #[test]
    fn encoded_pills() {
        let html = r#"<a href='https://matrix.to/#/%40ann%3Ax.org?via=x.org'>Ann</a>"#;
        assert_eq!(html_pills(html), vec![("@ann:x.org".into(), "Ann".into())]);
    }

    #[test]
    fn room_links_are_not_pills() {
        let html = r##"<a href="https://matrix.to/#/#rust:x.org">#rust</a>"##;
        assert!(html_pills(html).is_empty());
    }
}
