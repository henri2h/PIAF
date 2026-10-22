use std::sync::Arc;
use std::sync::atomic::Ordering;

use crate::ui::components::{TopAppBar, TopAppBarAction, TopAppBarTitle};
use crate::{Route, WIDE_MODE};

/// Room title, with an info action when `with_actions` (search is in the
/// room's info); back button in narrow mode only.
pub(super) fn room_app_bar(room_id: &str, name: &str, with_actions: bool) -> TopAppBar {
    let on_back: Option<Arc<dyn Fn()>> = if WIDE_MODE.load(Ordering::Relaxed) {
        None
    } else {
        Some(Arc::new(crate::app::navigation::go_back_or_home))
    };
    let push = |route: Route| -> Arc<dyn Fn()> {
        Arc::new(move || crate::app::navigation::push(route.clone()))
    };
    TopAppBar {
        title: TopAppBarTitle::Room {
            color: crate::utils::id_color(room_id),
            room_id: room_id.to_string(),
            name: name.to_string(),
            // Like other messaging apps: the title opens the room's info.
            on_press: with_actions.then(|| {
                push(Route::RoomSettings {
                    room_id: room_id.to_string(),
                })
            }),
        },
        on_back,
        actions: if !with_actions {
            vec![]
        } else {
            vec![TopAppBarAction::IconButton {
                icon: freya_icons::lucide::info(),
                on_press: push(Route::RoomSettings {
                    room_id: room_id.to_string(),
                }),
            }]
        },
    }
}
