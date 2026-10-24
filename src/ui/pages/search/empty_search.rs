use freya::prelude::*;
use freya_icons::lucide;

use crate::app::navigation::navigate_to_room;
use crate::ui::components::{Avatar, HoverableExt, IconButton, empty_state};
use crate::utils::avatars::AvatarSource;
use crate::utils::const_values::AppColors;
use crate::utils::room_list::RoomSummary;
use crate::utils::{id_color, recent_searches, room_list, use_app_colors, use_watch};

/// How many recent chats the empty search offers.
const RECENT_CHATS: usize = 10;

/// The search page before typing: recent chats to jump to, and recent
/// searches to run again (`query` takes the one tapped).
#[derive(PartialEq)]
pub struct EmptySearch {
    pub query: State<String>,
}

impl Component for EmptySearch {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let snapshot = use_watch(room_list::receiver());
        // Bumped on remove / clear: the list lives outside the component.
        let mut changed = use_state(|| 0u32);
        let _ = *changed.read();
        let mut query = self.query;

        let recents = recent_searches::list();
        let chats = recent_chats(&snapshot.read().rooms);
        if recents.is_empty() && chats.is_empty() {
            return empty_state(
                lucide::search(),
                "Search",
                Some("Conversations, people and messages"),
                c,
            )
            .into_element();
        }

        let mut list = rect().vertical().width(Size::fill());
        if !chats.is_empty() {
            list = list.child(header("Recent chats", None, c)).child(
                ScrollView::new()
                    .direction(Direction::Horizontal)
                    .show_scrollbar(false)
                    .width(Size::fill())
                    .height(Size::auto())
                    .child(
                        rect()
                            .horizontal()
                            .padding(Gaps::new(4., 12., 8., 12.))
                            .spacing(4.)
                            .children(chats.iter().map(|room| chat(room, c))),
                    ),
            );
        }
        if !recents.is_empty() {
            let clear = rect()
                .padding(Gaps::new(6., 10., 6., 10.))
                .on_press(move |_| {
                    recent_searches::clear();
                    *changed.write() += 1;
                })
                .child(label().text("Clear").font_size(13.).color(c.primary))
                .hoverable(Size::auto(), Size::auto(), 8.);
            list = list.child(header("Recent searches", Some(clear), c));
            for recent in recents {
                let (search, removed) = (recent.clone(), recent.clone());
                list = list.child(
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .content(Content::Flex)
                        .cross_align(Alignment::Center)
                        .padding(Gaps::new(0., 8., 0., 20.))
                        .spacing(16.)
                        .on_press(move |_| query.set(search.clone()))
                        .child(
                            SvgViewer::new(lucide::history())
                                .width(Size::px(20.))
                                .height(Size::px(20.))
                                .color(c.on_surface_variant),
                        )
                        .child(
                            label()
                                .width(Size::flex(1.))
                                .text(recent)
                                .max_lines(1)
                                .text_overflow(TextOverflow::Ellipsis)
                                .font_size(16.)
                                .color(c.on_surface),
                        )
                        .child(
                            IconButton::new(lucide::x(), c.on_surface_variant, move |_| {
                                recent_searches::remove(&removed);
                                *changed.write() += 1;
                            })
                            .tooltip("Remove")
                            .size(40., 18.),
                        )
                        .hoverable(Size::fill(), Size::px(52.), 0.),
                );
            }
        }

        ScrollView::new()
            .width(Size::fill())
            .height(Size::fill())
            .child(list)
            .into_element()
    }
}

/// Joined rooms with the newest messages.
fn recent_chats(rooms: &[RoomSummary]) -> Vec<RoomSummary> {
    let mut chats: Vec<RoomSummary> = rooms.iter().filter(|r| !r.is_invite).cloned().collect();
    chats.sort_by_key(|r| std::cmp::Reverse(r.latest_ts.unwrap_or(0)));
    chats.truncate(RECENT_CHATS);
    chats
}

fn header(title: &'static str, trailing: Option<Element>, c: AppColors) -> Element {
    rect()
        .horizontal()
        .width(Size::fill())
        .height(Size::px(40.))
        .content(Content::Flex)
        .cross_align(Alignment::Center)
        .padding(Gaps::new(8., 8., 0., 20.))
        .child(
            label()
                .width(Size::flex(1.))
                .text(title)
                .font_size(13.)
                .font_weight(FontWeight::MEDIUM)
                .color(c.primary),
        )
        .maybe_child(trailing)
        .into()
}

fn chat(room: &RoomSummary, c: AppColors) -> Element {
    let room_id = room.room_id.clone();
    rect()
        .width(Size::px(76.))
        .vertical()
        .cross_align(Alignment::Center)
        .padding(Gaps::new(6., 4., 6., 4.))
        .spacing(6.)
        .on_press(move |_| navigate_to_room(room_id.clone()))
        .child(Avatar {
            size: 56.,
            source: Some(AvatarSource::Room(room.room_id.clone())),
            name: room.name.clone(),
            color: id_color(&room.room_id),
        })
        .child(
            label()
                .width(Size::fill())
                .text(room.name.clone())
                .max_lines(2)
                .text_overflow(TextOverflow::Ellipsis)
                .text_align(TextAlign::Center)
                .font_size(12.)
                .color(c.on_surface),
        )
        .hoverable(Size::px(76.), Size::auto(), 12.)
}
