use std::collections::HashSet;

use freya::prelude::*;

use crate::ui::components::picked_users;
use freya_icons::lucide;

use crate::ui::components::{PersonRow, SearchBox, TopAppBar};
use crate::ui::pages::new_chat::use_user_search::{UserSearch, use_user_search};
use crate::utils::users::UserInfo;
use crate::utils::{on_tokio, use_app_colors};

/// Invite people to an existing room: search, pick, invite.
#[derive(PartialEq)]
pub struct RoomInvite {
    pub room_id: String,
}

impl Component for RoomInvite {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let search: State<String> = use_state(String::new);
        let user_search = use_user_search(search);
        let UserSearch { searching, .. } = user_search;
        let mut picked: State<Vec<UserInfo>> = use_state(Vec::new);
        // Already in the room (joined or invited): shown, not pickable.
        let mut in_room: State<HashSet<String>> = use_state(HashSet::new);
        let mut sending = use_state(|| false);
        let mut error: State<Option<String>> = use_state(|| None);

        let room_id = self.room_id.clone();
        use_hook(move || {
            spawn(async move {
                let ids = on_tokio(async move {
                    let room = crate::utils::matrix::get_room(&room_id)?;
                    let members = room
                        .members_no_sync(
                            matrix_sdk::RoomMemberships::JOIN | matrix_sdk::RoomMemberships::INVITE,
                        )
                        .await
                        .ok()?;
                    Some(members.iter().map(|m| m.user_id().to_string()).collect())
                })
                .await
                .flatten();
                if let Some(ids) = ids {
                    in_room.set(ids);
                }
            });
        });

        let picked_now = picked.read().clone();
        let picked_ids: HashSet<String> = picked_now.iter().map(|u| u.user_id.clone()).collect();
        let shown = user_search.shown(&search.read());
        let is_sending = *sending.read();

        let room_id = self.room_id.clone();
        let invite = move |_| {
            let users = picked.peek().clone();
            if users.is_empty() || *sending.peek() {
                return;
            }
            sending.set(true);
            error.set(None);
            let room_id = room_id.clone();
            spawn(async move {
                let failed = on_tokio(async move {
                    let room = crate::utils::matrix::get_room(&room_id)?;
                    let mut failed = vec![];
                    for user in users {
                        let ok = match matrix_sdk::ruma::UserId::parse(&user.user_id) {
                            Ok(id) => room.invite_user_by_id(&id).await.is_ok(),
                            Err(_) => false,
                        };
                        if !ok {
                            failed.push(user.display_name);
                        }
                    }
                    Some(failed)
                })
                .await
                .flatten();
                sending.set(false);
                match failed {
                    Some(failed) if failed.is_empty() => crate::app::navigation::go_back_or_home(),
                    Some(failed) => {
                        error.set(Some(format!("Could not invite {}", failed.join(", "))))
                    }
                    None => error.set(Some("Could not invite: room not found".into())),
                }
            });
        };

        let chips = (!picked_now.is_empty()).then(|| {
            picked_users(
                &picked_now,
                move |user_id| picked.write().retain(|u| u.user_id != user_id),
                c,
            )
        });

        let results = if *searching.read() {
            rect()
                .width(Size::fill())
                .height(Size::px(80.))
                .center()
                .child(CircularLoader::new().size(28.))
                .into_element()
        } else {
            let in_room = in_room.read().clone();
            ScrollView::new()
                .width(Size::fill())
                .height(Size::flex(1.))
                .children(shown.into_iter().map(|user| {
                    let member = in_room.contains(&user.user_id);
                    let chosen = picked_ids.contains(&user.user_id);
                    let row =
                        PersonRow::new(&user.user_id, &user.display_name, user.avatar.clone());
                    let row = if member {
                        row.subtitle("In this room")
                    } else {
                        let user = user.clone();
                        row.trailing(
                            SvgViewer::new(if chosen {
                                lucide::circle_check()
                            } else {
                                lucide::circle_plus()
                            })
                            .width(Size::px(22.))
                            .height(Size::px(22.))
                            .color(if chosen {
                                c.primary
                            } else {
                                c.on_surface_variant
                            }),
                        )
                        .on_press(move |_| {
                            let mut list = picked.write();
                            if list.iter().any(|u| u.user_id == user.user_id) {
                                list.retain(|u| u.user_id != user.user_id);
                            } else {
                                list.push(user.clone());
                            }
                        })
                    };
                    rect()
                        .key(&user.user_id)
                        .width(Size::fill())
                        .child(row)
                        .into_element()
                }))
                .into_element()
        };

        let count = picked_now.len();
        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar::new("Add people"))
            .child(
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 16., 8., 16.))
                    .child(SearchBox {
                        value: search,
                        placeholder: "Search by name or user ID…",
                        auto_focus: true,
                    }),
            )
            .maybe_child(chips)
            .maybe_child(error.read().clone().map(|e| {
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(0., 16., 8., 16.))
                    .child(label().text(e).font_size(13.).color(c.error))
            }))
            .child(results)
            .maybe_child((count > 0).then(|| {
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 16., 12., 16.))
                    .child(
                        Button::new()
                            .filled()
                            .expanded()
                            .width(Size::fill())
                            .enabled(!is_sending)
                            .on_press(invite)
                            .child(if is_sending {
                                "Inviting…".to_string()
                            } else if count == 1 {
                                "Invite 1 person".to_string()
                            } else {
                                format!("Invite {count} people")
                            }),
                    )
            }))
    }
}
