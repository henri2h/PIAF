use freya::prelude::*;
use freya_router::prelude::RouterContext;
use std::sync::Arc;
use std::time::Duration;

use crate::{
    Route,
    ui::components::{Avatar, TopAppBar, TopAppBarTitle, user_color},
    utils::{matrix::CLIENT, use_app_colors},
};

use super::draft::{GROUP_DRAFT, UserInfo};
use super::load_dm_suggestions;

#[derive(PartialEq)]
pub struct NewGroup;

impl Component for NewGroup {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let search: State<String> = use_state(String::new);
        let mut results: State<Vec<UserInfo>> = use_state(Vec::new);
        let mut searching: State<bool> = use_state(|| false);
        let mut suggestions: State<Vec<UserInfo>> = use_state(Vec::new);
        let mut invitees_tick: State<u32> = use_state(|| 0u32);
        let mut search_ver: State<u64> = use_state(|| 0u64);

        // Reset draft invitees and load suggestions on mount
        use_hook(|| {
            if let Ok(mut draft) = GROUP_DRAFT.lock() {
                draft.invitees.clear();
            }
            let mut suggestions = suggestions;
            spawn(async move {
                let sug = load_dm_suggestions().await;
                *suggestions.write() = sug;
            });
        });

        // Debounced search: runs whenever search text changes
        let search_text = search.read().clone();
        use_side_effect_with_deps(&search_text, move |query: &String| {
            let query = query.clone();
            if query.trim().is_empty() {
                *results.write() = vec![];
                *searching.write() = false;
                return;
            }
            let ver = {
                let v = *search_ver.read() + 1;
                *search_ver.write() = v;
                v
            };
            let (delay_tx, delay_rx) = futures::channel::oneshot::channel::<()>();
            tokio::task::spawn(async move {
                tokio::time::sleep(Duration::from_millis(400)).await;
                let _ = delay_tx.send(());
            });
            spawn(async move {
                let _ = delay_rx.await;
                if *search_ver.read() != ver {
                    return;
                }
                *searching.write() = true;
                *results.write() = vec![];
                let Some(client) = CLIENT.get().cloned() else {
                    *searching.write() = false;
                    return;
                };
                let (tx, rx) = futures::channel::oneshot::channel::<Vec<UserInfo>>();
                tokio::task::spawn(async move {
                    let users = match client.search_users(&query, 10).await {
                        Ok(r) => r
                            .results
                            .into_iter()
                            .map(|u| UserInfo {
                                display_name: u
                                    .display_name
                                    .unwrap_or_else(|| u.user_id.localpart().to_string()),
                                avatar_mxc: u.avatar_url.map(|a| a.to_string()),
                                user_id: u.user_id.to_string(),
                            })
                            .collect(),
                        Err(_) => vec![],
                    };
                    let _ = tx.send(users);
                });
                if let Ok(users) = rx.await {
                    if *search_ver.read() == ver {
                        *results.write() = users;
                    }
                }
                if *search_ver.read() == ver {
                    *searching.write() = false;
                }
            });
        });

        let is_searching = *searching.read();
        let is_empty_search = search.read().trim().is_empty();

        let display_list: Vec<(String, String, Option<String>)> = if is_empty_search {
            suggestions
                .read()
                .iter()
                .map(|u| {
                    (
                        u.user_id.clone(),
                        u.display_name.clone(),
                        u.avatar_mxc.clone(),
                    )
                })
                .collect()
        } else {
            results
                .read()
                .iter()
                .map(|u| {
                    (
                        u.user_id.clone(),
                        u.display_name.clone(),
                        u.avatar_mxc.clone(),
                    )
                })
                .collect()
        };

        let invitee_ids: Vec<String> = GROUP_DRAFT
            .lock()
            .map(|d| d.invitees.iter().map(|u| u.user_id.clone()).collect())
            .unwrap_or_default();
        let invitee_previews: Vec<(String, String, Option<String>)> = GROUP_DRAFT
            .lock()
            .map(|d| {
                d.invitees
                    .iter()
                    .map(|u| {
                        (
                            u.user_id.clone(),
                            u.display_name.clone(),
                            u.avatar_mxc.clone(),
                        )
                    })
                    .collect()
            })
            .unwrap_or_default();
        let has_invitees = !invitee_ids.is_empty();
        let has_suggestions = !suggestions.read().is_empty();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("New Group".to_string()),
                on_back: Some(Arc::new(|| {
                    let _ = RouterContext::get().push(Route::NewChat);
                })),
                actions: vec![],
            })
            // Search input
            .child(
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 16., 8., 16.))
                    .child(
                        rect()
                            .width(Size::fill())
                            .corner_radius(8.)
                            .background(c.surface_container)
                            .padding(Gaps::new(0., 4., 0., 12.))
                            .child(
                                Input::new(search)
                                    .flat()
                                    .auto_focus(true)
                                    .placeholder("Search by user ID or name…")
                                    .width(Size::fill()),
                            ),
                    ),
            )
            // Invited users chips
            .maybe_child(if has_invitees {
                let mut row = rect()
                    .horizontal()
                    .width(Size::fill())
                    .padding(Gaps::new(4., 16., 8., 16.))
                    .spacing(8.)
                    .background(c.surface_container);
                for (uid, display_name, avatar_mxc) in &invitee_previews {
                    let uid2 = uid.clone();
                    let initial = display_name
                        .chars()
                        .next()
                        .map(|ch| ch.to_uppercase().to_string())
                        .unwrap_or_else(|| "?".to_string());
                    let color = user_color(uid);
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
                                bytes: None,
                                fetch_key: avatar_mxc.clone(),
                                initial,
                                color,
                                image_key: uid.clone(),
                            })
                            .child(
                                label()
                                    .text(display_name.chars().take(10).collect::<String>())
                                    .font_size(13.)
                                    .color(c.on_surface),
                            )
                            .child(
                                rect()
                                    .center()
                                    .width(Size::px(18.))
                                    .height(Size::px(18.))
                                    .corner_radius(9.)
                                    .background(c.outline_variant)
                                    .overflow(Overflow::Clip)
                                    .on_press(move |_| {
                                        if let Ok(mut draft) = GROUP_DRAFT.lock() {
                                            draft.invitees.retain(|u| u.user_id != uid2);
                                        }
                                        *invitees_tick.write() += 1;
                                    })
                                    .child(
                                        svg(freya_icons::lucide::x())
                                            .color(c.on_surface_variant)
                                            .width(Size::px(10.))
                                            .height(Size::px(10.)),
                                    ),
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
                for (uid, display_name, avatar_mxc) in display_list {
                    let already_added = invitee_ids.contains(&uid);
                    let initial = display_name
                        .chars()
                        .next()
                        .map(|ch| ch.to_uppercase().to_string())
                        .unwrap_or_else(|| "?".to_string());
                    let color = user_color(&uid);
                    let uid2 = uid.clone();
                    let dn2 = display_name.clone();
                    let av2 = avatar_mxc.clone();
                    list = list.child(
                        rect()
                            .horizontal()
                            .content(Content::Flex)
                            .width(Size::fill())
                            .padding(Gaps::new(10., 16., 10., 16.))
                            .spacing(12.)
                            .cross_align(Alignment::Center)
                            .child(Avatar {
                                size: 42.,
                                bytes: None,
                                fetch_key: avatar_mxc,
                                initial,
                                color,
                                image_key: uid.clone(),
                            })
                            .child(
                                rect()
                                    .vertical()
                                    .width(Size::flex(1.0))
                                    .spacing(2.)
                                    .child(
                                        label()
                                            .text(display_name)
                                            .font_size(15.)
                                            .color(c.on_surface),
                                    )
                                    .child(
                                        label()
                                            .text(uid.clone())
                                            .font_size(12.)
                                            .color(c.on_surface_muted),
                                    ),
                            )
                            .child(if already_added {
                                svg(freya_icons::lucide::check())
                                    .color(c.primary)
                                    .width(Size::px(20.))
                                    .height(Size::px(20.))
                                    .into_element()
                            } else {
                                rect()
                                    .center()
                                    .width(Size::px(32.))
                                    .height(Size::px(32.))
                                    .corner_radius(16.)
                                    .background(c.surface_container)
                                    .overflow(Overflow::Clip)
                                    .on_press(move |_| {
                                        if let Ok(mut draft) = GROUP_DRAFT.lock() {
                                            if !draft.invitees.iter().any(|u| u.user_id == uid2) {
                                                draft.invitees.push(UserInfo {
                                                    user_id: uid2.clone(),
                                                    display_name: dn2.clone(),
                                                    avatar_mxc: av2.clone(),
                                                });
                                            }
                                        }
                                        *invitees_tick.write() += 1;
                                    })
                                    .child(
                                        svg(freya_icons::lucide::plus())
                                            .color(c.primary)
                                            .width(Size::px(18.))
                                            .height(Size::px(18.)),
                                    )
                                    .into_element()
                            }),
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
                                let _ = RouterContext::get().push(Route::NewGroupConfig);
                            })
                            .child(
                                rect()
                                    .horizontal()
                                    .spacing(8.)
                                    .cross_align(Alignment::Center)
                                    .child(label().text("Next"))
                                    .child(
                                        svg(freya_icons::lucide::arrow_right())
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
