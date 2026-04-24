use std::sync::Arc;

use freya::prelude::*;
use freya_router::prelude::RouterContext;
use matrix_sdk::encryption::{CrossSigningStatus, VerificationState};

use crate::ui::components::{TopAppBar, TopAppBarTitle};
use crate::utils::const_values::AppColors;
use crate::utils::use_app_colors;
use crate::{Route, utils::matrix::CLIENT};

#[derive(Clone, PartialEq)]
pub(super) struct DeviceInfo {
    pub device_id: String,
    pub display_name: String,
    pub is_verified: bool,
    pub is_this_device: bool,
    pub last_seen_ts: Option<u64>,
}

#[derive(Clone)]
pub(super) struct EncryptionInfo {
    pub verification_state: VerificationState,
    pub cross_signing: Option<CrossSigningStatus>,
}

#[derive(PartialEq)]
pub struct SettingsSecurity {}

impl Component for SettingsSecurity {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let devices: State<Vec<DeviceInfo>> = use_state(Vec::new);
        let encryption: State<Option<EncryptionInfo>> = use_state(|| None);

        use_hook(|| {
            let mut devices = devices;
            let mut encryption = encryption;
            spawn(async move {
                let Some(client) = CLIENT.get().cloned() else {
                    return;
                };
                let (tx, rx) = tokio::sync::oneshot::channel::<(Vec<DeviceInfo>, EncryptionInfo)>();
                tokio::task::spawn(async move {
                    let enc_info = {
                        let enc = client.encryption();
                        let verification_state = enc.verification_state().get();
                        let cross_signing = enc.cross_signing_status().await;
                        EncryptionInfo {
                            verification_state,
                            cross_signing,
                        }
                    };
                    let own_device_id = client
                        .device_id()
                        .map(|d| d.to_string())
                        .unwrap_or_default();

                    use matrix_sdk::ruma::api::client::device::get_devices;
                    let server_ts: std::collections::HashMap<String, u64> = client
                        .send(get_devices::v3::Request::new())
                        .await
                        .map(|r| {
                            r.devices
                                .into_iter()
                                .filter_map(|d| {
                                    let ts = u64::from(d.last_seen_ts?.get());
                                    Some((d.device_id.to_string(), ts))
                                })
                                .collect()
                        })
                        .unwrap_or_default();

                    let mut device_list: Vec<DeviceInfo> = if let Some(user_id) = client.user_id() {
                        client
                            .encryption()
                            .get_user_devices(user_id)
                            .await
                            .map(|ud| {
                                ud.devices()
                                    .map(|d| {
                                        let id = d.device_id().to_string();
                                        let last_seen_ts = server_ts.get(&id).copied();
                                        DeviceInfo {
                                            device_id: id.clone(),
                                            display_name: d
                                                .display_name()
                                                .unwrap_or(d.device_id().as_str())
                                                .to_string(),
                                            is_verified: d.is_verified(),
                                            is_this_device: id == own_device_id,
                                            last_seen_ts,
                                        }
                                    })
                                    .collect()
                            })
                            .unwrap_or_default()
                    } else {
                        vec![]
                    };

                    device_list.sort_by(|a, b| {
                        if a.is_this_device != b.is_this_device {
                            return b.is_this_device.cmp(&a.is_this_device);
                        }
                        b.last_seen_ts.cmp(&a.last_seen_ts)
                    });

                    let _ = tx.send((device_list, enc_info));
                });
                if let Ok((dev_list, enc_info)) = rx.await {
                    *devices.write() = dev_list;
                    *encryption.write() = Some(enc_info);
                }
            });
        });

        let device_list = devices.read().clone();
        let enc_info = encryption.read().clone();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Security".to_string()),
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
                            .spacing(24.)
                            .child(super::section_heading("Encryption", c))
                            .child(match enc_info {
                                None => rect()
                                    .width(Size::fill())
                                    .height(Size::px(32.))
                                    .center()
                                    .child(CircularLoader::new().size(20.))
                                    .into_element(),
                                Some(enc) => {
                                    let (vs_label, vs_color) = match enc.verification_state {
                                        VerificationState::Verified => {
                                            ("Verified", c.status_online)
                                        }
                                        VerificationState::Unverified => ("Unverified", c.error),
                                        VerificationState::Unknown => {
                                            ("Unknown", c.on_surface_muted)
                                        }
                                    };
                                    let cs = enc.cross_signing;
                                    rect()
                                        .vertical()
                                        .spacing(8.)
                                        .width(Size::fill())
                                        .child(super::info_row(
                                            "Session verification",
                                            vs_label,
                                            vs_color,
                                            c,
                                        ))
                                        .child(match cs {
                                            None => super::info_row(
                                                "Cross-signing",
                                                "Not available",
                                                c.on_surface_muted,
                                                c,
                                            ),
                                            Some(cs) => rect()
                                                .vertical()
                                                .spacing(4.)
                                                .width(Size::fill())
                                                .child(super::info_row(
                                                    "Master key",
                                                    if cs.has_master {
                                                        "Present"
                                                    } else {
                                                        "Missing"
                                                    },
                                                    if cs.has_master {
                                                        c.status_online
                                                    } else {
                                                        c.error
                                                    },
                                                    c,
                                                ))
                                                .child(super::info_row(
                                                    "Self-signing key",
                                                    if cs.has_self_signing {
                                                        "Present"
                                                    } else {
                                                        "Missing"
                                                    },
                                                    if cs.has_self_signing {
                                                        c.status_online
                                                    } else {
                                                        c.error
                                                    },
                                                    c,
                                                ))
                                                .child(super::info_row(
                                                    "User-signing key",
                                                    if cs.has_user_signing {
                                                        "Present"
                                                    } else {
                                                        "Missing"
                                                    },
                                                    if cs.has_user_signing {
                                                        c.status_online
                                                    } else {
                                                        c.error
                                                    },
                                                    c,
                                                ))
                                                .into_element(),
                                        })
                                        .into_element()
                                }
                            })
                            .child(super::section_heading(
                                &format!("Sessions ({})", device_list.len()),
                                c,
                            ))
                            .child(if device_list.is_empty() {
                                rect()
                                    .width(Size::fill())
                                    .height(Size::px(32.))
                                    .center()
                                    .child(CircularLoader::new().size(20.))
                                    .into_element()
                            } else {
                                let mut col = rect().vertical().spacing(2.).width(Size::fill());
                                for d in &device_list {
                                    col = col.child(device_row(d, c));
                                }
                                col.into_element()
                            }),
                    ),
            )
    }
}

pub(super) fn device_row(d: &DeviceInfo, c: AppColors) -> Element {
    let bg = if d.is_this_device {
        c.surface_container_high
    } else {
        c.surface_container
    };
    let (badge_text, badge_color) = if d.is_verified {
        ("Verified", c.status_online)
    } else {
        ("Unverified", c.error)
    };

    let last_active = d.last_seen_ts.map(|ms| {
        use matrix_sdk::ruma::UInt;
        if let Some(u) = UInt::new(ms) {
            let ts = matrix_sdk::ruma::MilliSecondsSinceUnixEpoch(u);
            format!("Active: {}", crate::utils::format_timestamp(ts))
        } else {
            String::new()
        }
    });

    rect()
        .key(d.device_id.clone())
        .horizontal()
        .content(Content::Flex)
        .width(Size::fill())
        .padding(Gaps::new(10., 12., 10., 12.))
        .corner_radius(8.)
        .background(bg)
        .cross_align(Alignment::Center)
        .spacing(8.)
        .child(
            svg(freya_icons::lucide::monitor())
                .width(Size::px(18.))
                .height(Size::px(18.))
                .color(c.on_surface_variant),
        )
        .child(
            rect()
                .vertical()
                .spacing(2.)
                .width(Size::flex(1.0))
                .child(
                    rect()
                        .horizontal()
                        .spacing(6.)
                        .cross_align(Alignment::Center)
                        .child(
                            label()
                                .text(d.display_name.clone())
                                .font_size(14.)
                                .font_weight(FontWeight::MEDIUM)
                                .color(c.on_surface),
                        )
                        .child(if d.is_this_device {
                            label()
                                .text("this device")
                                .font_size(11.)
                                .color(c.primary)
                                .into_element()
                        } else {
                            rect().into_element()
                        }),
                )
                .child(
                    label()
                        .text(d.device_id.clone())
                        .font_size(11.)
                        .color(c.on_surface_muted),
                )
                .child(if let Some(active) = last_active {
                    label()
                        .text(active)
                        .font_size(11.)
                        .color(c.on_surface_muted)
                        .into_element()
                } else {
                    rect().into_element()
                }),
        )
        .child(label().text(badge_text).font_size(12.).color(badge_color))
        .into_element()
}
