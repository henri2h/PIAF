use freya::prelude::*;

use crate::ui::components::IconButton;
use crate::utils::const_values::AppColors;

/// What the composer is doing besides a new message.
#[derive(Clone, PartialEq)]
pub(super) enum Context {
    Editing,
    Replying { sender: String, body: String },
}

/// The card at the top of the composer pill while replying or editing; the
/// × cancels.
pub(super) fn context_card(
    context: Context,
    opacity: f32,
    on_cancel: impl FnMut(()) + 'static,
    c: AppColors,
) -> Element {
    let (icon, title, body) = match context {
        Context::Editing => (
            freya_icons::lucide::pencil(),
            "Editing message".to_string(),
            None,
        ),
        Context::Replying { sender, body } => (
            freya_icons::lucide::reply(),
            format!("Replying to {sender}"),
            Some(body),
        ),
    };
    rect()
        .opacity(opacity)
        .padding(Gaps::new(6., 6., 0., 6.))
        .width(Size::fill())
        .child(
            rect()
                .horizontal()
                .width(Size::fill())
                .content(Content::Flex)
                .cross_align(Alignment::Center)
                .corner_radius(18.)
                .overflow(Overflow::Clip)
                .background(c.reply_other_bg)
                .padding(Gaps::new(8., 4., 8., 14.))
                .spacing(10.)
                .child(
                    SvgViewer::new(icon)
                        .color(c.reply_other_sender)
                        .width(Size::px(16.))
                        .height(Size::px(16.)),
                )
                .child(
                    rect()
                        .vertical()
                        .width(Size::flex(1.))
                        .spacing(2.)
                        .child(
                            label()
                                .width(Size::fill())
                                .text(title)
                                .font_size(13.)
                                .font_weight(FontWeight::BOLD)
                                .color(c.reply_other_sender)
                                .max_lines(1)
                                .text_overflow(TextOverflow::Ellipsis),
                        )
                        .maybe_child(body.map(|body| {
                            label()
                                .width(Size::fill())
                                .text(body)
                                .font_size(13.)
                                .color(c.reply_other_text)
                                .max_lines(2)
                                .text_overflow(TextOverflow::Ellipsis)
                        })),
                )
                .child(
                    IconButton::new(freya_icons::lucide::x(), c.on_surface_variant, on_cancel)
                        .tooltip("Cancel (Esc)")
                        .size(36., 18.),
                ),
        )
        .into_element()
}
