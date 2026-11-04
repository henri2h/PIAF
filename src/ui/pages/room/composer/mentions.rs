//! `@` autocomplete: the query being typed, matching members, insertion.

use freya::prelude::*;

use crate::ui::components::{Avatar, ListItem};
use crate::utils::const_values::AppColors;
use crate::utils::id_color;
use crate::utils::members::MemberItem;

const MAX_SUGGESTIONS: usize = 5;
const MAX_QUERY_CHARS: usize = 32;

/// The `@query` right before the cursor: `(start of the @, query)`, in
/// UTF-16 code units like the editor's positions.
pub(super) fn mention_query(text: &str, cursor: usize) -> Option<(usize, String)> {
    let before = utf16_prefix(text, cursor);
    let at = before.rfind('@')?;
    let query = &before[at + 1..];
    let starts_word = before[..at]
        .chars()
        .next_back()
        .is_none_or(char::is_whitespace);
    (starts_word
        && !query.contains(char::is_whitespace)
        && query.chars().count() <= MAX_QUERY_CHARS)
        .then(|| (before[..at].encode_utf16().count(), query.to_string()))
}

/// `text` with `start..cursor` replaced by `@name `, and the new cursor.
pub(super) fn insert_mention(
    text: &str,
    start: usize,
    cursor: usize,
    name: &str,
) -> (String, usize) {
    let head = utf16_prefix(text, start);
    let tail = &text[utf16_prefix(text, cursor).len()..];
    let inserted = format!("@{name} ");
    let cursor = start + inserted.encode_utf16().count();
    (format!("{head}{inserted}{tail}"), cursor)
}

/// Members matching `query` (names starting with it first), without us.
pub(super) fn suggestions<'a>(
    members: &'a [MemberItem],
    query: &str,
    me: Option<&str>,
) -> Vec<&'a MemberItem> {
    let lower = query.to_lowercase();
    let mut found: Vec<&MemberItem> = members
        .iter()
        .filter(|m| Some(m.user_id.as_str()) != me && m.matches(query))
        .collect();
    found.sort_by_key(|m| {
        let name = m.display_name.to_lowercase();
        let local = m.user_id.trim_start_matches('@').to_lowercase();
        !(name.starts_with(&lower) || local.starts_with(&lower))
    });
    found.truncate(MAX_SUGGESTIONS);
    found
}

/// The longest prefix of `text` within `units` UTF-16 code units.
fn utf16_prefix(text: &str, units: usize) -> &str {
    let mut count = 0;
    for (i, c) in text.char_indices() {
        if count >= units {
            return &text[..i];
        }
        count += c.len_utf16();
    }
    text
}

/// The suggestions above the composer's text; `on_pick` gets the member.
pub(super) fn suggestion_list(
    members: Vec<MemberItem>,
    room_id: &str,
    on_pick: impl Fn(MemberItem) + Clone + 'static,
    c: AppColors,
) -> Element {
    rect()
        .vertical()
        .width(Size::fill())
        .padding(Gaps::new(4., 0., 4., 0.))
        .children(members.into_iter().map(|member| {
            let on_pick = on_pick.clone();
            let picked = member.clone();
            ListItem::new(member.display_name.clone())
                .supporting(member.user_id.clone())
                .leading(Avatar {
                    size: 32.,
                    source: Some(member.avatar(room_id)),
                    name: member.display_name.clone(),
                    color: id_color(&member.user_id),
                })
                .on_press(move |_| on_pick(picked.clone()))
                .into_element()
        }))
        .child(
            rect()
                .width(Size::fill())
                .height(Size::px(1.))
                .background(c.outline_variant),
        )
        .into_element()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn member(user_id: &str, name: &str) -> MemberItem {
        MemberItem {
            user_id: user_id.into(),
            display_name: name.into(),
            power_level: 0,
        }
    }

    #[test]
    fn query_before_the_cursor() {
        assert_eq!(mention_query("hi @an", 6), Some((3, "an".into())));
        assert_eq!(mention_query("@", 1), Some((0, String::new())));
        assert_eq!(mention_query("hi @an more", 11), None);
        assert_eq!(mention_query("me@x", 4), None);
        // UTF-16 positions: the emoji counts for two.
        assert_eq!(mention_query("😀 @b", 5), Some((3, "b".into())));
    }

    #[test]
    fn inserting_replaces_the_query() {
        assert_eq!(
            insert_mention("hi @an!", 3, 6, "Ann"),
            ("hi @Ann !".to_string(), 8)
        );
    }

    #[test]
    fn prefix_matches_first_and_not_me() {
        let members = [
            member("@zed:x", "Bob Ann"),
            member("@ann:x", "Ann"),
            member("@me:x", "Annie"),
        ];
        let found = suggestions(&members, "ann", Some("@me:x"));
        let ids: Vec<_> = found.iter().map(|m| m.user_id.as_str()).collect();
        assert_eq!(ids, ["@ann:x", "@zed:x"]);
    }
}
