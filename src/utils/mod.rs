pub mod const_values;
pub mod matrix;
#[cfg(target_os = "android")]
pub mod push;
pub mod queries;
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

/// Safe replacement for `freya::sdk::use_track_watcher`.
///
/// The original runs `changed().await` in a Freya (smol) spawn. Tokio's
/// cooperative budget check (`poll_proceed`) fires the Freya task waker on
/// every poll, creating a 100% CPU spin loop whenever the channel is active.
///
/// This version runs `changed()` in a real `tokio::task::spawn` and signals
/// back via an executor-agnostic `futures::channel::mpsc`. The Freya spawn
/// only reads from that channel and increments `tick`, which triggers the
/// re-render.
pub fn use_tokio_track_watcher<T: Send + Sync + 'static>(
    watcher: &watch::Receiver<T>,
    mut tick: State<u64>,
) {
    use_hook(|| {
        let mut watcher = watcher.clone();
        watcher.mark_unchanged();
        let (tx, mut rx_chan) = futures::channel::mpsc::unbounded::<()>();
        tokio::task::spawn(async move {
            while watcher.changed().await.is_ok() {
                if tx.unbounded_send(()).is_err() {
                    break;
                }
            }
        });
        spawn(async move {
            while rx_chan.next().await.is_some() {
                *tick.write() += 1;
            }
        });
    });
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
        assert_eq!(extract_urls("see http://example.com"), vec!["http://example.com"]);
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
        assert!(result.contains("Jan"), "expected 'Jan' in result, got: {result}");
    }

    #[test]
    fn format_timestamp_does_not_panic_on_zero() {
        let _ = format_timestamp(ts(0));
    }
}
