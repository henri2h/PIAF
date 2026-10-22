use freya::prelude::*;

use crate::utils::avatars::AvatarSource;

use crate::ui::components::Avatar;
use crate::ui::components::TopAppBar;
use crate::utils::matrix::CLIENT;
use crate::utils::{on_tokio, use_app_colors};

#[derive(PartialEq)]
pub struct SettingsProfile {}

impl Component for SettingsProfile {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let avatar: State<Option<Vec<u8>>> = use_state(|| None);
        let display_name: State<String> = use_state(String::new);
        let name_input: State<String> = use_state(String::new);
        let saving_name: State<bool> = use_state(|| false);
        // Avatar upload is desktop-only (file picker).
        #[cfg_attr(target_os = "android", allow(unused_variables))]
        let uploading_avatar: State<bool> = use_state(|| false);
        let status: State<Option<String>> = use_state(|| None);

        use_hook(|| {
            let mut avatar = avatar;
            let mut display_name = display_name;
            let mut name_input = name_input;
            spawn(async move {
                let Some(client) = CLIENT.get().cloned() else {
                    return;
                };
                let rx = crate::utils::on_tokio::<(String, Option<Vec<u8>>), _>(async move {
                    let name = crate::utils::matrix::own_display_name(&client).await;
                    let av = crate::utils::avatars::own(&client).await;
                    (name, av)
                });
                if let Some((name, av)) = rx.await {
                    *display_name.write() = name.clone();
                    *name_input.write() = name;
                    *avatar.write() = av;
                }
            });
        });

        let avatar_bytes = avatar.read().clone();
        let current_name = display_name.read().clone();
        let is_saving = *saving_name.read();
        #[cfg(not(target_os = "android"))]
        let is_uploading = *uploading_avatar.read();
        let status_msg = status.read().clone();

        let user_id = crate::utils::matrix::my_user_id().unwrap_or_default();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar::new("Profile"))
            .child(
                ScrollView::new()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .child(
                        rect()
                            .vertical()
                            .width(Size::fill())
                            .padding(Gaps::new_all(24.))
                            .spacing(28.)
                            .child(
                                rect()
                                    .vertical()
                                    .cross_align(Alignment::Center)
                                    .spacing(12.)
                                    .width(Size::fill())
                                    .child(Avatar {
                                        size: 88.,
                                        source: Some(
                                            avatar_bytes
                                                .clone()
                                                .map(|b| AvatarSource::Bytes(b.into()))
                                                .unwrap_or(AvatarSource::Me),
                                        ),
                                        name: current_name.clone(),
                                        color: c.primary,
                                    })
                                    .child({
                                        #[cfg(not(target_os = "android"))]
                                        let btn = Button::new()
                                            .on_press(move |_| {
                                                if is_uploading {
                                                    return;
                                                }
                                                let mut avatar = avatar;
                                                let mut uploading_avatar = uploading_avatar;
                                                let mut status = status;
                                                *uploading_avatar.write() = true;
                                                spawn(async move {
                                                    let result = on_tokio(pick_and_upload_avatar())
                                                        .await
                                                        .unwrap_or_else(|| {
                                                            Err(anyhow::anyhow!("cancelled"))
                                                        })
                                                        .map(|data| {
                                                            if let Some(data) = data {
                                                                avatar.set(Some(data));
                                                            }
                                                        });
                                                    *uploading_avatar.write() = false;
                                                    *status.write() = Some(match result {
                                                        Ok(()) => "Avatar updated.".into(),
                                                        Err(e) => format!("Error: {e}"),
                                                    });
                                                });
                                            })
                                            .child(super::button_label(
                                                freya_icons::lucide::image(),
                                                if is_uploading {
                                                    "Uploading…"
                                                } else {
                                                    "Change avatar"
                                                },
                                                c,
                                            ));
                                        #[cfg(target_os = "android")]
                                        let btn = rect();
                                        btn
                                    }),
                            )
                            .child(
                                rect()
                                    .vertical()
                                    .spacing(8.)
                                    .width(Size::fill())
                                    .child(
                                        label()
                                            .text("Display name")
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
                                                    .child(
                                                        Input::new(name_input)
                                                            .flat()
                                                            .width(Size::fill()),
                                                    ),
                                            )
                                            .child(
                                                Button::new()
                                                    .on_press(move |_| {
                                                        if is_saving {
                                                            return;
                                                        }
                                                        let new_name = name_input.read().clone();
                                                        let mut saving_name = saving_name;
                                                        let mut display_name = display_name;
                                                        let mut status = status;
                                                        *saving_name.write() = true;
                                                        spawn(async move {
                                                            let result = on_tokio(
                                                                save_display_name(new_name.clone()),
                                                            )
                                                            .await
                                                            .unwrap_or_else(|| {
                                                                Err(anyhow::anyhow!("cancelled"))
                                                            });
                                                            *saving_name.write() = false;
                                                            match result {
                                                                Ok(()) => {
                                                                    *display_name.write() =
                                                                        new_name;
                                                                    *status.write() = Some(
                                                                        "Name updated.".into(),
                                                                    );
                                                                }
                                                                Err(e) => {
                                                                    *status.write() =
                                                                        Some(format!("Error: {e}"));
                                                                }
                                                            }
                                                        });
                                                    })
                                                    .child(super::button_label(
                                                        freya_icons::lucide::save(),
                                                        if is_saving {
                                                            "Saving…"
                                                        } else {
                                                            "Save"
                                                        },
                                                        c,
                                                    )),
                                            ),
                                    ),
                            )
                            .child(
                                rect()
                                    .vertical()
                                    .spacing(4.)
                                    .width(Size::fill())
                                    .child(
                                        label()
                                            .text("User ID")
                                            .font_size(13.)
                                            .color(c.on_surface_muted),
                                    )
                                    .child(label().text(user_id).color(c.reaction_default_text)),
                            )
                            .child(if let Some(msg) = status_msg {
                                label()
                                    .text(msg)
                                    .font_size(13.)
                                    .color(c.status_online)
                                    .into_element()
                            } else {
                                rect().into_element()
                            }),
                    ),
            )
    }
}

/// Runs on tokio (called through `on_tokio`).
async fn save_display_name(name: String) -> anyhow::Result<()> {
    let client = CLIENT
        .get()
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("Not logged in"))?;
    client
        .account()
        .set_display_name(Some(name.as_str()))
        .await?;
    Ok(())
}

/// Asks for an image and uploads it as the avatar; returns its bytes, or
/// `None` when the dialog was cancelled. Runs on tokio (through `on_tokio`).
#[cfg(not(target_os = "android"))]
async fn pick_and_upload_avatar() -> anyhow::Result<Option<Vec<u8>>> {
    let Some(image) = crate::utils::media::pick_image("Choose avatar image").await else {
        return Ok(None);
    };
    let client = CLIENT
        .get()
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("Not logged in"))?;
    client
        .account()
        .upload_avatar(&image.mime, image.bytes.clone())
        .await?;
    Ok(Some(image.bytes))
}
