use freya::prelude::*;
use freya_router::prelude::use_route;

use super::Route;
use super::state::ACTIVE_ROOM_RX;
use crate::ui::pages::{
    room::RoomPage, room_members::RoomMembers, room_search::RoomSearch, room_settings::RoomSettings,
};
use crate::utils::{use_app_colors, use_tokio_track_watcher};

/// Right panel in wide mode: a room sub-page from the route, else the active room.
#[derive(PartialEq)]
pub struct ActiveRoomPanel;

impl Component for ActiveRoomPanel {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let room_tick: State<u64> = use_state(|| 0u64);
        use_tokio_track_watcher(ACTIVE_ROOM_RX.get().expect("not initialized"), room_tick);

        let route = use_route::<Route>();

        match route {
            Route::RoomSettings { room_id } => {
                return rect()
                    .key(format!("settings-{room_id}"))
                    .expanded()
                    .child(RoomSettings { room_id })
                    .into_element();
            }
            Route::RoomMembers { room_id } => {
                return rect()
                    .key(format!("members-{room_id}"))
                    .expanded()
                    .child(RoomMembers { room_id })
                    .into_element();
            }
            Route::RoomSearch { room_id } => {
                return rect()
                    .key(format!("search-{room_id}"))
                    .expanded()
                    .child(RoomSearch { room_id })
                    .into_element();
            }
            _ => {}
        }

        let active_room = match route {
            Route::RoomPage { room_id } => Some(room_id),
            _ => ACTIVE_ROOM_RX
                .get()
                .expect("not initialized")
                .borrow()
                .clone(),
        };

        if let Some(room_id) = active_room {
            rect()
                .key(room_id.clone())
                .expanded()
                .background(c.surface)
                .child(RoomPage { room_id })
                .into_element()
        } else {
            rect()
                .expanded()
                .background(c.surface)
                .center()
                .child(
                    label()
                        .text("Select a conversation")
                        .color(c.on_surface_muted),
                )
                .into_element()
        }
    }
}
