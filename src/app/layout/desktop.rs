use std::sync::atomic::Ordering;

use freya::prelude::*;
use freya_router::prelude::{Outlet, RouterContext, use_route};

use std::time::Instant;

use super::Layout;
use crate::app::Route;
use crate::app::active_room_panel::ActiveRoomPanel;
use crate::app::keys::{
    Area, HELP, KeyCommand, KeyNav, Parsed, parse, text_input_focused, use_provide_key_nav,
};
use crate::app::state::{ACTIVE_ROOM_RX, WIDE_MODE};
use crate::app::theme::effective_theme;
use crate::ui::pages::{home::HomePage, room::RoomPage, room_settings::RoomSettings};
use crate::utils::const_values::AppColors;
use crate::utils::{matrix::load_theme_is_dark, use_app_colors, use_watch};

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

        let nav = use_provide_key_nav();
        let mut pending_g: State<Option<Instant>> = use_state(|| None);
        // Opening a room (mouse or keyboard) moves keyboard focus to it.
        let active_room = use_watch(ACTIVE_ROOM_RX.get().expect("not initialized"));
        use_side_effect(move || {
            if let Some(room_id) = active_room.read().clone() {
                let (mut area, mut selected) = (nav.area, nav.selected);
                area.set(Area::Room);
                selected.set(Some(room_id));
            }
        });
        // Narrow layouts show one pane: focus follows the route.
        if !is_wide {
            let routed = if matches!(route, Route::RoomPage { .. }) {
                Area::Room
            } else {
                Area::List
            };
            if *nav.area.peek() != routed {
                let mut area = nav.area;
                area.set(routed);
            }
        }
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
            .on_global_key_down(move |e: Event<KeyboardEventData>| {
                if e.key == Key::Named(NamedKey::BrowserBack) {
                    let router = RouterContext::get();
                    if router.can_go_back() {
                        router.go_back();
                    }
                    return;
                }
                on_key(&e, nav, pending_g, is_wide);
            })
            .child(body)
            .child(ContextMenuViewer::new())
            .maybe_child(nav.help_open.read().then(|| help_overlay(c, nav)))
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

/// Turns a key press into a command for the focused pane (see `app::keys`).
fn on_key(
    e: &Event<KeyboardEventData>,
    nav: KeyNav,
    mut pending_g: State<Option<Instant>>,
    is_wide: bool,
) {
    let mut help_open = nav.help_open;
    if *help_open.peek() {
        if matches!(&e.key, Key::Named(NamedKey::Escape)) || e.key == Key::Character("?".into()) {
            help_open.set(false);
        }
        return;
    }
    // Typing: text fields handle their own keys, including Esc to leave.
    if text_input_focused() {
        return;
    }
    let now = Instant::now();
    let pending = *pending_g.peek();
    match parse(&e.key, e.modifiers.ctrl(), pending, now) {
        Parsed::Pending => pending_g.set(Some(now)),
        Parsed::ToggleHelp => help_open.set(true),
        Parsed::Command(KeyCommand::Back) => {
            pending_g.set(None);
            if *nav.area.peek() == Area::Room {
                if is_wide {
                    let mut area = nav.area;
                    area.set(Area::List);
                } else {
                    let _ = RouterContext::get().push(Route::HomePage);
                }
            }
        }
        Parsed::Command(command) => {
            pending_g.set(None);
            nav.send(command);
        }
        Parsed::None => {}
    }
}

fn help_overlay(c: AppColors, nav: KeyNav) -> Element {
    let mut help_open = nav.help_open;
    Popup::new()
        .on_close_request(move |_| help_open.set(false))
        .child(
            rect()
                .vertical()
                .width(Size::fill())
                .spacing(8.)
                .child(
                    label()
                        .text("Keyboard shortcuts")
                        .font_size(16.)
                        .font_weight(FontWeight::BOLD)
                        .color(c.on_surface),
                )
                .children(HELP.iter().map(|(keys, what)| {
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .content(Content::Flex)
                        .child(
                            label()
                                .text(*keys)
                                .width(Size::px(140.))
                                .font_size(13.)
                                .font_weight(FontWeight::MEDIUM)
                                .color(c.primary),
                        )
                        .child(
                            label()
                                .text(*what)
                                .width(Size::flex(1.))
                                .font_size(13.)
                                .color(c.on_surface_variant),
                        )
                        .into_element()
                })),
        )
        .into_element()
}
