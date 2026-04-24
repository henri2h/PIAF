pub mod const_values;
pub mod matrix;
#[cfg(target_os = "android")]
pub mod push;
pub mod queries;
pub mod worker;

use chrono::{DateTime, Local, NaiveDate, TimeZone, Utc};
use freya::prelude::*;
use futures::StreamExt;
use tokio::sync::watch;

use const_values::AppColors;

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

/// Initialize `AppColors` as a root-scoped context (call once at the app root).
pub fn use_init_app_colors(init: impl FnOnce() -> AppColors) -> State<AppColors> {
    use_hook(|| {
        if let Some(existing) = try_consume_context::<State<AppColors>>() {
            existing
        } else {
            let state = State::create_in_scope(init(), ScopeId::ROOT);
            provide_context_for_scope_id(state, ScopeId::ROOT);
            state
        }
    })
}

/// Read the current `AppColors` from context and subscribe to changes.
/// Panics if `use_init_app_colors` was not called at a parent scope.
pub fn use_app_colors() -> AppColors {
    *use_consume::<State<AppColors>>().read()
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
    } else if age.num_days() < 30 {
        format!("{}d", age.num_days())
    } else {
        format!("{}w", age.num_weeks())
    }
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
