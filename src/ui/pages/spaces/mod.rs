use freya::prelude::*;

use crate::Route;
use crate::app::navigation::push;
use crate::ui::components::{Avatar, ListItem, TopAppBar, TopAppBarTitle, empty_state};
use crate::ui::pages::home::room_list_model::unread_conversations;
use crate::utils::avatars::AvatarSource;
use crate::utils::const_values::AppColors;
use crate::utils::{id_color, room_list, spaces, use_app_colors, use_watch, use_watch_tick};

mod space_page;
pub use space_page::SpacePage;

/// Android "Spaces" tab: the joined spaces; one opens its rooms.
#[derive(PartialEq)]
pub struct SpacesPage;

impl Component for SpacesPage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let spaces = use_watch(spaces::receiver());
        let snapshot = use_watch(room_list::receiver());
        let _mailbox = use_watch_tick(crate::ROOM_MAILBOX_RX.get().expect("not initialized"));

        let spaces = spaces.read().clone();
        let content = if spaces.is_empty() {
            empty_state(
                freya_icons::lucide::layers(),
                "No spaces yet",
                Some("Spaces you join appear here"),
                c,
            )
            .into_element()
        } else {
            let snapshot = snapshot.read();
            let mailbox = crate::ROOM_MAILBOX_RX
                .get()
                .expect("not initialized")
                .borrow();
            ScrollView::new()
                .width(Size::fill())
                .height(Size::flex(1.))
                .children(spaces.iter().map(|space| {
                    let joined = snapshot
                        .rooms
                        .iter()
                        .filter(|r| space.rooms.contains(&r.room_id))
                        .count();
                    let unread =
                        unread_conversations(&snapshot.rooms, &mailbox, Some(&space.rooms));
                    let space_id = space.room_id.clone();
                    let mut row = ListItem::new(space.name.clone())
                        .supporting(match joined {
                            1 => "1 room".to_string(),
                            n => format!("{n} rooms"),
                        })
                        .leading(Avatar {
                            size: 44.,
                            source: Some(AvatarSource::Room(space.room_id.clone())),
                            name: space.name.clone(),
                            color: id_color(&space.room_id),
                        })
                        .on_press(move |_| {
                            push(Route::SpacePage {
                                space_id: space_id.clone(),
                            })
                        });
                    if unread > 0 {
                        row = row.trailing(unread_badge(unread, c));
                    }
                    rect()
                        .key(&space.room_id)
                        .width(Size::fill())
                        .child(row)
                        .into_element()
                }))
                .into_element()
        };

        rect()
            .vertical()
            .expanded()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Spaces".to_string()),
                on_back: None,
                actions: vec![],
            })
            .child(content)
    }
}

fn unread_badge(count: usize, c: AppColors) -> Rect {
    rect()
        .min_width(Size::px(22.))
        .height(Size::px(22.))
        .corner_radius(11.)
        .padding(Gaps::new(0., 6., 0., 6.))
        .center()
        .background(c.primary)
        .child(
            label()
                .text(if count > 99 {
                    "99+".to_string()
                } else {
                    count.to_string()
                })
                .font_size(12.)
                .font_weight(FontWeight::MEDIUM)
                .color(c.on_primary),
        )
}
