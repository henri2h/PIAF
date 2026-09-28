//! Logging through `tracing`.
//!
//! Desktop: filtered by `RUST_LOG`, default [`DEFAULT_FILTER`].
//! Android: forwarded to logcat via the `log` bridge, filtered by [`DEFAULT_FILTER`].
//!
//! Perf diagnostics use the `piaf::perf` target:
//! `RUST_LOG=warn,piaf=info,piaf::perf=debug` for timings, `=trace` adds every render.

use std::time::{Duration, Instant};

pub const DEFAULT_FILTER: &str = "warn,piaf=info";

/// Target for render counts and timings.
pub const PERF: &str = "piaf::perf";

#[cfg(not(target_os = "android"))]
pub fn init() {
    use tracing_subscriber::EnvFilter;
    let filter =
        EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new(DEFAULT_FILTER));
    tracing_subscriber::fmt().with_env_filter(filter).init();
}

#[cfg(target_os = "android")]
pub fn init() {
    use android_logger::{Config, FilterBuilder};
    android_logger::init_once(
        Config::default()
            .with_max_level(log::LevelFilter::Trace)
            .with_filter(FilterBuilder::new().parse(DEFAULT_FILTER).build()),
    );
}

/// Logs `name`'s render at trace level, and its duration at debug level when
/// it exceeds `slow`. Hold it for the whole `render`.
pub struct RenderTimer {
    name: &'static str,
    start: Instant,
    slow: Duration,
}

impl RenderTimer {
    pub fn new(name: &'static str) -> Self {
        Self::with_threshold(name, Duration::from_micros(500))
    }

    pub fn with_threshold(name: &'static str, slow: Duration) -> Self {
        tracing::trace!(target: PERF, "render {name}");
        Self {
            name,
            start: Instant::now(),
            slow,
        }
    }
}

impl Drop for RenderTimer {
    fn drop(&mut self) {
        let elapsed = self.start.elapsed();
        if elapsed >= self.slow {
            tracing::debug!(target: PERF, "slow render {} {}µs", self.name, elapsed.as_micros());
        }
    }
}
