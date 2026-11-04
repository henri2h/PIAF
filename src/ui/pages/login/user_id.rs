/// Full Matrix ID from what the user typed: trimmed, `@` added if missing.
/// `None` until both the name and the server are present.
pub(super) fn normalize_user_id(input: &str) -> Option<String> {
    let s = input.trim();
    let s = s.strip_prefix('@').unwrap_or(s);
    let (name, server) = s.split_once(':')?;
    if name.is_empty() || server.is_empty() || name.contains(char::is_whitespace) {
        return None;
    }
    Some(format!("@{name}:{server}"))
}

#[cfg(test)]
mod tests {
    use super::normalize_user_id;

    #[test]
    fn adds_sigil_and_trims() {
        assert_eq!(
            normalize_user_id("  alice:matrix.org "),
            Some("@alice:matrix.org".into())
        );
        assert_eq!(
            normalize_user_id("@alice:matrix.org"),
            Some("@alice:matrix.org".into())
        );
    }

    #[test]
    fn needs_name_and_server() {
        assert_eq!(normalize_user_id("alice"), None);
        assert_eq!(normalize_user_id("@alice:"), None);
        assert_eq!(normalize_user_id(":matrix.org"), None);
        assert_eq!(normalize_user_id("al ice:matrix.org"), None);
    }

    #[test]
    fn keeps_port_in_server() {
        assert_eq!(
            normalize_user_id("bob:localhost:8448"),
            Some("@bob:localhost:8448".into())
        );
    }
}
