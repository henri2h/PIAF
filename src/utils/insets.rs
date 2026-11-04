//! System insets (status bar, navigation bar, keyboard), in logical pixels.
//! Android reports them from `MainActivity` over JNI; the app draws edge to
//! edge and pads itself. Zero on desktop.

use std::sync::LazyLock;

use freya::prelude::State;
use tokio::sync::watch;

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Insets {
    /// Status bar (and display cutout).
    pub top: f32,
    /// Navigation bar: gesture handle or buttons.
    pub bottom: f32,
    /// On-screen keyboard height from the bottom edge; 0 while hidden.
    pub ime: f32,
}

impl Insets {
    /// Space the content must leave at the bottom: the keyboard when open,
    /// else the navigation bar.
    pub fn content_bottom(&self) -> f32 {
        self.ime.max(self.bottom)
    }

    pub fn keyboard_open(&self) -> bool {
        self.ime > self.bottom
    }
}

/// Typical values until Android reports the real ones.
const DEFAULT: Insets = if cfg!(target_os = "android") {
    Insets {
        top: 40.,
        bottom: 20.,
        ime: 0.,
    }
} else {
    Insets {
        top: 0.,
        bottom: 0.,
        ime: 0.,
    }
};

/// A `LazyLock`, not an `app::state` singleton: Android reports insets as soon
/// as the activity is created, possibly before `init` runs.
static INSETS: LazyLock<watch::Sender<Insets>> = LazyLock::new(|| watch::Sender::new(DEFAULT));

#[cfg_attr(not(target_os = "android"), allow(dead_code))]
pub fn set(insets: Insets) {
    INSETS.send_if_modified(|current| {
        let changed = *current != insets;
        *current = insets;
        changed
    });
}

pub fn current() -> Insets {
    *INSETS.borrow()
}

/// Height of the status bar: top padding of app bars drawn under it.
pub fn status_bar_inset() -> f32 {
    current().top
}

/// The insets, re-rendering the component when they change (keyboard).
pub fn use_insets() -> State<Insets> {
    crate::utils::use_watch(&INSETS.subscribe())
}
