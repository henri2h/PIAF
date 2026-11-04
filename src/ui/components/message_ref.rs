use freya::prelude::*;
use matrix_sdk::ruma::{MilliSecondsSinceUnixEpoch, UInt};

use crate::utils::const_values::AppColors;
use crate::utils::format_timestamp;

/// Headline of a row pointing at a message elsewhere (bookmarks,
/// reactions): "**Sender** in Room", one line.
pub fn sender_in_room(sender: &str, room: &str, c: AppColors) -> Paragraph {
    paragraph()
        .span(
            Span::new(sender.to_string())
                .font_weight(FontWeight::MEDIUM)
                .color(c.on_surface),
        )
        .span(Span::new(format!(" in {room}")).color(c.on_surface_muted))
        .width(Size::fill())
        .max_lines(1)
        .text_overflow(TextOverflow::Ellipsis)
        .font_size(14.)
}

/// A small timestamp label for a row's trailing side.
pub fn row_time(ts_ms: u64, c: AppColors) -> Label {
    let ts = MilliSecondsSinceUnixEpoch(UInt::try_from(ts_ms).unwrap_or_default());
    label()
        .text(format_timestamp(ts))
        .font_size(11.)
        .color(c.on_surface_faint)
}
