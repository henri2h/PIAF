use freya::prelude::*;

use crate::REACTIONS_RX;
use crate::ui::components::{
    ListItem, TopAppBar, empty_state, loading_state, row_time, sender_in_room,
};
use crate::utils::{ReceivedReaction, use_app_colors, use_watch};

#[derive(PartialEq)]
pub struct ReactionsPage {}

impl Component for ReactionsPage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let reactions = use_watch(REACTIONS_RX.get().expect("not initialized"));
        let reactions = reactions.read().clone();
        // Past reactions: scan recent history once per session.
        let mut loading = use_state(|| true);
        use_hook(move || {
            let rx = crate::utils::on_tokio::<(), _>(async move {
                if let Some(client) = crate::utils::matrix::CLIENT.get().cloned() {
                    crate::utils::reactions::backfill(client).await;
                }
                ()
            });
            spawn(async move {
                let _ = rx.await;
                loading.set(false);
            });
        });

        rect()
            .vertical()
            .expanded()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar::new("Reactions"))
            .child(if reactions.is_empty() && *loading.read() {
                loading_state(Some("Loading reactions…"), c).into_element()
            } else if reactions.is_empty() {
                empty_state(
                    freya_icons::lucide::heart(),
                    "No reactions yet",
                    Some("Reactions to your messages appear here"),
                    c,
                )
                .into_element()
            } else {
                let mut scroll = ScrollView::new()
                    .width(Size::fill())
                    .height(Size::flex(1.0));
                for r in reactions {
                    scroll = scroll.child(ReactionItem { reaction: r });
                }
                scroll.into_element()
            })
    }
}

#[derive(PartialEq, Clone)]
struct ReactionItem {
    reaction: ReceivedReaction,
}

impl Component for ReactionItem {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let r = &self.reaction;
        let room_id = r.room_id.clone();
        ListItem::with_headline(sender_in_room(&r.sender_display, &r.room_name, c))
            .supporting(r.message_preview.clone())
            .leading(
                rect()
                    .width(Size::px(44.))
                    .height(Size::px(44.))
                    .corner_radius(22.)
                    .background(c.surface_container)
                    .center()
                    .child(label().text(r.emoji.clone()).font_size(22.)),
            )
            .trailing(row_time(r.timestamp_ms, c))
            .on_press(move |_| crate::app::navigation::navigate_to_room(room_id.clone()))
    }
}
