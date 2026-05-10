use std::sync::OnceLock;
use std::sync::atomic::{AtomicBool, Ordering};

use freya::prelude::*;
use freya_router::prelude::{Outlet, Routable, Router, RouterConfig, RouterContext, use_route};
use tokio::sync::watch;

use crate::utils::{
    matrix::restore_matrix_client,
    use_tokio_track_watcher,
    worker::{ClientWorker, Requester},
};
use ui::pages::{
    home::HomePage,
    login::LoginPage,
    new_chat::NewChat,
    room::RoomPage,
    room_media::RoomMediaPage,
    room_members::RoomMembers,
    room_search::RoomSearch,
    room_settings::RoomSettings,
    settings::{
        Settings, SettingsAppearance, SettingsNotifications, SettingsProfile, SettingsSecurity,
    },
    welcome::WelcomePage,
};

mod ui;
mod utils;

pub static REQUESTER: OnceLock<Requester> = OnceLock::new();
pub static SYNC_TX: OnceLock<watch::Sender<()>> = OnceLock::new();
pub static SYNC_RX: OnceLock<watch::Receiver<()>> = OnceLock::new();
pub static ACTIVE_ROOM_TX: OnceLock<watch::Sender<Option<String>>> = OnceLock::new();
pub static ACTIVE_ROOM_RX: OnceLock<watch::Receiver<Option<String>>> = OnceLock::new();
pub static THEME_PREF_TX: OnceLock<watch::Sender<u8>> = OnceLock::new();
pub static THEME_PREF_RX: OnceLock<watch::Receiver<u8>> = OnceLock::new();
/// Set to true by Layout when the window is wide enough for split-pane view.
pub static WIDE_MODE: AtomicBool = AtomicBool::new(false);
/// True while no sync batch has completed yet (initial loading phase).
pub static SYNCING: AtomicBool = AtomicBool::new(true);

#[tokio::main]
async fn main() {
    println!("Starting PIAF client");

    let requester = ClientWorker::spawn().await;
    REQUESTER.set(requester).unwrap();

    let (sync_tx, sync_rx) = watch::channel(());
    SYNC_TX.set(sync_tx).unwrap();
    SYNC_RX.set(sync_rx).unwrap();

    let (active_room_tx, active_room_rx) = watch::channel::<Option<String>>(None);
    ACTIVE_ROOM_TX.set(active_room_tx).unwrap();
    ACTIVE_ROOM_RX.set(active_room_rx).unwrap();

    let base_dir = dirs::data_dir().expect("no data_dir").join("piaf");
    let saved_pref = tokio::fs::read_to_string(base_dir.join("theme_pref"))
        .await
        .ok()
        .and_then(|s| s.trim().parse::<u8>().ok())
        .unwrap_or(0);
    let (theme_pref_tx, theme_pref_rx) = watch::channel(saved_pref);
    THEME_PREF_TX.set(theme_pref_tx).unwrap();
    THEME_PREF_RX.set(theme_pref_rx).unwrap();

    tokio::spawn(async {
        let base_dir = dirs::data_dir().expect("no data_dir").join("piaf");
        match restore_matrix_client(base_dir).await {
            Ok(available) => println!("Client available: {available}"),
            Err(e) => println!("Could not restore client: {e:#}"),
        }
        let _ = crate::SYNC_TX.get().map(|tx| tx.send(()));
    });

    launch(LaunchConfig::new().with_window(WindowConfig::new(app).with_size(500., 450.)))
}

#[derive(Routable, Clone, PartialEq)]
#[rustfmt::skip]
pub enum Route {
    #[layout(Layout)]
        #[route("/")]
        HomePage,
        #[route("/welcome")]
        WelcomePage,
        #[route("/login")]
        LoginPage,
        #[route("/settings")]
        Settings,
        #[route("/settings/profile")]
        SettingsProfile,
        #[route("/settings/security")]
        SettingsSecurity,
        #[route("/settings/notifications")]
        SettingsNotifications,
        #[route("/settings/appearance")]
        SettingsAppearance,
        #[route("/new-chat")]
        NewChat,
        #[route("/room/:room_id")]
        RoomPage { room_id: String },
        #[route("/room/:room_id/search")]
        RoomSearch { room_id: String },
        #[route("/room/:room_id/settings")]
        RoomSettings { room_id: String },
        #[route("/room/:room_id/media")]
        RoomMediaPage { room_id: String },
        #[route("/room/:room_id/members")]
        RoomMembers { room_id: String },
}

fn app() -> impl IntoElement {
    Router::<Route>::new(|| RouterConfig::default().with_initial_path(Route::WelcomePage))
}

#[derive(PartialEq)]
struct Layout;
impl Component for Layout {
    fn render(&self) -> impl IntoElement {
        let mut _tpt: State<u64> = use_state(|| 0u64);
        if let Some(rx) = THEME_PREF_RX.get() {
            use_tokio_track_watcher(rx, _tpt);
        }
        let current_pref = || {
            utils::const_values::ThemePref::from_u8(
                THEME_PREF_RX.get().map(|r| *r.borrow()).unwrap_or(0),
            )
        };
        let system_theme = || *Platform::get().preferred_theme.read();

        let mut theme = use_init_theme(|| effective_theme(current_pref(), system_theme()));

        use_side_effect(move || {
            let _ = *_tpt.read();
            let pref = current_pref();
            let system = system_theme();
            theme.set(effective_theme(pref, system));
        });

        let c = utils::use_app_colors();
        let mut width: State<f32> = use_state(|| 0.0f32);
        let w = *width.read();
        let is_wide = w >= 800.0;
        // Three-panel: room list + room + settings side-by-side
        let is_three_panel = w >= 1200.0;

        WIDE_MODE.store(is_wide, Ordering::Relaxed);

        let route = use_route::<Route>();
        let settings_room = if let Route::RoomSettings { room_id } = &route {
            Some(room_id.clone())
        } else {
            None
        };
        let show_split = is_wide
            && matches!(
                route,
                Route::HomePage | Route::RoomPage { .. } | Route::RoomSettings { .. }
            );
        let show_three = is_three_panel && settings_room.is_some();

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
            .child(if show_three {
                // ── Three panels: room list | room | settings ────────────────
                let rid = settings_room.unwrap();
                rect()
                    .horizontal()
                    .expanded()
                    .content(Content::Flex)
                    .child(
                        rect()
                            .width(Size::px(400.))
                            .height(Size::fill())
                            .child(HomePage {}),
                    )
                    .child(
                        rect()
                            .width(Size::px(1.))
                            .height(Size::fill())
                            .background(c.outline_variant),
                    )
                    .child(
                        rect()
                            .key(format!("room-{rid}"))
                            .width(Size::flex(1.0))
                            .height(Size::fill())
                            .child(RoomPage {
                                room_id: rid.clone(),
                            }),
                    )
                    .child(
                        rect()
                            .width(Size::px(1.))
                            .height(Size::fill())
                            .background(c.outline_variant),
                    )
                    .child(
                        rect()
                            .key(format!("settings-{rid}"))
                            .width(Size::px(400.))
                            .height(Size::fill())
                            .child(RoomSettings { room_id: rid }),
                    )
                    .into_element()
            } else if show_split {
                // ── Two panels: room list | active panel (room or settings) ──
                rect()
                    .horizontal()
                    .expanded()
                    .content(Content::Flex)
                    .child(
                        rect()
                            .width(Size::px(400.))
                            .height(Size::fill())
                            .child(HomePage {}),
                    )
                    .child(
                        rect()
                            .width(Size::px(1.))
                            .height(Size::fill())
                            .background(c.outline_variant),
                    )
                    .child(
                        rect()
                            .width(Size::flex(1.0))
                            .height(Size::fill())
                            .child(ActiveRoomPanel),
                    )
                    .into_element()
            } else {
                Outlet::<Route>::new().into_element()
            })
    }
}

#[derive(PartialEq)]
struct ActiveRoomPanel;

impl Component for ActiveRoomPanel {
    fn render(&self) -> impl IntoElement {
        let c = utils::use_app_colors();
        let mut _room_tick: State<u64> = use_state(|| 0u64);
        if let Some(rx) = ACTIVE_ROOM_RX.get() {
            use_tokio_track_watcher(rx, _room_tick);
        }

        let route = use_route::<Route>();

        // Derive active room from route first, fall back to ACTIVE_ROOM_RX
        let route_room_id = match &route {
            Route::RoomSettings { room_id } => Some(room_id.clone()),
            Route::RoomMembers { room_id } => Some(room_id.clone()),
            Route::RoomPage { room_id } => Some(room_id.clone()),
            Route::RoomSearch { room_id } => Some(room_id.clone()),
            _ => None,
        };

        // Room settings: render settings panel
        if let Route::RoomSettings { room_id } = &route {
            return rect()
                .key(format!("settings-{room_id}"))
                .expanded()
                .child(RoomSettings {
                    room_id: room_id.clone(),
                })
                .into_element();
        }

        // Room members panel
        if let Route::RoomMembers { room_id } = &route {
            return rect()
                .key(format!("members-{room_id}"))
                .expanded()
                .child(RoomMembers {
                    room_id: room_id.clone(),
                })
                .into_element();
        }

        // Room search: render search in the right panel (room behind, search on top)
        if let Route::RoomSearch { room_id } = &route {
            return rect()
                .key(format!("search-{room_id}"))
                .expanded()
                .child(RoomSearch {
                    room_id: room_id.clone(),
                })
                .into_element();
        }

        let active_room =
            route_room_id.or_else(|| ACTIVE_ROOM_RX.get().and_then(|rx| rx.borrow().clone()));

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

fn effective_theme(pref: utils::const_values::ThemePref, system: PreferredTheme) -> Theme {
    match pref {
        utils::const_values::ThemePref::Light => PreferredTheme::Light.to_theme(),
        utils::const_values::ThemePref::Dark => PreferredTheme::Dark.to_theme(),
        utils::const_values::ThemePref::System => system.to_theme(),
    }
}
