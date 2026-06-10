use freya::prelude::*;
use freya_router::prelude::RouterContext;
use matrix_sdk::ruma::MilliSecondsSinceUnixEpoch;
use std::sync::Arc;

use crate::ui::components::{TopAppBar, TopAppBarTitle};
use crate::utils::{format_timestamp, use_app_colors, ReceivedReaction};
use crate::REACTIONS_RX;

#[derive(PartialEq)]
pub struct ReactionsPage {}

impl Component for ReactionsPage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let tick: State<u64> = use_state(|| 0u64);
        crate::utils::use_tokio_track_watcher(
            REACTIONS_RX.get().expect("REACTIONS_RX not initialized"),
            tick,
        );

        let reactions = REACTIONS_RX
            .get()
            .expect("REACTIONS_RX not initialized")
            .borrow()
            .clone();

        rect()
            .vertical()
            .expanded()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Reactions".to_string()),
                on_back: Some(Arc::new(|| {
                    RouterContext::get().go_back();
                })),
                actions: vec![],
            })
            .child(if reactions.is_empty() {
                rect()
                    .expanded()
                    .center()
                    .vertical()
                    .spacing(12.)
                    .child(
                        label()
                            .text("No reactions yet")
                            .font_size(16.)
                            .color(c.on_surface_muted),
                    )
                    .child(
                        label()
                            .text("Reactions to your messages appear here")
                            .font_size(13.)
                            .color(c.on_surface_faint),
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
        let r = self.reaction.clone();
        let room_id = r.room_id.clone();

        let ts = MilliSecondsSinceUnixEpoch(
            matrix_sdk::ruma::UInt::try_from(r.timestamp_ms).unwrap_or_default(),
        );
        let time_str = format_timestamp(ts);

        rect()
            .width(Size::fill())
            .padding(Gaps::new(2., 8., 2., 8.))
            .on_press(move |_| {
                super::home::navigate_to_room(room_id.clone());
            })
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .content(Content::Flex)
                    .padding(Gaps::new(10., 8., 10., 8.))
                    .spacing(12.)
                    .corner_radius(12.)
                    .cross_align(Alignment::Center)
                    // Emoji pill
                    .child(
                        rect()
                            .width(Size::px(44.))
                            .height(Size::px(44.))
                            .corner_radius(22.)
                            .background(c.surface_container)
                            .center()
                            .child(label().text(r.emoji.clone()).font_size(22.)),
                    )
                    // Text column
                    .child(
                        rect()
                            .vertical()
                            .width(Size::flex(1.0))
                            .spacing(2.)
                            // Row 1: sender + room + timestamp
                            .child(
                                rect()
                                    .horizontal()
                                    .width(Size::fill())
                                    .content(Content::Flex)
                                    .spacing(4.)
                                    .cross_align(Alignment::Center)
                                    .child(
                                        label()
                                            .text(r.sender_display.clone())
                                            .font_size(14.)
                                            .font_weight(FontWeight::MEDIUM)
                                            .color(c.on_surface),
                                    )
                                    .child(
                                        label()
                                            .text("in".to_string())
                                            .font_size(13.)
                                            .color(c.on_surface_muted),
                                    )
                                    .child(
                                        label()
                                            .text(r.room_name.clone())
                                            .font_size(13.)
                                            .color(c.on_surface_muted)
                                            .width(Size::flex(1.0)),
                                    )
                                    .child(
                                        label()
                                            .text(time_str)
                                            .font_size(11.)
                                            .color(c.on_surface_faint),
                                    ),
                            )
                            // Row 2: message preview
                            .child(
                                label()
                                    .text(r.message_preview.clone())
                                    .font_size(13.)
                                    .color(c.on_surface_muted),
                            ),
                    ),
            )
    }
}
