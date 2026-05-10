use freya::prelude::*;
use freya_query::prelude::*;
use freya_router::prelude::RouterContext;

use crate::ui::pages::home::{ActiveRoomCtx, room_list_item::RoomListItem};
use crate::utils::queries::FetchMutualRooms;
use crate::{Route, utils::matrix::CLIENT};

use super::Avatar;

#[derive(Clone, PartialEq)]
pub struct UserPopupInfo {
    pub user_id: String,
    pub display_name: String,
    pub initial: String,
    pub color: (u8, u8, u8),
    pub avatar_url: Option<String>,
}

#[derive(PartialEq)]
pub struct UserPopupOverlay {
    pub open: State<Option<UserPopupInfo>>,
}

impl Component for UserPopupOverlay {
    fn render(&self) -> impl IntoElement {
        let theme = use_theme();
        let colors = theme.read().colors.clone();
        let mut open = self.open;
        let info_opt = self.open.read().clone();
        let show = info_opt.is_some();

        let mut action_loading: State<bool> = use_state(|| false);

        // Provide a dummy ActiveRoomCtx so RoomListItem works inside the popup.
        let dummy_active: State<Option<String>> = use_state(|| None);
        use_hook(move || {
            provide_context_for_scope_id(ActiveRoomCtx(dummy_active), ScopeId::ROOT);
        });

        // Hooks must always be called; use empty key when no user is selected.
        let user_id_key = info_opt.as_ref().map(|i| i.user_id.clone()).unwrap_or_default();
        let mutual_query = use_query(Query::new(user_id_key, FetchMutualRooms));
        let mutual_state = mutual_query.read();
        let is_loading = mutual_state.state().is_pending() || mutual_state.state().is_loading();
        let common_room_ids = mutual_state.state().ok().cloned().unwrap_or_default();
        drop(mutual_state);

        let mut popup = Popup::new()
            .show(show)
            .on_close_request(move |_| *open.write() = None);

        if let Some(info) = info_opt {
            let fetch_key = info.avatar_url.as_ref().map(|u| format!("mxc:{u}"));

            // Resolve room IDs to Room objects.
            let common_rooms: Vec<_> = if let Some(client) = CLIENT.get() {
                common_room_ids
                    .iter()
                    .filter_map(|id| {
                        matrix_sdk::ruma::RoomId::parse(id)
                            .ok()
                            .and_then(|rid| client.get_room(&rid))
                    })
                    .collect()
            } else {
                vec![]
            };

            let dm_room_id = CLIENT.get().and_then(|client| {
                matrix_sdk::ruma::UserId::parse(&info.user_id)
                    .ok()
                    .and_then(|uid| client.get_dm_room(&uid))
                    .map(|r| r.room_id().to_string())
            });

            let common_count = common_rooms.len();
            let has_dm = dm_room_id.is_some();
            let dm_room_for_press = dm_room_id.clone();
            let user_id_for_press = info.user_id.clone();

            popup = popup
                // ── Header ────────────────────────────────────────────────────
                .child(
                    rect()
                        .horizontal()
                        .spacing(16.)
                        .cross_align(Alignment::Center)
                        .child(Avatar {
                            size: 56.,
                            bytes: None,
                            initial: info.initial.clone(),
                            color: info.color,
                            image_key: info.user_id.clone(),
                            fetch_key,
                        })
                        .child(
                            rect()
                                .vertical()
                                .spacing(2.)
                                .child(
                                    label()
                                        .text(info.display_name.clone())
                                        .font_size(18.)
                                        .font_weight(FontWeight::MEDIUM)
                                        .color(colors.text_primary),
                                )
                                .child(
                                    label()
                                        .text(info.user_id.clone())
                                        .font_size(13.)
                                        .color(colors.text_secondary),
                                ),
                        ),
                )
                // ── Rooms in common ───────────────────────────────────────────
                .maybe_child((!is_loading && common_count > 0).then(|| {
                    rect()
                        .vertical()
                        .width(Size::fill())
                        .spacing(2.)
                        .child(
                            label()
                                .text(format!(
                                    "{common_count} room{} in common",
                                    if common_count == 1 { "" } else { "s" }
                                ))
                                .font_size(12.)
                                .font_weight(FontWeight::MEDIUM)
                                .color(colors.primary),
                        )
                        .children(common_rooms.into_iter().take(4).map(|room| {
                            RoomListItem { room }.into_element()
                        }))
                }))
                // ── DM button ─────────────────────────────────────────────────
                .child(
                    rect()
                        .width(Size::fill())
                        .padding(Gaps::new(14., 0., 14., 0.))
                        .corner_radius(8.)
                        .background(colors.primary)
                        .overflow(Overflow::Clip)
                        .center()
                        .on_press(move |_| {
                            if *action_loading.read() || is_loading {
                                return;
                            }
                            *action_loading.write() = true;
                            let dm_room_id = dm_room_for_press.clone();
                            let user_id = user_id_for_press.clone();
                            spawn(async move {
                                let room_id = if let Some(id) = dm_room_id {
                                    Some(id)
                                } else {
                                    let Some(client) = CLIENT.get().cloned() else { return };
                                    let (tx, rx) =
                                        futures::channel::oneshot::channel::<Option<String>>();
                                    tokio::spawn(async move {
                                        let Ok(parsed) =
                                            matrix_sdk::ruma::UserId::parse(&user_id)
                                        else {
                                            let _ = tx.send(None);
                                            return;
                                        };
                                        use matrix_sdk::ruma::api::client::room::create_room::v3::Request as CreateRoom;
                                        let mut req = CreateRoom::new();
                                        req.is_direct = true;
                                        req.invite = vec![parsed.to_owned()];
                                        match client.create_room(req).await {
                                            Ok(room) => {
                                                let _ = tx.send(Some(
                                                    room.room_id().to_string(),
                                                ));
                                            }
                                            Err(_) => {
                                                let _ = tx.send(None);
                                            }
                                        }
                                    });
                                    rx.await.ok().flatten()
                                };
                                if let Some(id) = room_id {
                                    *open.write() = None;
                                    let _ = RouterContext::get()
                                        .push(Route::RoomPage { room_id: id });
                                }
                                *action_loading.write() = false;
                            });
                        })
                        .child(
                            label()
                                .text(if *action_loading.read() || is_loading {
                                    "Loading…"
                                } else if has_dm {
                                    "Jump to DM"
                                } else {
                                    "Send message"
                                })
                                .font_size(16.)
                                .color(colors.text_inverse),
                        ),
                );
        }

        popup
    }
}
