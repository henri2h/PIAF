use freya::prelude::*;

use crate::utils::const_values::{piaf_dark_colors, piaf_light_colors};

pub fn effective_theme(is_dark: bool) -> Theme {
    let mut theme = if is_dark { dark_theme() } else { light_theme() };
    theme.colors = if is_dark {
        piaf_dark_colors()
    } else {
        piaf_light_colors()
    };
    theme
}

/// Theme preference file (next to the data directory).
fn pref_file() -> Option<std::path::PathBuf> {
    crate::utils::matrix::DATA_DIR
        .get()
        .and_then(|d| d.parent())
        .map(|p| p.join("theme_pref"))
}

/// Saved preference: dark (`2`) or light (`1`, or nothing saved).
pub fn load_is_dark() -> bool {
    pref_file()
        .and_then(|p| std::fs::read_to_string(p).ok())
        .is_some_and(|s| s.trim() == "2")
}

/// Applies the dark or light theme and remembers the choice.
pub fn set_dark(mut theme: State<Theme>, dark: bool) {
    theme.set(effective_theme(dark));
    if let Some(path) = pref_file() {
        tokio::spawn(async move {
            let _ = tokio::fs::write(&path, if dark { "2" } else { "1" }).await;
        });
    }
}
