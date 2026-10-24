use freya::prelude::*;
use matrix_sdk_ui::timeline::EventSendState;

use crate::utils::const_values::AppColors;

/// Time of a bubble, "edited", and for our messages the send state.
pub(super) struct Meta {
    pub timestamp: String,
    pub edited: bool,
    /// Our message: `Some(read by someone)`.
    pub mine: Option<bool>,
    pub send_state: Option<EventSendState>,
}

impl Meta {
    /// `over_image`: white, for the dark pill over an image's corner.
    pub fn render(self, over_image: bool, c: AppColors) -> Rect {
        let color = if over_image {
            (255, 255, 255)
        } else if self.mine.is_some() {
            c.timestamp_me
        } else {
            c.on_surface_faint
        };
        let receipt = self.mine.map(|read| match &self.send_state {
            Some(EventSendState::NotSentYet { .. }) => {
                (freya_icons::lucide::clock(), c.on_surface_muted)
            }
            Some(EventSendState::SendingFailed { .. }) => {
                (freya_icons::lucide::circle_alert(), c.error)
            }
            _ if read => (freya_icons::lucide::check_check(), c.receipt_read),
            _ => (freya_icons::lucide::check(), c.receipt_default),
        });
        let text = if self.edited {
            format!("edited · {}", self.timestamp)
        } else {
            self.timestamp
        };
        rect()
            .horizontal()
            .cross_align(Alignment::Center)
            .spacing(4.)
            .child(label().text(text).font_size(11.).color(color))
            .maybe_child(receipt.map(|(icon, color)| {
                SvgViewer::new(icon)
                    .color(color)
                    .width(Size::px(13.))
                    .height(Size::px(13.))
            }))
    }
}
