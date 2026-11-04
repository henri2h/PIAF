use freya::prelude::*;

use super::room_list_model::unread_conversations;
use crate::ui::components::{Avatar, HoverableExt};
use crate::utils::avatars::AvatarSource;
use crate::utils::const_values::AppColors;
use crate::utils::spaces::{self, Selection};
use crate::utils::{id_color, room_list, use_app_colors, use_watch};

pub const SPACE_RAIL_WIDTH: f32 = 64.;
const ITEM_SIZE: f32 = 44.;

/// Desktop: the joined spaces down the left of the room list, "all chats"
/// first. Picking one narrows the list to its rooms.
#[derive(PartialEq)]
pub struct SpaceRail;

impl Component for SpaceRail {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let spaces = use_watch(spaces::receiver());
        let selection = use_watch(spaces::selection());
        let snapshot = use_watch(room_list::receiver());

        let spaces = spaces.read().clone();
        let current = spaces::selected(&spaces, &selection.read()).map(|s| s.room_id.clone());
        let rooms = &snapshot.read().rooms;
        let mailbox = crate::ROOM_MAILBOX_RX
            .get()
            .expect("not initialized")
            .borrow();

        let home = rect()
            .width(Size::px(ITEM_SIZE))
            .height(Size::px(ITEM_SIZE))
            .corner_radius(ITEM_SIZE / 2.)
            .center()
            .background(c.primary_container)
            .child(
                SvgViewer::new(freya_icons::lucide::message_circle())
                    .color(c.on_primary_container)
                    .width(Size::px(20.))
                    .height(Size::px(20.)),
            );
        let column = rect()
            .vertical()
            .width(Size::fill())
            .padding(Gaps::new(8., 0., 8., 0.))
            .spacing(4.)
            .child(rail_item(
                c,
                "All chats",
                current.is_none(),
                false,
                home.into(),
                Selection::default(),
            ))
            .children(spaces.iter().map(|space| {
                let unread = unread_conversations(rooms, &mailbox, Some(&space.rooms)) > 0;
                rect()
                    .key(&space.room_id)
                    .child(rail_item(
                        c,
                        &space.name,
                        current.as_deref() == Some(space.room_id.as_str()),
                        unread,
                        Avatar {
                            size: ITEM_SIZE,
                            source: Some(AvatarSource::Room(space.room_id.clone())),
                            name: space.name.clone(),
                            color: id_color(&space.room_id),
                        }
                        .into_element(),
                        Selection {
                            space: Some(space.room_id.clone()),
                            sub: None,
                        },
                    ))
                    .into_element()
            }));

        rect()
            .width(Size::px(SPACE_RAIL_WIDTH))
            .height(Size::fill())
            .background(c.surface_container)
            .child(
                ScrollView::new()
                    .width(Size::fill())
                    .height(Size::fill())
                    .show_scrollbar(false)
                    .child(column),
            )
    }
}

/// An entry: a bar on the left edge when `selected`, a dot when `unread`,
/// the name as a tooltip.
fn rail_item(
    c: AppColors,
    name: &str,
    selected: bool,
    unread: bool,
    content: Element,
    target: Selection,
) -> Element {
    let item = rect()
        .width(Size::px(ITEM_SIZE))
        .height(Size::px(ITEM_SIZE))
        .on_press(move |_| spaces::select(target.clone()))
        .child(content)
        .maybe_child(unread.then(|| {
            rect()
                .position(Position::new_absolute().top(0.).right(0.))
                .layer(Layer::Relative(10))
                .width(Size::px(12.))
                .height(Size::px(12.))
                .corner_radius(6.)
                .border(Border::new().fill(c.surface_container).width(2.))
                .background(c.primary)
        }))
        .hoverable(Size::px(ITEM_SIZE), Size::px(ITEM_SIZE), ITEM_SIZE / 2.);
    rect()
        .horizontal()
        .width(Size::fill())
        .height(Size::px(ITEM_SIZE + 4.))
        .cross_align(Alignment::Center)
        .child(
            rect()
                .width(Size::px(4.))
                .height(Size::px(if selected { 32. } else { 0. }))
                .corner_radius(CornerRadius::new(0., 2., 2., 0.))
                .background(c.primary),
        )
        .child(
            rect()
                .width(Size::px(SPACE_RAIL_WIDTH - 8.))
                .center()
                .child(
                    TooltipContainer::new(Tooltip::new_text(name.to_string()))
                        .position(AttachedPosition::Right)
                        .child(item),
                ),
        )
        .into_element()
}

#[cfg(test)]
mod tests {
    use freya::prelude::*;
    use freya_testing::prelude::launch_test;

    use super::SpaceRail;
    use crate::utils::spaces::{self, Entry};

    fn app() -> impl IntoElement {
        use_init_theme(light_theme);
        rect()
            .width(Size::px(200.))
            .height(Size::px(400.))
            .child(SpaceRail)
    }

    fn entry(id: &str) -> Entry {
        Entry {
            room_id: id.into(),
            name: id.into(),
            level: 0,
            descendants: vec![],
        }
    }

    /// Item centres: 8px padding, then 48px items 4px apart ("All chats" first).
    fn item(index: f64) -> (f64, f64) {
        (32., 8. + index * 52. + 24.)
    }

    #[test]
    fn picks_a_space_then_all_chats() {
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let _guard = runtime.enter();
        let dir = tempfile::tempdir().unwrap();
        crate::app::state::init(dir.path().to_path_buf());
        spaces::set_for_test(spaces::build(&[entry("!rust"), entry("!matrix")]));

        let mut test = launch_test(app);
        test.sync_and_update();
        test.click_cursor(item(2.));
        test.sync_and_update();
        assert_eq!(
            spaces::selection().borrow().space.as_deref(),
            Some("!matrix")
        );

        // Spaces leaving and coming back keep the hooks in order.
        spaces::set_for_test(vec![]);
        test.sync_and_update();
        spaces::set_for_test(spaces::build(&[entry("!rust"), entry("!matrix")]));
        test.sync_and_update();

        test.click_cursor(item(0.));
        test.sync_and_update();
        assert_eq!(spaces::selection().borrow().space, None);
    }
}
