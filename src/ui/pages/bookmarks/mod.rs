use std::sync::Arc;

use freya::prelude::*;
use freya_material_design::prelude::Ripple;
use freya_router::prelude::RouterContext;
use matrix_sdk::ruma::MilliSecondsSinceUnixEpoch;

use crate::BOOKMARKS_RX;
use crate::ui::components::{TopAppBar, TopAppBarAction, TopAppBarTitle};
use crate::utils::bookmarks::{
    BookmarkEntry, BookmarkList, delete_list, mutate_bookmarks, remove_entry, rename_list,
};
use crate::utils::const_values::AppColors;
use crate::utils::{format_timestamp, use_app_colors};

#[derive(PartialEq)]
pub struct BookmarksPage {}

impl Component for BookmarksPage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let tick: State<u64> = use_state(|| 0u64);
        crate::utils::use_tokio_track_watcher(
            BOOKMARKS_RX.get().expect("BOOKMARKS_RX not initialized"),
            tick,
        );

        let lists = BOOKMARKS_RX
            .get()
            .expect("BOOKMARKS_RX not initialized")
            .borrow()
            .lists
            .clone();

        let selected: State<Option<String>> = use_state(|| None);
        let manage_open: State<bool> = use_state(|| false);

        // Effective selection: the explicitly picked list if it still exists,
        // otherwise the first list. Never written back into `selected` during
        // render — only tab presses do that.
        let selected_id = selected.read().clone();
        let current_id = selected_id
            .filter(|id| lists.iter().any(|l| &l.id == id))
            .or_else(|| lists.first().map(|l| l.id.clone()));
        let current_list = lists
            .iter()
            .find(|l| Some(&l.id) == current_id.as_ref())
            .cloned();

        rect()
            .vertical()
            .expanded()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Bookmarks".to_string()),
                on_back: Some(Arc::new(|| {
                    RouterContext::get().go_back();
                })),
                actions: vec![TopAppBarAction::IconButton {
                    icon: freya_icons::lucide::settings(),
                    on_press: Arc::new(move || *manage_open.write_unchecked() = true),
                }],
            })
            .maybe_child((!lists.is_empty()).then(|| tabs_row(&lists, current_id, selected, c)))
            .child(match current_list {
                Some(list) if !list.entries.is_empty() => {
                    let mut scroll = ScrollView::new()
                        .width(Size::fill())
                        .height(Size::flex(1.0));
                    for entry in list.entries.clone() {
                        scroll = scroll.child(BookmarkItem {
                            list_id: list.id.clone(),
                            entry,
                        });
                    }
                    scroll.into_element()
                }
                _ => empty_state(c).into_element(),
            })
            .child(ManageListsOverlay {
                open: manage_open,
                lists,
            })
    }
}

fn tabs_row(
    lists: &[BookmarkList],
    current_id: Option<String>,
    mut selected: State<Option<String>>,
    c: AppColors,
) -> Element {
    let mut row = ScrollView::new()
        .direction(Direction::Horizontal)
        .width(Size::fill())
        .height(Size::px(46.));
    for list in lists {
        let is_selected = current_id.as_deref() == Some(list.id.as_str());
        let list_id = list.id.clone();
        let bg = if is_selected {
            c.primary
        } else {
            c.surface_container
        };
        let text_color = if is_selected {
            c.on_primary
        } else {
            c.on_surface_variant
        };
        row = row.child(
            rect()
                .height(Size::px(30.))
                .margin(Gaps::new(8., 0., 8., 8.))
                .corner_radius(15.)
                .background(bg)
                .overflow(Overflow::Clip)
                .on_press(move |_| selected.set(Some(list_id.clone())))
                .child(
                    rect()
                        .horizontal()
                        .height(Size::fill())
                        .padding(Gaps::new(0., 14., 0., 14.))
                        .cross_align(Alignment::Center)
                        .child(
                            label()
                                .text(list.name.clone())
                                .font_size(13.)
                                .font_weight(FontWeight::MEDIUM)
                                .color(text_color),
                        ),
                ),
        );
    }
    row.into()
}

fn empty_state(c: AppColors) -> Element {
    rect()
        .expanded()
        .center()
        .vertical()
        .spacing(12.)
        .child(
            SvgViewer::new(freya_icons::lucide::bookmark())
                .width(Size::px(48.))
                .height(Size::px(48.))
                .color(c.outline_variant_light),
        )
        .child(
            label()
                .text("No bookmarks yet")
                .font_size(16.)
                .color(c.on_surface_muted),
        )
        .child(
            label()
                .text("Bookmark a message to start a list")
                .font_size(13.)
                .color(c.on_surface_faint),
        )
        .into()
}

#[derive(PartialEq, Clone)]
struct BookmarkItem {
    list_id: String,
    entry: BookmarkEntry,
}

impl Component for BookmarkItem {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let entry = self.entry.clone();
        let list_id = self.list_id.clone();
        let room_id = entry.room_id.clone();
        let event_id = entry.event_id.clone();

        let ts = MilliSecondsSinceUnixEpoch(
            matrix_sdk::ruma::UInt::try_from(entry.added_ts_ms).unwrap_or_default(),
        );
        let time_str = format_timestamp(ts);

        rect()
            .width(Size::fill())
            .padding(Gaps::new(2., 8., 2., 8.))
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .content(Content::Flex)
                    .padding(Gaps::new(10., 8., 10., 8.))
                    .spacing(8.)
                    .corner_radius(12.)
                    .cross_align(Alignment::Center)
                    .on_press(move |_| {
                        crate::app::navigation::navigate_to_room_at_event(
                            room_id.clone(),
                            event_id.clone(),
                        );
                    })
                    .child(
                        rect()
                            .vertical()
                            .width(Size::flex(1.0))
                            .spacing(2.)
                            .child(
                                rect()
                                    .horizontal()
                                    .width(Size::fill())
                                    .content(Content::Flex)
                                    .spacing(4.)
                                    .cross_align(Alignment::Center)
                                    .child(
                                        label()
                                            .text(entry.sender_display.clone())
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
                                            .text(entry.room_name.clone())
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
                            .child(
                                label()
                                    .text(entry.message_preview.clone())
                                    .font_size(13.)
                                    .color(c.on_surface_muted),
                            ),
                    )
                    .child(
                        rect()
                            .width(Size::px(28.))
                            .height(Size::px(28.))
                            .corner_radius(14.)
                            .overflow(Overflow::Clip)
                            .on_press({
                                let list_id = list_id.clone();
                                let room_id = entry.room_id.clone();
                                let event_id = entry.event_id.clone();
                                move |e: Event<PressEventData>| {
                                    e.stop_propagation();
                                    let list_id = list_id.clone();
                                    let room_id = room_id.clone();
                                    let event_id = event_id.clone();
                                    tokio::spawn(async move {
                                        mutate_bookmarks(|content| {
                                            remove_entry(content, &list_id, &room_id, &event_id)
                                        })
                                        .await;
                                    });
                                }
                            })
                            .child(
                                Ripple::new().color(c.error).width(Size::fill()).child(
                                    rect().center().expanded().child(
                                        SvgViewer::new(freya_icons::lucide::trash_2())
                                            .width(Size::px(16.))
                                            .height(Size::px(16.))
                                            .color(c.on_surface_muted),
                                    ),
                                ),
                            ),
                    ),
            )
    }
}

/// Popup for creating, renaming, and deleting bookmark lists.
struct ManageListsOverlay {
    open: State<bool>,
    lists: Vec<BookmarkList>,
}

impl PartialEq for ManageListsOverlay {
    fn eq(&self, other: &Self) -> bool {
        self.open == other.open && self.lists == other.lists
    }
}

impl Component for ManageListsOverlay {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut open = self.open;

        if !*self.open.read() {
            return Popup::new().into_element();
        }

        let mut new_name: State<String> = use_state(String::new);

        Popup::new()
            .on_close_request(move |_| open.set(false))
            .child(
                rect()
                    .vertical()
                    .width(Size::fill())
                    .spacing(4.)
                    .child(
                        label()
                            .text("Manage lists")
                            .font_size(16.)
                            .font_weight(FontWeight::BOLD)
                            .color(c.on_surface),
                    )
                    .children(
                        self.lists
                            .iter()
                            .map(|list| ManageListRow { list: list.clone() }.into_element()),
                    )
                    .child(
                        rect()
                            .horizontal()
                            .width(Size::fill())
                            .padding(Gaps::new(8., 4., 8., 4.))
                            .spacing(8.)
                            .cross_align(Alignment::Center)
                            .child(
                                Input::new(new_name)
                                    .placeholder("New list name")
                                    .width(Size::flex(1.0))
                                    .on_submit(move |name: String| {
                                        let name = name.trim().to_string();
                                        if name.is_empty() {
                                            return;
                                        }
                                        tokio::spawn(async move {
                                            mutate_bookmarks(|content| {
                                                crate::utils::bookmarks::create_list(content, name);
                                            })
                                            .await;
                                        });
                                        new_name.set(String::new());
                                    }),
                            ),
                    ),
            )
            .into_element()
    }
}

#[derive(PartialEq, Clone)]
struct ManageListRow {
    list: BookmarkList,
}

impl Component for ManageListRow {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let list_id = self.list.id.clone();
        let list_id_delete = self.list.id.clone();
        let mut name_draft: State<String> = use_state(|| self.list.name.clone());

        rect()
            .horizontal()
            .width(Size::fill())
            .content(Content::Flex)
            .padding(Gaps::new(6., 4., 6., 4.))
            .spacing(8.)
            .cross_align(Alignment::Center)
            .child(
                Input::new(name_draft)
                    .width(Size::flex(1.0))
                    .on_submit(move |name: String| {
                        let name = name.trim().to_string();
                        if name.is_empty() {
                            return;
                        }
                        let list_id = list_id.clone();
                        name_draft.set(name.clone());
                        tokio::spawn(async move {
                            mutate_bookmarks(|content| rename_list(content, &list_id, name)).await;
                        });
                    }),
            )
            .child(
                rect()
                    .width(Size::px(28.))
                    .height(Size::px(28.))
                    .corner_radius(14.)
                    .overflow(Overflow::Clip)
                    .on_press(move |_| {
                        let list_id = list_id_delete.clone();
                        tokio::spawn(async move {
                            mutate_bookmarks(|content| delete_list(content, &list_id)).await;
                        });
                    })
                    .child(
                        Ripple::new().color(c.error).width(Size::fill()).child(
                            rect().center().expanded().child(
                                SvgViewer::new(freya_icons::lucide::trash_2())
                                    .width(Size::px(16.))
                                    .height(Size::px(16.))
                                    .color(c.error),
                            ),
                        ),
                    ),
            )
    }
}
