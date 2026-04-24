use freya::prelude::*;
use freya_router::prelude::RouterContext;

use crate::{Route, utils::const_values::AppColors, utils::matrix::CLIENT};

pub(super) fn room_tab(
    room_name: State<String>,
    mut room_creating: State<bool>,
    mut room_status: State<Option<String>>,
    c: AppColors,
) -> impl IntoElement {
    let is_creating = *room_creating.read();
    let status = room_status.read().clone();

    let mut do_create = move || {
        let name = room_name.read().trim().to_string();
        if name.is_empty() {
            return;
        }
        *room_creating.write() = true;
        *room_status.write() = None;
        spawn(async move {
            let Some(client) = CLIENT.get().cloned() else {
                return;
            };
            let (tx, rx) = tokio::sync::oneshot::channel::<Result<String, String>>();
            tokio::task::spawn(async move {
                let result = (|| async {
                    use matrix_sdk::ruma::api::client::room::create_room;
                    let mut request = create_room::v3::Request::new();
                    request.name = Some(name);
                    let room = client
                        .create_room(request)
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
                    *room_status.write() = Some(format!("Error: {e}"));
                }
                Err(_) => {}
            }
            *room_creating.write() = false;
        });
    };
    let mut do_create_submit = do_create.clone();

    rect()
        .vertical()
        .width(Size::fill())
        .height(Size::flex(1.0))
        .padding(Gaps::new(16., 16., 16., 16.))
        .spacing(12.)
        .child(
            label()
                .text("Room name")
                .font_size(13.)
                .color(c.on_surface_muted),
        )
        .child(
            rect()
                .width(Size::fill())
                .corner_radius(8.)
                .background(c.surface_container)
                .padding(Gaps::new(0., 4., 0., 12.))
                .child(
                    Input::new(room_name)
                        .flat()
                        .placeholder("Enter room name…")
                        .width(Size::fill())
                        .on_submit(move |_: String| do_create_submit()),
                ),
        )
        .child(
            Button::new()
                .on_press(move |_| do_create())
                .child(if is_creating {
                    "Creating…"
                } else {
                    "Create Room"
                }),
        )
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
