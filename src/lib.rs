use std::sync::OnceLock;
use std::sync::atomic::{AtomicBool, Ordering};

use freya::prelude::*;
#[cfg(target_os = "android")]
use freya_router::prelude::RouterContext;
use freya_router::prelude::{Outlet, Routable, Router, RouterConfig, use_route};
use tokio::sync::watch;

#[cfg(target_os = "android")]
use freya_icons::lucide;
#[cfg(target_os = "android")]
use freya_material_design::prelude::FloatingTabRippleExt;

pub mod ui;
pub mod utils;

use ui::pages::{
    home::HomePage,
    login::LoginPage,
    new_chat::{NewChat, NewGroup, NewGroupConfig, PendingDm, PendingGroup},
    reactions::ReactionsPage,
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
use utils::use_tokio_track_watcher;

pub static REQUESTER: OnceLock<utils::worker::Requester> = OnceLock::new();
pub static SYNC_TX: OnceLock<watch::Sender<()>> = OnceLock::new();
pub static SYNC_RX: OnceLock<watch::Receiver<()>> = OnceLock::new();
pub static ACTIVE_ROOM_TX: OnceLock<watch::Sender<Option<String>>> = OnceLock::new();
pub static ACTIVE_ROOM_RX: OnceLock<watch::Receiver<Option<String>>> = OnceLock::new();
/// Set before navigating to open a room at a specific event. Tuple is (room_id, event_id).
pub static FOCUS_EVENT_TX: OnceLock<watch::Sender<Option<(String, String)>>> = OnceLock::new();
pub static FOCUS_EVENT_RX: OnceLock<watch::Receiver<Option<(String, String)>>> = OnceLock::new();
pub static REACTIONS_TX: OnceLock<watch::Sender<Vec<utils::ReceivedReaction>>> = OnceLock::new();
pub static REACTIONS_RX: OnceLock<watch::Receiver<Vec<utils::ReceivedReaction>>> = OnceLock::new();
/// Set to true by Layout when the window is wide enough for split-pane view.
pub static WIDE_MODE: AtomicBool = AtomicBool::new(false);
#[cfg(target_os = "android")]
pub static TOKIO_HANDLE: OnceLock<tokio::runtime::Handle> = OnceLock::new();
/// Owns the Tokio runtime created in the push-notification context (app killed).
/// Must stay alive for the process lifetime so the handle in TOKIO_HANDLE remains valid.
#[cfg(target_os = "android")]
pub static PUSH_RT: OnceLock<tokio::runtime::Runtime> = OnceLock::new();
/// True while no sync batch has completed yet (initial loading phase).
/// Set to false by matrix_sync after the first successful batch.
pub static SYNCING: AtomicBool = AtomicBool::new(true);

pub fn app() -> impl IntoElement {
    Router::<Route>::new(|| RouterConfig::default().with_initial_path(Route::WelcomePage))
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
        #[route("/new-group")]
        NewGroup,
        #[route("/new-group/config")]
        NewGroupConfig,
        #[route("/pending-dm/:user_id")]
        PendingDm { user_id: String },
        #[route("/pending-group")]
        PendingGroup,
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
        #[route("/reactions")]
        ReactionsPage,
}

#[derive(PartialEq)]
struct Layout;

// ── Desktop layout ────────────────────────────────────────────────────────────
#[cfg(not(target_os = "android"))]
impl Component for Layout {
    fn render(&self) -> impl IntoElement {
        use_init_theme(|| effective_theme(utils::matrix::load_theme_is_dark()));

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
                            .background((220, 222, 226)),
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
                            .background((220, 222, 226)),
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
                            .background((220, 222, 226)),
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

// ── Android layout: single-panel with bottom navigation bar ──────────────────
#[cfg(target_os = "android")]
impl Component for Layout {
    fn render(&self) -> impl IntoElement {
        use_init_theme(|| effective_theme(utils::matrix::load_theme_is_dark()));
        let c = utils::use_app_colors();

        let route = use_route::<Route>();

        // Show the navbar on all post-login pages; hide on auth flow.
        let show_navbar = matches!(
            route,
            Route::HomePage
                | Route::Settings
                | Route::SettingsProfile
                | Route::SettingsSecurity
                | Route::SettingsNotifications
                | Route::SettingsAppearance
                | Route::NewChat
                | Route::NewGroup
                | Route::NewGroupConfig
                | Route::PendingDm { .. }
                | Route::PendingGroup
                | Route::RoomPage { .. }
                | Route::RoomSearch { .. }
                | Route::RoomSettings { .. }
                | Route::RoomMediaPage { .. }
                | Route::RoomMembers { .. }
                | Route::ReactionsPage
        );

        rect()
            .vertical()
            .expanded()
            .native_router()
            .on_global_key_down(|e: Event<KeyboardEventData>| {
                if e.key == Key::Named(NamedKey::BrowserBack) {
                    let router = RouterContext::get();
                    if router.can_go_back() {
                        router.go_back();
                    } else {
                        std::process::exit(0);
                    }
                }
            })
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .child(Outlet::<Route>::new()),
            )
            .child(if show_navbar {
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .main_align(Alignment::center())
                    .padding(Gaps::new(4., 4., 20., 4.))
                    .spacing(4.)
                    .background(c.surface)
                    .child(navbar_tab(Route::HomePage, "Chats", lucide::message_circle))
                    .child(navbar_tab(Route::Settings, "Settings", lucide::settings))
                    .into_element()
            } else {
                rect().into_element()
            })
    }
}

#[cfg(target_os = "android")]
fn navbar_tab(
    route: Route,
    tab_label: &'static str,
    icon: fn() -> bytes::Bytes,
) -> ActivableRoute<Route> {
    ActivableRoute::new(
        route.clone(),
        Link::new(route).child(
            FloatingTab::new().ripple().child(
                rect()
                    .center()
                    .vertical()
                    .spacing(2.)
                    .child(svg(icon()).width(Size::px(22.)).height(Size::px(22.)))
                    .child(label().text(tab_label).font_size(11.)),
            ),
        ),
    )
    .routes(vec![])
}

#[derive(PartialEq)]
struct ActiveRoomPanel;

impl Component for ActiveRoomPanel {
    fn render(&self) -> impl IntoElement {
        let mut _room_tick: State<u64> = use_state(|| 0u64);
        use_tokio_track_watcher(
            ACTIVE_ROOM_RX
                .get()
                .expect("ACTIVE_ROOM_RX not initialized"),
            _room_tick,
        );

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

        // Room members: render members panel
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
                .child(RoomPage { room_id })
                .into_element()
        } else {
            rect()
                .expanded()
                .center()
                .child(label().text("Select a conversation").color((150, 150, 150)))
                .into_element()
        }
    }
}

// ── Android entry point ──────────────────────────────────────────────────────

#[cfg(target_os = "android")]
use winit::platform::android::activity::AndroidApp;

// ── JNI exports for UnifiedPush ──────────────────────────────────────────────

#[cfg(target_os = "android")]
mod jni_push {
    use jni::{
        JNIEnv,
        objects::{JClass, JString},
    };
    use matrix_sdk::ruma::exports::serde_json;

    /// Initialise the Rust SDK in a push-notification context (app killed).
    ///
    /// Spins up a Tokio runtime (if not already running) and restores the Matrix
    /// client from the persisted session so all enrichment JNI functions work,
    /// including decryption of E2E events.  Safe to call repeatedly — subsequent
    /// calls are no-ops when already initialised.
    ///
    /// Returns 1 on success, 0 on failure.
    #[unsafe(no_mangle)]
    pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeInitForPush(
        mut env: JNIEnv,
        _class: JClass,
        data_dir: JString,
    ) -> jni::sys::jboolean {
        if crate::TOKIO_HANDLE.get().is_some() && crate::utils::matrix::CLIENT.get().is_some() {
            return 1;
        }

        let data_dir_str: String = match env.get_string(&data_dir) {
            Ok(s) => s.into(),
            Err(_) => return 0,
        };

        if crate::TOKIO_HANDLE.get().is_none() {
            let rt = match tokio::runtime::Builder::new_multi_thread()
                .enable_all()
                .build()
            {
                Ok(r) => r,
                Err(_) => return 0,
            };
            let _ = crate::TOKIO_HANDLE.set(rt.handle().clone());
            let _ = crate::PUSH_RT.set(rt);
        }

        let handle = match crate::TOKIO_HANDLE.get() {
            Some(h) => h,
            None => return 0,
        };

        let base_dir = std::path::PathBuf::from(data_dir_str);
        let ok = handle.block_on(async move {
            crate::utils::matrix::restore_matrix_client(base_dir)
                .await
                .unwrap_or(false)
        });

        ok as jni::sys::jboolean
    }

    /// Called by Kotlin PushReceiver when a new UP endpoint is assigned.
    /// Persists the endpoint and, if the Matrix client is available, registers
    /// the HTTP pusher with the homeserver immediately.
    #[unsafe(no_mangle)]
    pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeEndpointChanged(
        mut env: JNIEnv,
        _class: JClass,
        endpoint: JString,
    ) {
        let endpoint: String = match env.get_string(&endpoint) {
            Ok(s) => s.into(),
            Err(_) => return,
        };

        let handle = match crate::TOKIO_HANDLE.get() {
            Some(h) => h,
            None => return,
        };

        if let Some(data_dir) = crate::utils::matrix::DATA_DIR.get() {
            let base_dir = data_dir.parent().unwrap_or(data_dir).to_path_buf();
            let endpoint_clone = endpoint.clone();
            handle.spawn(async move {
                crate::utils::push::persist_endpoint(&base_dir, &endpoint_clone).await;
            });
        }

        if let Some(client) = crate::utils::matrix::CLIENT.get() {
            let client = client.clone();
            handle.spawn(async move {
                crate::utils::push::register_pusher(&client, &endpoint).await;
            });
        }
    }

    /// Called by Kotlin PushReceiver to look up a room's display name from the
    /// local Matrix store. Returns null if the room is unknown or the client is
    /// not loaded. Blocks the calling Java thread for the duration of the lookup.
    #[unsafe(no_mangle)]
    pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchRoomName(
        mut env: JNIEnv,
        _class: JClass,
        room_id: JString,
    ) -> jni::sys::jstring {
        let room_id_str: String = match env.get_string(&room_id) {
            Ok(s) => s.into(),
            Err(_) => return std::ptr::null_mut(),
        };
        let handle = match crate::TOKIO_HANDLE.get() {
            Some(h) => h,
            None => return std::ptr::null_mut(),
        };
        let client = match crate::utils::matrix::CLIENT.get() {
            Some(c) => c.clone(),
            None => return std::ptr::null_mut(),
        };
        let name: Option<String> = handle.block_on(async move {
            use matrix_sdk::ruma::RoomId;
            let room_id = RoomId::parse(&room_id_str).ok()?;
            let room = client.get_room(&room_id)?;
            let dn = room.display_name().await.ok()?;
            Some(dn.to_string())
        });
        match name {
            Some(n) => env
                .new_string(n)
                .map(|s| s.into_raw())
                .unwrap_or(std::ptr::null_mut()),
            None => std::ptr::null_mut(),
        }
    }

    /// Fetch enriched notification payload (room name, sender, message body).
    /// Returns a JSON string `{"roomName":..,"senderName":..,"body":..}` or null.
    #[unsafe(no_mangle)]
    pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchNotificationPayload(
        mut env: JNIEnv,
        _class: JClass,
        room_id: JString,
        event_id: JString,
    ) -> jni::sys::jstring {
        let room_id_str: String = match env.get_string(&room_id) {
            Ok(s) => s.into(),
            Err(_) => return std::ptr::null_mut(),
        };
        let event_id_str: String = match env.get_string(&event_id) {
            Ok(s) => s.into(),
            Err(_) => return std::ptr::null_mut(),
        };
        let handle = match crate::TOKIO_HANDLE.get() {
            Some(h) => h,
            None => return std::ptr::null_mut(),
        };
        let client = match crate::utils::matrix::CLIENT.get() {
            Some(c) => c.clone(),
            None => return std::ptr::null_mut(),
        };
        let payload = handle.block_on(async move {
            crate::utils::push::fetch_notification_payload(&client, &room_id_str, &event_id_str)
                .await
        });
        match payload {
            Some(p) => {
                let json = format!(
                    r#"{{"roomName":{},"senderId":{},"senderName":{},"body":{},"isImage":{}}}"#,
                    serde_json::Value::String(p.room_name),
                    serde_json::Value::String(p.sender_id),
                    serde_json::Value::String(p.sender_display_name),
                    serde_json::Value::String(p.body),
                    p.is_image,
                );
                env.new_string(json)
                    .map(|s| s.into_raw())
                    .unwrap_or(std::ptr::null_mut())
            }
            None => std::ptr::null_mut(),
        }
    }

    /// Fetch the sender's avatar bytes for a notification (identified by room + user ID).
    #[unsafe(no_mangle)]
    pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchSenderAvatarBytes(
        mut env: JNIEnv,
        _class: JClass,
        room_id: JString,
        sender_id: JString,
    ) -> jni::sys::jbyteArray {
        let room_id_str: String = match env.get_string(&room_id) {
            Ok(s) => s.into(),
            Err(_) => return std::ptr::null_mut(),
        };
        let sender_id_str: String = match env.get_string(&sender_id) {
            Ok(s) => s.into(),
            Err(_) => return std::ptr::null_mut(),
        };
        let handle = match crate::TOKIO_HANDLE.get() {
            Some(h) => h,
            None => return std::ptr::null_mut(),
        };
        let client = match crate::utils::matrix::CLIENT.get() {
            Some(c) => c.clone(),
            None => return std::ptr::null_mut(),
        };
        let bytes = handle.block_on(async move {
            crate::utils::push::fetch_sender_avatar(&client, &room_id_str, &sender_id_str).await
        });
        match bytes {
            Some(b) => env
                .byte_array_from_slice(&b)
                .map(|a| a.into_raw())
                .unwrap_or(std::ptr::null_mut()),
            None => std::ptr::null_mut(),
        }
    }

    /// Fetch the image bytes for an image message event (notification thumbnail).
    #[unsafe(no_mangle)]
    pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchEventImageBytes(
        mut env: JNIEnv,
        _class: JClass,
        room_id: JString,
        event_id: JString,
    ) -> jni::sys::jbyteArray {
        let room_id_str: String = match env.get_string(&room_id) {
            Ok(s) => s.into(),
            Err(_) => return std::ptr::null_mut(),
        };
        let event_id_str: String = match env.get_string(&event_id) {
            Ok(s) => s.into(),
            Err(_) => return std::ptr::null_mut(),
        };
        let handle = match crate::TOKIO_HANDLE.get() {
            Some(h) => h,
            None => return std::ptr::null_mut(),
        };
        let client = match crate::utils::matrix::CLIENT.get() {
            Some(c) => c.clone(),
            None => return std::ptr::null_mut(),
        };
        let bytes = handle.block_on(async move {
            crate::utils::push::fetch_event_image(&client, &room_id_str, &event_id_str).await
        });
        match bytes {
            Some(b) => env
                .byte_array_from_slice(&b)
                .map(|a| a.into_raw())
                .unwrap_or(std::ptr::null_mut()),
            None => std::ptr::null_mut(),
        }
    }

    /// Fetch room avatar bytes for the notification large icon. Returns null if unavailable.
    #[unsafe(no_mangle)]
    pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchRoomAvatarBytes(
        mut env: JNIEnv,
        _class: JClass,
        room_id: JString,
    ) -> jni::sys::jbyteArray {
        let room_id_str: String = match env.get_string(&room_id) {
            Ok(s) => s.into(),
            Err(_) => return std::ptr::null_mut(),
        };
        let handle = match crate::TOKIO_HANDLE.get() {
            Some(h) => h,
            None => return std::ptr::null_mut(),
        };
        let client = match crate::utils::matrix::CLIENT.get() {
            Some(c) => c.clone(),
            None => return std::ptr::null_mut(),
        };
        let bytes = handle.block_on(async move {
            crate::utils::push::fetch_room_avatar(&client, &room_id_str).await
        });
        match bytes {
            Some(b) => env
                .byte_array_from_slice(&b)
                .map(|a| a.into_raw())
                .unwrap_or(std::ptr::null_mut()),
            None => std::ptr::null_mut(),
        }
    }

    /// Returns a JSON array of room IDs whose notifications should be dismissed.
    /// Input is a JSON array of {roomId, ts} objects (ts = notification display time in ms).
    /// A room is considered read if the user's read receipt post-dates the notification timestamp.
    #[unsafe(no_mangle)]
    pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeGetReadRooms(
        mut env: JNIEnv,
        _class: JClass,
        room_ids_json: JString,
    ) -> jni::sys::jstring {
        macro_rules! empty {
            () => {
                env.new_string("[]")
                    .map(|s| s.into_raw())
                    .unwrap_or(std::ptr::null_mut())
            };
        }
        let json_str: String = match env.get_string(&room_ids_json) {
            Ok(s) => s.into(),
            Err(_) => return empty!(),
        };
        let entries: Vec<(String, u64)> = {
            let arr: Vec<serde_json::Value> = serde_json::from_str(&json_str).unwrap_or_default();
            arr.into_iter()
                .filter_map(|v| {
                    let room_id = v.get("roomId")?.as_str()?.to_string();
                    let ts = v.get("ts")?.as_u64().unwrap_or(0);
                    Some((room_id, ts))
                })
                .collect()
        };
        let handle = match crate::TOKIO_HANDLE.get() {
            Some(h) => h,
            None => return empty!(),
        };
        let client = match crate::utils::matrix::CLIENT.get() {
            Some(c) => c.clone(),
            None => return empty!(),
        };
        let read_rooms = handle
            .block_on(async move { crate::utils::push::get_read_rooms(&client, entries).await });
        let result = serde_json::to_string(&read_rooms).unwrap_or_else(|_| "[]".to_string());
        env.new_string(result)
            .map(|s| s.into_raw())
            .unwrap_or(std::ptr::null_mut())
    }

    /// Called by Kotlin PushReceiver when the UP registration is revoked.
    #[unsafe(no_mangle)]
    pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeEndpointCleared(
        _env: JNIEnv,
        _class: JClass,
    ) {
        let handle = match crate::TOKIO_HANDLE.get() {
            Some(h) => h,
            None => return,
        };

        if let Some(data_dir) = crate::utils::matrix::DATA_DIR.get() {
            let base_dir = data_dir.parent().unwrap_or(data_dir).to_path_buf();
            let client = crate::utils::matrix::CLIENT.get().cloned();
            handle.spawn(async move {
                if let Some(client) = client {
                    crate::utils::push::unregister_pusher(&client, &base_dir).await;
                } else {
                    crate::utils::push::clear_endpoint(&base_dir).await;
                }
            });
        }
    }
}

#[cfg(target_os = "android")]
#[unsafe(no_mangle)]
fn android_main(droid_app: AndroidApp) {
    use freya::android::AndroidPlugin;
    use freya::prelude::NativeEvent;
    use winit::{event_loop::EventLoop, platform::android::EventLoopBuilderExtAndroid};

    android_logger::init_once(
        android_logger::Config::default().with_max_level(log::LevelFilter::Debug),
    );

    let data_path = droid_app
        .internal_data_path()
        .expect("No internal data path on Android");

    let rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("Failed to build tokio runtime");

    let _ = TOKIO_HANDLE.set(rt.handle().clone());

    // Store JavaVM and Application context so Rust can dismiss notifications via JNI
    // without needing a Kotlin-side callback. activity_as_ptr() is the Java Activity jobject.
    {
        let vm_ptr = droid_app.vm_as_ptr() as *mut jni::sys::JavaVM;
        if let Ok(vm) = unsafe { jni::JavaVM::from_raw(vm_ptr) } {
            if let Ok(mut env) = vm.attach_current_thread() {
                let activity = unsafe {
                    jni::objects::JObject::from_raw(droid_app.activity_as_ptr() as jni::sys::jobject)
                };
                let ctx_obj = env
                    .call_method(
                        &activity,
                        "getApplicationContext",
                        "()Landroid/content/Context;",
                        &[],
                    )
                    .and_then(|v| v.l());
                if let Ok(ctx_obj) = ctx_obj {
                    // Cache the app's ClassLoader so background threads can resolve
                    // DEX classes via find_app_class() instead of env.find_class().
                    let loader = env
                        .call_method(&ctx_obj, "getClassLoader", "()Ljava/lang/ClassLoader;", &[])
                        .and_then(|v| v.l())
                        .and_then(|obj| env.new_global_ref(obj));
                    if let Ok(global) = loader {
                        let _ = crate::utils::push::APP_CLASS_LOADER.set(global);
                    }
                    if let Ok(global) = env.new_global_ref(&ctx_obj) {
                        let _ = crate::utils::push::ANDROID_APP_CONTEXT.set(global);
                    }
                }
            }
            let _ = crate::utils::push::JAVA_VM.set(vm);
        }
    }

    // Initialize workers while runtime is active; spawned tasks keep running after block_on.
    rt.block_on(async {
        let requester = utils::worker::client::MatrixClientWorker::spawn();
        REQUESTER.set(requester).unwrap();

        let (sync_tx, sync_rx) = tokio::sync::watch::channel(());
        SYNC_TX.set(sync_tx).unwrap();
        SYNC_RX.set(sync_rx).unwrap();

        let (active_room_tx, active_room_rx) = tokio::sync::watch::channel::<Option<String>>(None);
        ACTIVE_ROOM_TX.set(active_room_tx).unwrap();
        ACTIVE_ROOM_RX.set(active_room_rx).unwrap();

        let (focus_event_tx, focus_event_rx) =
            tokio::sync::watch::channel::<Option<(String, String)>>(None);
        FOCUS_EVENT_TX.set(focus_event_tx).unwrap();
        FOCUS_EVENT_RX.set(focus_event_rx).unwrap();

        let (reactions_tx, reactions_rx) =
            tokio::sync::watch::channel::<Vec<utils::ReceivedReaction>>(vec![]);
        REACTIONS_TX.set(reactions_tx).unwrap();
        REACTIONS_RX.set(reactions_rx).unwrap();

        tokio::spawn(async move {
            match utils::matrix::restore_matrix_client(data_path).await {
                Ok(available) => println!("Client available: {available}"),
                Err(e) => println!("Could not restore client: {e:#}"),
            }
            let _ = SYNC_TX.get().map(|tx| tx.send(()));
        });
    });

    // Keep the runtime as "current" so freya's internal tokio::spawn calls work.
    let _rt_guard = rt.enter();

    let event_loop = EventLoop::<NativeEvent>::with_user_event()
        .with_android_app(droid_app.clone())
        .build()
        .expect("Failed to build event loop");

    launch(
        LaunchConfig::new()
            .with_plugin(AndroidPlugin::new(droid_app))
            .with_window(WindowConfig::new(app))
            .with_event_loop(event_loop),
    )
}

pub(crate) fn effective_theme(is_dark: bool) -> Theme {
    use utils::const_values::{piaf_dark_colors, piaf_light_colors};
    let mut theme = if is_dark { dark_theme() } else { light_theme() };
    theme.colors = if is_dark {
        piaf_dark_colors()
    } else {
        piaf_light_colors()
    };
    theme
}
