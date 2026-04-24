use std::sync::Arc;

use freya::prelude::*;
use freya_router::prelude::RouterContext;

use crate::Route;
use crate::ui::components::{TopAppBar, TopAppBarTitle};
use crate::utils::use_app_colors;

#[derive(PartialEq)]
pub struct SettingsNotifications {}

impl Component for SettingsNotifications {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let push_endpoint: State<Option<String>> = use_state(|| None);
        let pusher_active: State<bool> = use_state(|| false);
        let push_busy: State<bool> = use_state(|| false);
        let gateway_url: State<String> = use_state(String::new);
        let _gateway_input: State<String> = use_state(String::new);
        let _gateway_saving: State<bool> = use_state(|| false);
        #[cfg(target_os = "android")]
        let (gateway_input, gateway_saving) = (_gateway_input, _gateway_saving);
        #[cfg(target_os = "android")]
        let pushers: State<Vec<crate::utils::push::PusherInfo>> = use_state(Vec::new);

        #[cfg(target_os = "android")]
        use_hook(|| {
            let mut push_endpoint = push_endpoint;
            let mut pusher_active = pusher_active;
            let mut gateway_url = gateway_url;
            let mut gateway_input = gateway_input;
            let mut pushers = pushers;
            spawn(async move {
                let Some(client) = crate::utils::matrix::CLIENT.get().cloned() else {
                    return;
                };
                let (tx, rx) = tokio::sync::oneshot::channel::<(
                    Option<String>,
                    bool,
                    String,
                    Vec<crate::utils::push::PusherInfo>,
                )>();
                tokio::task::spawn(async move {
                    let endpoint = crate::utils::push::get_current_endpoint().await;
                    let active = crate::utils::push::is_pusher_registered(&client).await;
                    let gateway = crate::utils::push::get_push_gateway().await;
                    let pusher_list = crate::utils::push::get_registered_pushers(&client).await;
                    let _ = tx.send((endpoint, active, gateway, pusher_list));
                });
                if let Ok((ep, active, gw, pusher_list)) = rx.await {
                    *push_endpoint.write() = ep;
                    *pusher_active.write() = active;
                    *gateway_url.write() = gw.clone();
                    *gateway_input.write() = gw;
                    *pushers.write() = pusher_list;
                }
            });
        });

        let _endpoint = push_endpoint.read().clone();
        let _on_server = *pusher_active.read();
        let _busy = *push_busy.read();
        let _gateway = gateway_url.read().clone();
        #[cfg(target_os = "android")]
        let pusher_list = pushers
            .read()
            .iter()
            .map(|p| {
                (
                    p.device_name.clone(),
                    p.pushkey.clone(),
                    p.app_id.clone(),
                    p.last_seen_ts,
                )
            })
            .collect::<Vec<_>>();
        #[cfg(target_os = "android")]
        let (endpoint, on_server, busy, gateway) =
            (_endpoint.clone(), _on_server, _busy, _gateway.clone());

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Notifications".to_string()),
                on_back: Some(Arc::new(|| {
                    let _ = RouterContext::get().push(Route::Settings);
                })),
                actions: vec![],
            })
            .child(
                ScrollView::new()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .child(
                        rect()
                            .vertical()
                            .width(Size::fill())
                            .padding(Gaps::new_all(24.))
                            .spacing(16.)
                            .child({
                                #[cfg(target_os = "android")]
                                let el = notifications_content(
                                    endpoint,
                                    on_server,
                                    busy,
                                    gateway,
                                    pusher_list,
                                    push_endpoint,
                                    pusher_active,
                                    push_busy,
                                    gateway_url,
                                    gateway_input,
                                    gateway_saving,
                                    c,
                                );
                                #[cfg(not(target_os = "android"))]
                                let el = label()
                                    .text("Push notifications are only available on Android.")
                                    .font_size(14.)
                                    .color(c.on_surface_muted)
                                    .into_element();
                                el
                            }),
                    ),
            )
    }
}

#[cfg(target_os = "android")]
#[allow(clippy::too_many_arguments)]
fn notifications_content(
    endpoint: Option<String>,
    on_server: bool,
    busy: bool,
    gateway: String,
    pusher_list: Vec<(String, String, String, Option<u64>)>,
    mut push_endpoint: State<Option<String>>,
    mut pusher_active: State<bool>,
    mut push_busy: State<bool>,
    mut gateway_url: State<String>,
    gateway_input: State<String>,
    mut gateway_saving: State<bool>,
    c: AppColors,
) -> Element {
    let registered = endpoint.is_some();

    let (status_label, status_color) = match (registered, on_server) {
        (true, true) => ("Active", c.status_online),
        (true, false) => ("Endpoint stored, not on server", c.error),
        (false, _) => ("Not registered", c.on_surface_muted),
    };

    let endpoint_display = endpoint.clone().map(|url| {
        if url.len() > 52 {
            format!("{}…", &url[..52])
        } else {
            url
        }
    });

    let is_saving = *gateway_saving.read();

    let mut col = rect()
        .vertical()
        .spacing(8.)
        .width(Size::fill())
        .child(super::info_row(
            "UnifiedPush",
            status_label,
            status_color,
            c,
        ));

    if let Some(display) = endpoint_display {
        col = col.child(
            rect()
                .vertical()
                .spacing(2.)
                .width(Size::fill())
                .child(
                    label()
                        .text("Endpoint")
                        .font_size(13.)
                        .color(c.on_surface_muted),
                )
                .child(
                    label()
                        .text(display)
                        .font_size(12.)
                        .color(c.on_surface_variant),
                ),
        );
    }

    col = col.child(super::section_heading("Push Gateway", c)).child(
        rect()
            .vertical()
            .spacing(4.)
            .width(Size::fill())
            .child(
                label()
                    .text("Gateway URL")
                    .font_size(13.)
                    .color(c.on_surface_muted),
            )
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
                            .child(Input::new(gateway_input).flat().width(Size::fill())),
                    )
                    .child(
                        Button::new()
                            .on_press(move |_| {
                                if is_saving {
                                    return;
                                }
                                let new_gw = gateway_input.read().clone();
                                *gateway_saving.write() = true;
                                spawn(async move {
                                    crate::utils::push::set_push_gateway(&new_gw).await;
                                    let saved = crate::utils::push::get_push_gateway().await;
                                    *gateway_url.write() = saved;
                                    *gateway_saving.write() = false;
                                });
                            })
                            .child(if is_saving { "Saving…" } else { "Save" }),
                    ),
            )
            .child(
                label()
                    .text(if gateway.is_empty() {
                        "Default: matrix.gateway.unifiedpush.org".to_string()
                    } else {
                        format!("Active: {gateway}")
                    })
                    .font_size(11.)
                    .color(c.on_surface_muted),
            ),
    );

    if !pusher_list.is_empty() {
        col = col.child(super::section_heading("Registered Sessions", c));
        for (device_name, pushkey, _app_id, last_seen_ts) in &pusher_list {
            let key_display = if pushkey.len() > 48 {
                format!("{}…", &pushkey[..48])
            } else {
                pushkey.clone()
            };
            let ts_display = last_seen_ts
                .map(|ms| {
                    use matrix_sdk::ruma::UInt;
                    if let Some(u) = UInt::new(ms) {
                        let ts = matrix_sdk::ruma::MilliSecondsSinceUnixEpoch(u);
                        format!("Last active: {}", crate::utils::format_timestamp(ts))
                    } else {
                        "Last active: unknown".to_string()
                    }
                })
                .unwrap_or_else(|| "Last active: unknown".to_string());
            col = col.child(
                rect()
                    .key(pushkey.clone())
                    .vertical()
                    .spacing(2.)
                    .width(Size::fill())
                    .padding(Gaps::new(8., 12., 8., 12.))
                    .corner_radius(8.)
                    .background(c.surface_container)
                    .child(
                        rect()
                            .horizontal()
                            .content(Content::Flex)
                            .width(Size::fill())
                            .child(
                                label()
                                    .width(Size::flex(1.0))
                                    .text(device_name.clone())
                                    .font_size(14.)
                                    .font_weight(FontWeight::MEDIUM)
                                    .color(c.on_surface),
                            )
                            .child(
                                label()
                                    .text(ts_display)
                                    .font_size(11.)
                                    .color(c.on_surface_muted),
                            ),
                    )
                    .child(
                        label()
                            .text(key_display)
                            .font_size(11.)
                            .color(c.on_surface_muted),
                    ),
            );
        }
    }

    let mut btn_row = rect()
        .horizontal()
        .spacing(8.)
        .width(Size::fill())
        .cross_align(Alignment::Center);

    btn_row = btn_row.child(
        Button::new()
            .on_press(move |_| {
                if busy {
                    return;
                }
                let Some(client) = crate::utils::matrix::CLIENT.get().cloned() else {
                    return;
                };
                *push_busy.write() = true;
                spawn(async move {
                    let result = crate::utils::push::reregister(&client).await;
                    match result {
                        Ok(ep) => {
                            *push_endpoint.write() = Some(ep);
                            *pusher_active.write() = true;
                        }
                        Err(_) => {}
                    }
                    *push_busy.write() = false;
                });
            })
            .child(if busy { "Working…" } else { "Re-register" }),
    );

    if registered {
        btn_row = btn_row.child(
            Button::new()
                .on_press(move |_| {
                    if busy {
                        return;
                    }
                    let Some(client) = crate::utils::matrix::CLIENT.get().cloned() else {
                        return;
                    };
                    *push_busy.write() = true;
                    spawn(async move {
                        let _ = crate::utils::push::unregister(&client).await;
                        *push_endpoint.write() = None;
                        *pusher_active.write() = false;
                        *push_busy.write() = false;
                    });
                })
                .child("Unregister"),
        );
    }

    col.child(btn_row).into()
}
