use std::sync::Arc;

use freya::prelude::*;
use tokio::sync::mpsc::UnboundedSender;

use super::PressGuard;
use crate::ui::components::HoverableExt;
use crate::ui::pages::room::{MsgAction, Reaction};
use crate::utils::const_values::AppColors;

pub(super) const REACTION_HEIGHT: f32 = 22.;
/// How far the reactions overlap the bottom of their bubble.
const REACTION_OVERLAP: f32 = 8.;

/// The reaction pills under a bubble, overlapping its bottom edge; a tap
/// toggles ours.
pub(super) fn reactions_row(
    reactions: &[Reaction],
    event_id: Option<String>,
    action_tx: &Arc<UnboundedSender<MsgAction>>,
    guard: PressGuard,
    c: AppColors,
) -> Element {
    let pills = reactions.iter().map(|reaction| {
        let (bg, fg) = if reaction.reacted_by_me {
            (c.reaction_active_bg, c.reaction_active_text)
        } else {
            (c.reaction_default_bg, c.reaction_default_text)
        };
        let (key, event_id, tx) = (reaction.key.clone(), event_id.clone(), action_tx.clone());
        rect()
            .horizontal()
            .cross_align(Alignment::Center)
            .height(Size::px(REACTION_HEIGHT))
            .padding(Gaps::new(0., 8., 0., 8.))
            .corner_radius(REACTION_HEIGHT / 2.)
            .background(bg)
            // A ring in the page colour separates it from the bubble.
            .border(Border::new().fill(c.surface).width(2.))
            .on_press(move |_| {
                if let Some(event_id) = event_id.clone()
                    && guard.allows()
                {
                    let _ = tx.send(MsgAction::React {
                        event_id,
                        key: key.clone(),
                    });
                }
            })
            .child(
                label()
                    .text(format!("{} {}", reaction.key, reaction.count))
                    .font_size(13.)
                    .color(fg),
            )
            .hoverable(
                Size::auto(),
                Size::px(REACTION_HEIGHT),
                REACTION_HEIGHT / 2.,
            )
    });
    // Negative margins are ignored, so the holder is shorter than the pills
    // and `offset_y` (which moves its children) lifts them into the bubble.
    rect()
        .height(Size::px(REACTION_HEIGHT - REACTION_OVERLAP))
        .offset_y(-REACTION_OVERLAP)
        .layer(1)
        .child(
            rect()
                .horizontal()
                .spacing(4.)
                .padding(Gaps::new(0., 8., 0., 8.))
                .cross_align(Alignment::Center)
                .children(pills),
        )
        .into_element()
}
