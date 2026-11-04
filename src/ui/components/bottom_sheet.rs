use freya::prelude::*;

use crate::utils::const_values::AppColors;
use crate::utils::insets;

/// Freya's `BottomSheet` in piaf's colours, clear of the navigation bar (and
/// of the keyboard, if one is open: the sheet would sit behind it), with
/// a grab bar (pull down to close) on touch screens. Pressing the backdrop,
/// Esc or the grab bar calls `on_close`; the caller decides whether it shows.
pub fn bottom_sheet(c: AppColors, mut on_close: impl FnMut() + 'static) -> BottomSheet {
    BottomSheet::new()
        .on_close_request(move |_| on_close())
        .show_handle(cfg!(target_os = "android"))
        .bottom_inset(insets::current().content_bottom())
        .background(c.surface)
        .color(c.on_surface)
        .handle_color(c.outline_variant)
}
