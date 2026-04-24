use freya::prelude::*;
use freya_router::prelude::RouterContext;
use matrix_sdk::ruma::UserId;

use crate::{Route, utils::const_values::AppColors, utils::matrix::CLIENT};

pub(super) fn dm_tab(
    dm_search: State<String>,
    mut dm_results: State<Vec<(String, String)>>,
    mut dm_searching: State<bool>,
    dm_status: State<Option<String>>,
    c: AppColors,
) -> impl IntoElement {
    let is_searching = *dm_searching.read();
    let results = dm_results.read().clone();
    let status = dm_status.read().clone();

    let mut do_search = move || {
        let query = dm_search.read().clone();
        if query.is_empty() {
            return;
        }
        *dm_searching.write() = true;
        *dm_results.write() = vec![];
        spawn(async move {
            let Some(client) = CLIENT.get().cloned() else {
                return;
            };
            let (tx, rx) = tokio::sync::oneshot::channel::<Vec<(String, String)>>();
            tokio::task::spawn(async move {
                let results = match client.search_users(&query, 10).await {
                    Ok(r) => r
                        .results
                        .into_iter()
                        .map(|u| {
                            let name = u
                                .display_name
                                .unwrap_or_else(|| u.user_id.localpart().to_string());
                            (u.user_id.to_string(), name)
                        })
                        .collect(),
                    Err(_) => vec![],
                };
                let _ = tx.send(results);
            });
            if let Ok(r) = rx.await {
                *dm_results.write() = r;
            }
            *dm_searching.write() = false;
        });
    };
    let mut do_search_submit = do_search.clone();

    rect()
        .vertical()
        .width(Size::fill())
        .height(Size::flex(1.0))
        .padding(Gaps::new(16., 16., 16., 16.))
        .spacing(12.)
        .child(
            rect()
                .horizontal()
                .content(Content::Flex)
                .width(Size::fill())
                .spacing(8.)
                .child(
                    rect()
                        .width(Size::flex(1.0))
                        .corner_radius(8.)
                        .background(c.surface_container)
                        .padding(Gaps::new(0., 4., 0., 12.))
                        .child(
                            Input::new(dm_search)
                                .flat()
                                .placeholder("Search by user ID or name…")
                                .width(Size::fill())
                                .on_submit(move |_: String| do_search_submit()),
                        ),
                )
                .child(
                    Button::new()
                        .on_press(move |_| do_search())
                        .child(if is_searching { "…" } else { "Search" }),
                ),
        )
        .child(if is_searching {
            rect()
                .center()
                .width(Size::fill())
                .child(CircularLoader::new().size(24.))
                .into_element()
        } else if results.is_empty() {
            rect().into_element()
        } else {
            let mut list = rect().vertical().spacing(4.).width(Size::fill());
            for (uid, display_name) in results {
                let uid_press = uid.clone();
                list = list.child(
                    rect()
                        .horizontal()
                        .content(Content::Flex)
                        .width(Size::fill())
                        .padding(Gaps::new(10., 12., 10., 12.))
                        .corner_radius(8.)
                        .background(c.surface_container)
                        .spacing(12.)
                        .cross_align(Alignment::Center)
                        .overflow(Overflow::Clip)
                        .on_press(move |_| {
                            let uid = uid_press.clone();
                            let mut dm_status = dm_status;
                            spawn(async move {
                                let Some(client) = CLIENT.get().cloned() else {
                                    return;
                                };
                                let (tx, rx) =
                                    tokio::sync::oneshot::channel::<Result<String, String>>();
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
                                        let _ = RouterContext::get().push(Route::RoomPage { room_id });
                                    }
                                    Ok(Err(e)) => {
                                        *dm_status.write() = Some(format!("Error: {e}"));
                                    }
                                    Err(_) => {}
                                }
                            });
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
                                .child(label().text(uid).font_size(12.).color(c.on_surface_muted)),
                        )
                        .child(
                            svg(freya_icons::lucide::message_circle())
                                .width(Size::px(18.))
                                .height(Size::px(18.))
                                .color(c.primary),
                        )
                        .into_element(),
                );
            }
            list.into_element()
        })
        .child(if let Some(msg) = status {
            label()
                .text(msg)
                .font_size(13.)
                .color(c.error)
                .into_element()
        } else {
            rect().into_element()
        })
}
