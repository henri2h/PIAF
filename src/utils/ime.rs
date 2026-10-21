//! The soft keyboard on Android (`android::ime`), no-op elsewhere: desktop
//! input reaches the composer as key events.

/// What the keyboard did to the composer's text.
pub enum ImeEvent {
    /// Insert, replacing the composition (`"\n"`: new line).
    Commit(String),
    /// The word being composed (shown in place, replaced by the next one); empty clears it.
    Preedit(String),
    /// Delete around the cursor, in characters.
    Delete { before: usize, after: usize },
    /// Text already typed becomes the composition (UTF-16 range).
    ComposingRegion { start: usize, end: usize },
    /// Move the cursor or select (UTF-16 range).
    Select { start: usize, end: usize },
}

impl ImeEvent {
    /// For logs: never the text.
    pub fn kind(&self) -> &'static str {
        match self {
            Self::Commit(_) => "commit",
            Self::Preedit(_) => "preedit",
            Self::Delete { .. } => "delete",
            Self::ComposingRegion { .. } => "composing region",
            Self::Select { .. } => "select",
        }
    }
}

#[cfg(target_os = "android")]
pub use crate::android::ime::{drain, events, hide, show, sync};

#[cfg(not(target_os = "android"))]
mod desktop {
    use super::ImeEvent;

    pub fn events() -> tokio::sync::watch::Receiver<u64> {
        tokio::sync::watch::channel(0).1
    }
    pub fn drain() -> Vec<ImeEvent> {
        Vec::new()
    }
    pub fn show(_text: &str, _cursor: usize) -> u64 {
        0
    }
    pub fn hide(_owner: u64) {}
    pub fn sync(_text: &str, _cursor: usize) {}
}
#[cfg(not(target_os = "android"))]
pub use desktop::*;
