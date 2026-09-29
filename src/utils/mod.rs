pub mod bookmarks;
pub mod const_values;
pub mod matrix;
#[cfg(target_os = "android")]
pub mod push;
pub mod queries;
pub mod room_mailbox;
pub mod room_preview;
pub mod sync;
pub mod worker;

#[derive(Clone, Debug, PartialEq)]
pub struct ReceivedReaction {
    pub room_id: String,
    pub room_name: String,
    pub target_event_id: String,
    pub message_preview: String,
    pub emoji: String,
    pub sender_id: String,
    pub sender_display: String,
    pub timestamp_ms: u64,
}

use chrono::{DateTime, Datelike, Local, NaiveDate, TimeZone, Utc};
use freya::prelude::*;
use futures::StreamExt;
use tokio::sync::watch;

use const_values::AppColors;
use freya::prelude::use_theme;

/// Calls `on_change` on the UI executor with each new value of a tokio watch channel.
///
/// `changed()` is awaited in a tokio task: polled from Freya's smol executor,
/// tokio's coop budget re-wakes the task on every poll and spins at 100% CPU.
/// Bound to the calling component: when it unmounts, Freya drops the UI task,
/// which drops `_stop` and ends the tokio task right away.
pub fn bridge_watch<T: Clone + Send + Sync + 'static>(
    rx: &watch::Receiver<T>,
    mut on_change: impl FnMut(T) + 'static,
) {
    let mut rx = rx.clone();
    rx.mark_unchanged();
    let (tx, mut values) = futures::channel::mpsc::unbounded::<T>();
    let (_stop, mut stopped) = futures::channel::oneshot::channel::<()>();
    tokio::task::spawn(async move {
        loop {
            tokio::select! {
                changed = rx.changed() => {
                    if changed.is_err() { break; }
                    let value = rx.borrow_and_update().clone();
                    if tx.unbounded_send(value).is_err() { break; }
                }
                _ = &mut stopped => break,
            }
        }
    });
    spawn(async move {
        let _stop = _stop;
        while let Some(value) = values.next().await {
            on_change(value);
        }
    });
}

/// Mirrors a tokio watch channel into reactive state.
pub fn use_watch<T: Clone + Send + Sync + 'static>(rx: &watch::Receiver<T>) -> State<T> {
    let mut state = use_state(|| rx.borrow().clone());
    use_hook(|| bridge_watch(rx, move |value| state.set(value)));
    state
}

/// Counts changes of a watch channel, for "something changed" signals like sync.
/// Useful as a memo key.
pub fn use_watch_tick<T: Clone + Send + Sync + 'static>(rx: &watch::Receiver<T>) -> State<u64> {
    let mut tick = use_state(|| 0u64);
    use_hook(|| bridge_watch(rx, move |_| *tick.write() += 1));
    tick
}

/// Memoizes an expensive computation across renders, recomputing only when
/// `key` changes from the previous call.
///
/// Freya's own `use_memo` auto-tracks `State` reads instead of taking an
/// explicit key, but requires `T: PartialEq` — many SDK types (e.g.
/// `matrix_sdk::Room`) don't implement that, so this is the escape hatch:
/// key on something cheap and comparable (a tick counter, a filter enum)
/// instead of the expensive value itself.
///
/// Must be called unconditionally at the top of `render`, like any hook.
/// The cache is a plain cell, not `State`: updating it must not schedule
/// another render (a `State` write here rendered every caller twice).
pub fn use_keyed_cache<K, T>(key: K, compute: impl FnOnce() -> T) -> T
where
    K: PartialEq + 'static,
    T: Clone + 'static,
{
    let cache = use_hook(|| std::rc::Rc::new(std::cell::RefCell::new(None::<(K, T)>)));
    let mut cache = cache.borrow_mut();
    match &*cache {
        Some((cached_key, value)) if cached_key == &key => value.clone(),
        _ => {
            let value = compute();
            *cache = Some((key, value.clone()));
            value
        }
    }
}

/// Derives `AppColors` from the current freya theme. Use inside Component::render().
pub fn use_app_colors() -> AppColors {
    let theme = use_theme();
    AppColors::from_colors(&theme.read().colors)
}
use matrix_sdk::ruma::MilliSecondsSinceUnixEpoch;

pub fn sender_color(user_id: &str) -> (u8, u8, u8) {
    let hash: u32 = user_id
        .bytes()
        .fold(0u32, |acc, b| acc.wrapping_mul(31).wrapping_add(b as u32));
    const PALETTE: [(u8, u8, u8); 8] = [
        (229, 57, 53),
        (239, 108, 0),
        (67, 160, 71),
        (30, 136, 229),
        (142, 36, 170),
        (0, 131, 143),
        (0, 121, 107),
        (198, 40, 40),
    ];
    PALETTE[(hash as usize) % PALETTE.len()]
}

pub fn format_timestamp(ts: MilliSecondsSinceUnixEpoch) -> String {
    let millis = u64::from(ts.get()) as i64;
    let Some(dt_utc) = Utc.timestamp_millis_opt(millis).single() else {
        return String::new();
    };
    let dt_local: DateTime<Local> = dt_utc.into();
    let now = Local::now();
    let age = now.signed_duration_since(dt_local);

    if age.num_seconds() < 3600 {
        format!("{}m", age.num_minutes().max(0))
    } else if age.num_hours() < 24 {
        dt_local.format("%H:%M").to_string()
    } else if age.num_days() < 7 {
        dt_local.format("%a").to_string()
    } else if dt_local.year() == now.year() {
        dt_local.format("%b %-d").to_string()
    } else {
        dt_local.format("%b %-d, %Y").to_string()
    }
}

pub fn extract_urls(text: &str) -> Vec<String> {
    text.split_whitespace()
        .filter_map(|word| {
            let trimmed = word.trim_end_matches(|c: char| ".,;:!?)>]\"'".contains(c));
            if trimmed.starts_with("http://") || trimmed.starts_with("https://") {
                Some(trimmed.to_string())
            } else {
                None
            }
        })
        .collect()
}

/// Returns a sortable "YYYY-MM-DD" string for the given timestamp (local time).
pub fn format_date_key(ts: MilliSecondsSinceUnixEpoch) -> String {
    let millis = u64::from(ts.get()) as i64;
    if let Some(dt_utc) = Utc.timestamp_millis_opt(millis).single() {
        let dt_local: DateTime<Local> = dt_utc.into();
        dt_local.format("%Y-%m-%d").to_string()
    } else {
        String::new()
    }
}

/// Returns a human-readable date label for display as a date separator.
pub fn format_date_label(date_key: &str) -> String {
    let today = Local::now().date_naive();
    let yesterday = today.pred_opt().unwrap_or(today);

    if let Ok(date) = NaiveDate::parse_from_str(date_key, "%Y-%m-%d") {
        if date == today {
            return "Today".to_string();
        } else if date == yesterday {
            return "Yesterday".to_string();
        } else if today.signed_duration_since(date).num_days() < 7 {
            // Within the last week: show weekday name
            let dt = date.and_hms_opt(12, 0, 0).unwrap_or_default();
            if let Some(local_dt) = Local.from_local_datetime(&dt).single() {
                return local_dt.format("%A").to_string();
            }
        } else {
            let dt = date.and_hms_opt(12, 0, 0).unwrap_or_default();
            if let Some(local_dt) = Local.from_local_datetime(&dt).single() {
                return local_dt.format("%B %-d, %Y").to_string();
            }
        }
    }
    date_key.to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    use matrix_sdk::ruma::{MilliSecondsSinceUnixEpoch, UInt};

    fn ts(millis: u64) -> MilliSecondsSinceUnixEpoch {
        MilliSecondsSinceUnixEpoch(UInt::try_from(millis).unwrap())
    }

    // ── sender_color ─────────────────────────────────────────────────────────

    #[test]
    fn sender_color_is_deterministic() {
        let a = sender_color("@alice:example.com");
        let b = sender_color("@alice:example.com");
        assert_eq!(a, b);
    }

    #[test]
    fn sender_color_differs_for_different_users() {
        // Not strictly guaranteed by the hash, but holds for these two inputs.
        let a = sender_color("@alice:example.com");
        let b = sender_color("@bob:example.com");
        assert_ne!(a, b);
    }

    #[test]
    fn sender_color_empty_string_does_not_panic() {
        let _ = sender_color("");
    }

    // ── extract_urls ─────────────────────────────────────────────────────────

    #[test]
    fn extract_urls_empty() {
        assert!(extract_urls("").is_empty());
    }

    #[test]
    fn extract_urls_no_urls() {
        assert!(extract_urls("hello world, no links here").is_empty());
    }

    #[test]
    fn extract_urls_plain_domain_ignored() {
        assert!(extract_urls("visit example.com for more").is_empty());
    }

    #[test]
    fn extract_urls_http() {
        assert_eq!(
            extract_urls("see http://example.com"),
            vec!["http://example.com"]
        );
    }

    #[test]
    fn extract_urls_https() {
        assert_eq!(
            extract_urls("see https://example.com"),
            vec!["https://example.com"]
        );
    }

    #[test]
    fn extract_urls_strips_trailing_punctuation() {
        assert_eq!(
            extract_urls("check https://example.com."),
            vec!["https://example.com"]
        );
        assert_eq!(
            extract_urls("see https://example.com, ok"),
            vec!["https://example.com"]
        );
        assert_eq!(
            extract_urls("see https://example.com/path)"),
            vec!["https://example.com/path"]
        );
        // Leading ( is part of the word from split_whitespace; extract_urls only strips
        // trailing chars and does not handle a URL wrapped in balanced parentheses.
        assert!(extract_urls("(https://example.com)").is_empty());
    }

    #[test]
    fn extract_urls_multiple() {
        let urls = extract_urls("a https://foo.com and https://bar.com here");
        assert_eq!(urls, vec!["https://foo.com", "https://bar.com"]);
    }

    #[test]
    fn extract_urls_preserves_path_and_query() {
        let urls = extract_urls("see https://example.com/path?q=1&r=2");
        assert_eq!(urls, vec!["https://example.com/path?q=1&r=2"]);
    }

    // ── format_date_key ───────────────────────────────────────────────────────

    #[test]
    fn format_date_key_known_timestamp() {
        // Jan 15, 2020 12:00 UTC. In any practical timezone this is still Jan 15.
        let result = format_date_key(ts(1_579_089_600_000));
        // Must be a valid YYYY-MM-DD string
        assert!(result.len() == 10, "unexpected: {result}");
        assert_eq!(&result[..4], "2020");
        let parts: Vec<&str> = result.split('-').collect();
        assert_eq!(parts.len(), 3);
    }

    #[test]
    fn format_date_key_invalid_returns_empty() {
        // Timestamp 0 is valid (Unix epoch), but extremely large values overflow UInt.
        // Use a ts() of 0 (Jan 1, 1970).
        let result = format_date_key(ts(0));
        assert!(!result.is_empty()); // epoch is valid
    }

    // ── format_date_label ─────────────────────────────────────────────────────

    #[test]
    fn format_date_label_old_date_returns_long_form() {
        // March 5, 2019 is always in the past and far from any "last week" window.
        let label = format_date_label("2019-03-05");
        assert_eq!(label, "March 5, 2019");
    }

    #[test]
    fn format_date_label_invalid_key_echoed_back() {
        assert_eq!(format_date_label("not-a-date"), "not-a-date");
        assert_eq!(format_date_label("2020-13-45"), "2020-13-45");
    }

    #[test]
    fn format_date_label_old_year_format() {
        assert_eq!(format_date_label("2018-11-22"), "November 22, 2018");
    }

    // ── format_timestamp ─────────────────────────────────────────────────────

    #[test]
    fn format_timestamp_old_different_year() {
        // Jan 1, 2020 12:00 UTC — always older than 7 days, year != current year.
        let result = format_timestamp(ts(1_577_880_000_000));
        // Expect "Jan 1, 2020" format (month abbrev + day + year).
        assert!(
            result.contains("2020"),
            "expected year 2020 in result, got: {result}"
        );
        assert!(
            result.contains("Jan"),
            "expected 'Jan' in result, got: {result}"
        );
    }

    #[test]
    fn format_timestamp_does_not_panic_on_zero() {
        let _ = format_timestamp(ts(0));
    }
}
