use std::sync::Arc;

use freya::prelude::*;
use freya_router::prelude::RouterContext;
use matrix_sdk::media::MediaFormat;

use crate::ui::components::Avatar;
use crate::ui::components::{TopAppBar, TopAppBarTitle};
use crate::utils::use_app_colors;
use crate::{Route, utils::matrix::CLIENT};

#[derive(PartialEq)]
pub struct SettingsProfile {}

impl Component for SettingsProfile {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        let avatar: State<Option<Vec<u8>>> = use_state(|| None);
        let display_name: State<String> = use_state(String::new);
        let name_input: State<String> = use_state(String::new);
        let saving_name: State<bool> = use_state(|| false);
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
                let (tx, rx) = tokio::sync::oneshot::channel::<(String, Option<Vec<u8>>)>();
                tokio::task::spawn(async move {
                    let name = client
                        .account()
                        .get_display_name()
                        .await
                        .ok()
                        .flatten()
                        .or_else(|| client.user_id().map(|id| id.to_string()))
                        .unwrap_or_default();
                    let av = client
                        .account()
                        .get_avatar(MediaFormat::File)
                        .await
                        .ok()
                        .flatten();
                    let _ = tx.send((name, av));
                });
                if let Ok((name, av)) = rx.await {
                    *display_name.write() = name.clone();
                    *name_input.write() = name;
                    *avatar.write() = av;
                }
            });
        });

        let avatar_bytes = avatar.read().clone();
        let current_name = display_name.read().clone();
        let is_saving = *saving_name.read();
        let is_uploading = *uploading_avatar.read();
        let status_msg = status.read().clone();

        let user_id = CLIENT
            .get()
            .and_then(|c| c.user_id().map(|id| id.to_string()))
            .unwrap_or_default();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Profile".to_string()),
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
                            .spacing(28.)
                            .child(
                                rect()
                                    .vertical()
                                    .cross_align(Alignment::Center)
                                    .spacing(12.)
                                    .width(Size::fill())
                                    .child(Avatar {
                                        size: 88.,
                                        bytes: avatar_bytes.clone(),
                                        initial: current_name
                                            .chars()
                                            .next()
                                            .map(|c| c.to_uppercase().to_string())
                                            .unwrap_or_else(|| "?".to_string()),
                                        color: c.primary,
                                        image_key: "settings-avatar".to_string(),
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
                                                    let result =
                                                        pick_and_upload_avatar(&mut avatar).await;
                                                    *uploading_avatar.write() = false;
                                                    *status.write() = Some(match result {
                                                        Ok(()) => "Avatar updated.".into(),
                                                        Err(e) => format!("Error: {e}"),
                                                    });
                                                });
                                            })
                                            .child(if is_uploading {
                                                "Uploading…"
                                            } else {
                                                "Change avatar"
                                            });
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
                                                            let result =
                                                                save_display_name(new_name.clone())
                                                                    .await;
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
                                                    .child(if is_saving {
                                                        "Saving…"
                                                    } else {
                                                        "Save"
                                                    }),
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

async fn save_display_name(name: String) -> anyhow::Result<()> {
    let client = CLIENT
        .get()
        .ok_or_else(|| anyhow::anyhow!("Not logged in"))?;
    let (tx, rx) = tokio::sync::oneshot::channel::<anyhow::Result<()>>();
    let client = client.clone();
    tokio::task::spawn(async move {
        let result = client
            .account()
            .set_display_name(Some(name.as_str()))
            .await
            .map_err(anyhow::Error::from);
        let _ = tx.send(result);
    });
    rx.await?
}

#[cfg(not(target_os = "android"))]
async fn pick_and_upload_avatar(avatar_state: &mut State<Option<Vec<u8>>>) -> anyhow::Result<()> {
    let picked = tokio::task::spawn_blocking(|| {
        rfd::FileDialog::new()
            .add_filter("Images", &["png", "jpg", "jpeg", "gif", "webp"])
            .set_title("Choose avatar image")
            .pick_file()
    })
    .await?;

    let Some(path) = picked else { return Ok(()) };

    let ext = path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_lowercase();
    let mime_str = match ext.as_str() {
        "png" => "image/png",
        "gif" => "image/gif",
        "webp" => "image/webp",
        _ => "image/jpeg",
    };
    let content_type: mime::Mime = mime_str.parse()?;
    let data = tokio::fs::read(&path).await?;

    let client = CLIENT
        .get()
        .ok_or_else(|| anyhow::anyhow!("Not logged in"))?;
    let (tx, rx) = tokio::sync::oneshot::channel::<anyhow::Result<()>>();
    let client = client.clone();
    let data_clone = data.clone();
    tokio::task::spawn(async move {
        let result = client
            .account()
            .upload_avatar(&content_type, data_clone)
            .await
            .map(|_| ())
            .map_err(anyhow::Error::from);
        let _ = tx.send(result);
    });

    rx.await??;
    *avatar_state.write() = Some(data);
    Ok(())
}
