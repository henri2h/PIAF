use std::sync::Arc;
use std::sync::atomic::Ordering;

use freya_router::prelude::RouterContext;

use crate::ui::components::{TopAppBar, TopAppBarAction, TopAppBarTitle};
use crate::utils::const_values::AppColors;
use crate::{Route, WIDE_MODE};

/// Room title with search + settings actions; back button in narrow mode only.
pub(super) fn room_app_bar(room_id: &str, name: &str, c: AppColors) -> TopAppBar {
    let on_back: Option<Arc<dyn Fn()>> = if WIDE_MODE.load(Ordering::Relaxed) {
        None
    } else {
        Some(Arc::new(|| {
            let _ = RouterContext::get().push(Route::HomePage);
        }))
    };
    let push = |route: Route| -> Arc<dyn Fn()> {
        Arc::new(move || {
            let _ = RouterContext::get().push(route.clone());
        })
    };
    TopAppBar {
        title: TopAppBarTitle::Room {
            initial: name
                .chars()
                .next()
                .map(|ch| ch.to_uppercase().to_string())
                .unwrap_or_else(|| "?".to_string()),
            color: c.primary,
            room_id: room_id.to_string(),
            name: name.to_string(),
        },
        on_back,
        actions: vec![
            TopAppBarAction::IconButton {
                icon: freya_icons::lucide::search(),
                on_press: push(Route::RoomSearch {
                    room_id: room_id.to_string(),
                }),
            },
            TopAppBarAction::IconButton {
                icon: freya_icons::lucide::settings(),
                on_press: push(Route::RoomSettings {
                    room_id: room_id.to_string(),
                }),
            },
        ],
    }
}
