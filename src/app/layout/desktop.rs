use std::sync::atomic::Ordering;

use freya::prelude::*;
use freya_router::prelude::{Outlet, RouterContext, use_route};

use super::Layout;
use crate::app::Route;
use crate::app::active_room_panel::ActiveRoomPanel;
use crate::app::state::WIDE_MODE;
use crate::app::theme::effective_theme;
use crate::ui::pages::{home::HomePage, room::RoomPage, room_settings::RoomSettings};
use crate::utils::const_values::AppColors;
use crate::utils::{matrix::load_theme_is_dark, use_app_colors};

const WIDE_MIN_WIDTH: f32 = 800.;
const THREE_PANEL_MIN_WIDTH: f32 = 1200.;
const SIDE_PANEL_WIDTH: f32 = 400.;

/// Desktop: one, two (list | room) or three (list | room | settings) panels by width.
impl Component for Layout {
    fn render(&self) -> impl IntoElement {
        use_init_theme(|| effective_theme(load_theme_is_dark()));

        let c = use_app_colors();
        let mut width: State<f32> = use_state(|| 0.0f32);

        // Notifications run on tokio and can't read Freya state; mirror focus for them.
        use_side_effect(|| {
            let focused = *Platform::get().is_app_focused.read();
            crate::APP_FOCUSED.store(focused, Ordering::Relaxed);
        });
        let w = *width.read();
        let is_wide = w >= WIDE_MIN_WIDTH;
        WIDE_MODE.store(is_wide, Ordering::Relaxed);

        let route = use_route::<Route>();
        let settings_room = match &route {
            Route::RoomSettings { room_id } if w >= THREE_PANEL_MIN_WIDTH => Some(room_id.clone()),
            _ => None,
        };
        let show_split = is_wide
            && matches!(
                route,
                Route::HomePage | Route::RoomPage { .. } | Route::RoomSettings { .. }
            );

        let body = if let Some(rid) = settings_room {
            rect()
                .horizontal()
                .expanded()
                .content(Content::Flex)
                .child(side_panel(HomePage {}))
                .child(divider(c))
                .child(
                    rect()
                        .key(format!("room-{rid}"))
                        .width(Size::flex(1.0))
                        .height(Size::fill())
                        .child(RoomPage {
                            room_id: rid.clone(),
                        }),
                )
                .child(divider(c))
                .child(
                    side_panel(RoomSettings {
                        room_id: rid.clone(),
                    })
                    .key(format!("settings-{rid}")),
                )
                .into_element()
        } else if show_split {
            rect()
                .horizontal()
                .expanded()
                .content(Content::Flex)
                .child(side_panel(HomePage {}))
                .child(divider(c))
                .child(
                    rect()
                        .width(Size::flex(1.0))
                        .height(Size::fill())
                        .child(ActiveRoomPanel),
                )
                .into_element()
        } else {
            Outlet::<Route>::new().into_element()
        };

        rect()
            .center()
            .expanded()
            .on_sized(move |e: Event<SizedEventData>| {
                *width.write() = e.area.width();
            })
            .on_global_key_down(|e: Event<KeyboardEventData>| {
                if e.key == Key::Named(NamedKey::BrowserBack) {
                    let router = RouterContext::get();
                    if router.can_go_back() {
                        router.go_back();
                    }
                }
            })
            .child(body)
            .child(ContextMenuViewer::new())
    }
}

fn side_panel(child: impl IntoElement) -> Rect {
    rect()
        .width(Size::px(SIDE_PANEL_WIDTH))
        .height(Size::fill())
        .child(child)
}

fn divider(c: AppColors) -> Rect {
    rect()
        .width(Size::px(1.))
        .height(Size::fill())
        .background(c.outline_variant)
}
