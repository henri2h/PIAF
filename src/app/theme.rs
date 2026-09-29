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
