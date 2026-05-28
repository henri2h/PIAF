use std::sync::Arc;
use std::time::Duration;

use freya::prelude::*;
use freya_router::prelude::RouterContext;
use matrix_sdk::ruma::UserId;

use crate::{
    Route,
    ui::components::{Avatar, M3ListItem, TopAppBar, TopAppBarTitle, user_color},
    utils::{matrix::CLIENT, use_app_colors},
};

pub mod draft;
mod group_config;
mod group_invite;

pub use group_config::NewGroupConfig;
pub use group_invite::NewGroup;

use draft::UserInfo;

async fn load_dm_suggestions() -> Vec<UserInfo> {
    use matrix_sdk::ruma::events::direct::DirectEventContent;
    let Some(client) = CLIENT.get().cloned() else {
        return vec![];
    };
    let Ok(Some(raw)) = client.account().account_data::<DirectEventContent>().await else {
        return vec![];
    };
    let Ok(direct) = raw.deserialize() else {
        return vec![];
    };

    // Collect DM contacts: get cached member info from local store
    let mut suggestions = Vec::new();
    let my_id = client.user_id().map(|id| id.to_string());
    'outer: for (user, rooms) in direct.0 {
        let user_id_str = user.to_string();
        if my_id.as_deref() == Some(&user_id_str) {
            continue;
        }
        let Ok(uid) = UserId::parse(&user_id_str) else {
            continue;
        };
        for room_id in &rooms {
            let Some(room) = client.get_room(room_id) else {
                continue;
            };
            let Ok(Some(member)) = room.get_member_no_sync(&uid).await else {
                continue;
            };
            let display_name = member
                .display_name()
                .unwrap_or_else(|| uid.localpart())
                .to_string();
            let avatar_mxc = member.avatar_url().map(|u| u.to_string());
            suggestions.push(UserInfo {
                user_id: uid.to_string(),
                display_name,
                avatar_mxc,
            });
            if suggestions.len() >= 8 {
                break 'outer;
            }
            break;
        }
    }
    suggestions
}

#[derive(PartialEq)]
pub struct NewChat;

impl Component for NewChat {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let search: State<String> = use_state(String::new);
        let mut results: State<Vec<UserInfo>> = use_state(Vec::new);
        let mut searching: State<bool> = use_state(|| false);
        let mut status: State<Option<String>> = use_state(|| None);
        let mut suggestions: State<Vec<UserInfo>> = use_state(Vec::new);
        let mut search_ver: State<u64> = use_state(|| 0u64);

        // Load DM suggestions on mount
        use_hook(|| {
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

        // Show search results, or suggestions when search box is empty
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
        let status_msg = status.read().clone();
        let has_suggestions = !suggestions.read().is_empty();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("New Chat".to_string()),
                on_back: Some(Arc::new(|| {
                    let _ = RouterContext::get().push(Route::HomePage);
                })),
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
            // Results / spinner / suggestions
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
                    let uid_press = uid.clone();
                    let initial = display_name
                        .chars()
                        .next()
                        .map(|ch| ch.to_uppercase().to_string())
                        .unwrap_or_else(|| "?".to_string());
                    let color = user_color(&uid);
                    list = list.child(
                        rect()
                            .horizontal()
                            .content(Content::Flex)
                            .width(Size::fill())
                            .padding(Gaps::new(10., 16., 10., 16.))
                            .spacing(12.)
                            .cross_align(Alignment::Center)
                            .overflow(Overflow::Clip)
                            .on_press(move |_| {
                                let uid = uid_press.clone();
                                let mut status = status;
                                spawn(async move {
                                    let Some(client) = CLIENT.get().cloned() else {
                                        return;
                                    };
                                    let (tx, rx) = futures::channel::oneshot::channel::<
                                        Result<String, String>,
                                    >();
                                    tokio::task::spawn(async move {
                                        let result = (|| async {
                                            let user_id =
                                                UserId::parse(&uid).map_err(|e| e.to_string())?;
                                            let room = client
                                                .create_dm(&user_id)
                                                .await
                                                .map_err(|e| e.to_string())?;
                                            Ok::<String, String>(room.room_id().to_string())
                                        })()
                                        .await;
                                        let _ = tx.send(result);
                                    });
                                    match rx.await {
                                        Ok(Ok(room_id)) => {
                                            let _ = RouterContext::get()
                                                .push(Route::RoomPage { room_id });
                                        }
                                        Ok(Err(e)) => {
                                            *status.write() = Some(format!("Error: {e}"));
                                        }
                                        Err(_) => {}
                                    }
                                });
                            })
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
                                        label().text(uid).font_size(12.).color(c.on_surface_muted),
                                    ),
                            )
                            .child(
                                svg(freya_icons::lucide::message_circle())
                                    .width(Size::px(18.))
                                    .height(Size::px(18.))
                                    .color(c.primary),
                            ),
                    );
                }
                list.into_element()
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
