use std::sync::Arc;

use freya::prelude::*;

use freya_router::prelude::RouterContext;

use crate::{
    Route,
    ui::components::{M3ListItem, PersonRow, TopAppBar, TopAppBarTitle, search_input},
    utils::use_app_colors,
};

pub mod draft;
mod group_config;
mod group_invite;
mod pending_dm;
mod pending_group;
mod use_user_search;

pub use group_config::NewGroupConfig;
pub use group_invite::NewGroup;
pub use pending_dm::PendingDm;
pub use pending_group::PendingGroup;

use use_user_search::{UserSearch, use_user_search};

#[derive(PartialEq)]
pub struct NewChat;

impl Component for NewChat {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let search: State<String> = use_state(String::new);
        let user_search = use_user_search(search);
        let UserSearch {
            searching,
            suggestions,
            ..
        } = user_search;
        let status: State<Option<String>> = use_state(|| None);

        let is_searching = *searching.read();
        let is_empty_search = search.read().trim().is_empty();

        // Show search results, or suggestions when search box is empty.
        // When a query is active, also include matching m.direct contacts (bridged accounts are
        // never in the user directory but do appear in m.direct).
        let display_list = user_search.shown(&search.read());
        let status_msg = status.read().clone();
        let has_suggestions = !suggestions.read().is_empty();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("New Chat".to_string()),
                on_back: Some(Arc::new(crate::app::navigation::go_back_or_home)),
                actions: vec![],
            })
            // "Create a group" list item
            .child(M3ListItem {
                icon: freya_icons::lucide::users(),
                item_label: "Create a group".to_string(),
                sublabel: None,
                icon_color: c.primary,
                destructive: false,
                on_press: EventHandler::new(|_| {
                    let _ = RouterContext::get().push(Route::NewGroup);
                }),
            })
            // Divider + section label
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::px(1.))
                    .background(c.outline_variant),
            )
            .child(
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(12., 16., 4., 16.))
                    .child(
                        label()
                            .text("Direct message")
                            .font_size(13.)
                            .color(c.on_surface_muted),
                    ),
            )
            // Search input (auto-focus)
            .child(
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(4., 16., 8., 16.))
                    .child(search_input(search, "Search by user ID or name…", c).auto_focus(true)),
            )
            // Results / spinner / suggestions
            .child(if is_searching {
                rect()
                    .width(Size::fill())
                    .height(Size::px(80.))
                    .center()
                    .child(CircularLoader::new().size(28.))
                    .into_element()
            } else {
                let count = display_list.len();
                let show_label = is_empty_search && has_suggestions && count > 0;
                let mut list = rect()
                    .vertical()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .content(Content::Flex);
                if show_label {
                    list = list.child(
                        rect()
                            .width(Size::fill())
                            .padding(Gaps::new(4., 16., 4., 16.))
                            .child(
                                label()
                                    .text("Recent contacts")
                                    .font_size(12.)
                                    .color(c.on_surface_muted),
                            ),
                    );
                }
                list.child(
                    VirtualScrollView::new_with_data(display_list, move |item, users| {
                        let Some(user) = users.get(item.index).cloned() else {
                            return rect().into_element();
                        };
                        let key = user.user_id.clone();
                        let row =
                            PersonRow::new(&user.user_id, &user.display_name, user.avatar.clone())
                                .trailing(
                                    SvgViewer::new(freya_icons::lucide::message_circle())
                                        .width(Size::px(18.))
                                        .height(Size::px(18.))
                                        .color(c.primary),
                                )
                                .on_press(move |_| crate::app::navigation::open_dm(user.clone()));
                        rect()
                            .key(key)
                            .width(Size::fill())
                            .height(Size::px(62.))
                            .child(row)
                            .into_element()
                    })
                    .length(count)
                    .item_size(62.)
                    .height(Size::flex(1.0)),
                )
                .into_element()
            })
            // Error status
            .maybe_child(status_msg.map(|msg| {
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(4., 16., 8., 16.))
                    .child(label().text(msg).font_size(13.).color(c.error))
            }))
    }
}
