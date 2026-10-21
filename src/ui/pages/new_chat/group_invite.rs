use crate::utils::id_color;
use freya::prelude::*;

use crate::ui::components::IconButton;

use std::sync::Arc;

use crate::{
    Route,
    ui::components::{Avatar, PersonRow, TopAppBar, TopAppBarTitle, search_input},
    utils::use_app_colors,
};

use super::draft::GROUP_DRAFT;
use super::use_user_search::{UserSearch, use_user_search};

#[derive(PartialEq)]
pub struct NewGroup;

impl Component for NewGroup {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let search: State<String> = use_state(String::new);
        let user_search = use_user_search(search);
        let UserSearch {
            searching,
            suggestions,
            ..
        } = user_search;
        let mut invitees_tick: State<u32> = use_state(|| 0u32);

        // Start from an empty invitee list.
        use_hook(|| {
            if let Ok(mut draft) = GROUP_DRAFT.lock() {
                draft.invitees.clear();
            }
        });

        let is_searching = *searching.read();
        let is_empty_search = search.read().trim().is_empty();

        let display_list = user_search.shown(&search.read());

        let invitees = super::draft::invitees();
        let invitee_ids: Vec<String> = invitees.iter().map(|u| u.user_id.clone()).collect();
        let has_invitees = !invitee_ids.is_empty();
        let has_suggestions = !suggestions.read().is_empty();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("New Group".to_string()),
                on_back: Some(Arc::new(crate::app::navigation::go_back_or_home)),
                actions: vec![],
            })
            // Search input
            .child(
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 16., 8., 16.))
                    .child(search_input(search, "Search by user ID or name…", c).auto_focus(true)),
            )
            // Invited users chips
            .maybe_child(if has_invitees {
                let mut row = rect()
                    .horizontal()
                    .width(Size::fill())
                    .padding(Gaps::new(4., 16., 8., 16.))
                    .spacing(8.)
                    .background(c.surface_container);
                for user in &invitees {
                    let user_id = user.user_id.clone();
                    row = row.child(
                        rect()
                            .horizontal()
                            .corner_radius(20.)
                            .background(c.surface)
                            .padding(Gaps::new(4., 8., 4., 4.))
                            .spacing(6.)
                            .cross_align(Alignment::Center)
                            .child(Avatar {
                                size: 28.,
                                source: user.avatar.clone(),
                                name: user.display_name.clone(),
                                color: id_color(&user.user_id),
                            })
                            .child(
                                label()
                                    .text(user.display_name.chars().take(10).collect::<String>())
                                    .font_size(13.)
                                    .color(c.on_surface),
                            )
                            .child(
                                IconButton::new(
                                    freya_icons::lucide::x(),
                                    c.on_surface_variant,
                                    move |_| {
                                        if let Ok(mut draft) = GROUP_DRAFT.lock() {
                                            draft.invitees.retain(|u| u.user_id != user_id);
                                        }
                                        *invitees_tick.write() += 1;
                                    },
                                )
                                .size(18., 10.)
                                .background(c.outline_variant)
                                .into_element(),
                            ),
                    );
                }
                Some(row)
            } else {
                None
            })
            // Search results / spinner / suggestions
            .child(if is_searching {
                rect()
                    .width(Size::fill())
                    .height(Size::px(80.))
                    .center()
                    .child(CircularLoader::new().size(28.))
                    .into_element()
            } else {
                let show_label = is_empty_search && has_suggestions && !display_list.is_empty();
                let mut list = rect()
                    .vertical()
                    .width(Size::fill())
                    .height(Size::flex(1.0));
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
                for user in display_list {
                    let added = invitee_ids.contains(&user.user_id);
                    let key = user.user_id.clone();
                    let trailing = if added {
                        SvgViewer::new(freya_icons::lucide::check())
                            .color(c.primary)
                            .width(Size::px(20.))
                            .height(Size::px(20.))
                            .into_element()
                    } else {
                        let user = user.clone();
                        IconButton::new(freya_icons::lucide::plus(), c.primary, move |_| {
                            if let Ok(mut draft) = GROUP_DRAFT.lock()
                                && !draft.invitees.iter().any(|u| u.user_id == user.user_id)
                            {
                                draft.invitees.push(user.clone());
                            }
                            *invitees_tick.write() += 1;
                        })
                        .tooltip("Add")
                        .size(32., 18.)
                        .background(c.surface_container)
                        .into_element()
                    };
                    list = list.child(
                        rect().key(key).width(Size::fill()).child(
                            PersonRow::new(&user.user_id, &user.display_name, user.avatar.clone())
                                .trailing(trailing),
                        ),
                    );
                }
                list.into_element()
            })
            // Next button
            .child(
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(12., 16., 12., 16.))
                    .child(if has_invitees {
                        Button::new()
                            .on_press(|_| {
                                crate::app::navigation::push(Route::NewGroupConfig);
                            })
                            .child(
                                rect()
                                    .horizontal()
                                    .spacing(8.)
                                    .cross_align(Alignment::Center)
                                    .child(label().text("Next"))
                                    .child(
                                        SvgViewer::new(freya_icons::lucide::arrow_right())
                                            .width(Size::px(16.))
                                            .height(Size::px(16.)),
                                    ),
                            )
                            .into_element()
                    } else {
                        rect().into_element()
                    }),
            )
    }
}
