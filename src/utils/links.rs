//! Bare URLs in message text, made into markdown links.

/// A piece of text: plain, or a URL.
#[derive(Debug, PartialEq)]
pub enum Piece<'a> {
    Text(&'a str),
    Url(&'a str),
}

/// `text` cut into plain text and the `http(s)://` URLs written in it.
/// Punctuation closing a sentence (or a parenthesis opened before the URL)
/// is left out of the URL.
pub fn pieces(text: &str) -> Vec<Piece<'_>> {
    let mut out = vec![];
    let mut last = 0;
    let mut i = 0;
    while let Some(offset) = text[i..].find("http") {
        let at = i + offset;
        let rest = &text[at..];
        let is_url = (rest.starts_with("https://") || rest.starts_with("http://"))
            && text[..at]
                .chars()
                .next_back()
                .is_none_or(|c| !c.is_alphanumeric());
        let len = if is_url { url_len(rest) } else { 0 };
        if len == 0 {
            i = at + "http".len();
            continue;
        }
        if at > last {
            out.push(Piece::Text(&text[last..at]));
        }
        out.push(Piece::Url(&rest[..len]));
        i = at + len;
        last = i;
    }
    if last < text.len() {
        out.push(Piece::Text(&text[last..]));
    }
    out
}

/// Length of the URL `s` starts with; 0 when there is nothing after the scheme.
fn url_len(s: &str) -> usize {
    // `](` closes a markdown link's label: `[https://a](https://b)`.
    let end = s
        .find(|c: char| c.is_whitespace() || "<>\"`".contains(c))
        .unwrap_or(s.len())
        .min(s.find("](").unwrap_or(s.len()));
    let mut url = &s[..end];
    loop {
        let trimmed = url.trim_end_matches(['.', ',', ';', ':', '!', '?', '\'', '*', '_', '~']);
        // A `)` closes the URL's own `(` (Wikipedia), else the sentence's.
        let trimmed = match trimmed.strip_suffix(')') {
            Some(inner) if inner.matches('(').count() < trimmed.matches(')').count() => inner,
            _ => trimmed,
        };
        if trimmed.len() == url.len() {
            break;
        }
        url = trimmed;
    }
    if url.ends_with("//") { 0 } else { url.len() }
}

/// Markdown source with its bare URLs as autolinks (`<url>`); URLs already in
/// a link (`[text](url)`, `<url>`) or in code are left as they are.
pub fn autolink_markdown(markdown: &str) -> String {
    let mut out = String::with_capacity(markdown.len());
    let mut in_fence = false;
    for line in markdown.split_inclusive('\n') {
        if line.trim_start().starts_with("```") {
            in_fence = !in_fence;
            out.push_str(line);
            continue;
        }
        if in_fence {
            out.push_str(line);
            continue;
        }
        let mut written = 0;
        for piece in pieces(line) {
            match piece {
                Piece::Url(url) => {
                    let before = &line[..written];
                    let in_code = before.matches('`').count() % 2 == 1;
                    let label_of_link =
                        before.ends_with('[') && line[written + url.len()..].starts_with("](");
                    let in_link = before.ends_with("](") || before.ends_with('<') || label_of_link;
                    if in_code || in_link {
                        out.push_str(url);
                    } else {
                        out.push('<');
                        out.push_str(url);
                        out.push('>');
                    }
                    written += url.len();
                }
                Piece::Text(text) => {
                    out.push_str(text);
                    written += text.len();
                }
            }
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn urls(text: &str) -> Vec<&str> {
        pieces(text)
            .into_iter()
            .filter_map(|p| match p {
                Piece::Url(u) => Some(u),
                Piece::Text(_) => None,
            })
            .collect()
    }

    #[test]
    fn markdown_link_with_url_label_stays() {
        let md = "[https://a.b/](https://a.b/?x=1&y=2)";
        assert_eq!(autolink_markdown(md), md);
    }

    #[test]
    fn finds_urls_without_sentence_punctuation() {
        assert_eq!(
            urls("see https://x.org/a?b=1. and (http://y.org)!"),
            vec!["https://x.org/a?b=1", "http://y.org"]
        );
        assert_eq!(
            urls("https://en.wikipedia.org/wiki/Rust_(language)"),
            vec!["https://en.wikipedia.org/wiki/Rust_(language)"]
        );
        assert!(urls("xhttps://x.org, https:// alone, httpbin").is_empty());
    }

    #[test]
    fn pieces_keep_all_the_text() {
        let text = "a https://x.org b";
        let joined: String = pieces(text)
            .into_iter()
            .map(|p| match p {
                Piece::Text(t) | Piece::Url(t) => t,
            })
            .collect();
        assert_eq!(joined, text);
    }

    #[test]
    fn markdown_links_and_code_stay() {
        assert_eq!(
            autolink_markdown("go https://x.org now"),
            "go <https://x.org> now"
        );
        assert_eq!(
            autolink_markdown("[x](https://x.org) <https://y.org> `https://z.org`"),
            "[x](https://x.org) <https://y.org> `https://z.org`"
        );
        assert_eq!(
            autolink_markdown("```\nhttps://x.org\n```\nhttps://y.org"),
            "```\nhttps://x.org\n```\n<https://y.org>"
        );
        assert_eq!(autolink_markdown("**https://x.org**"), "**<https://x.org>**");
    }
}
