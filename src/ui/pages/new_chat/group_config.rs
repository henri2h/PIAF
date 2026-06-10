use freya::prelude::*;
use freya_router::prelude::RouterContext;
use std::sync::Arc;

use crate::{
    Route,
    ui::components::{Avatar, TopAppBar, TopAppBarTitle, user_color},
    utils::use_app_colors,
};

use super::draft::GROUP_DRAFT;

#[derive(PartialEq)]
pub struct NewGroupConfig;

impl Component for NewGroupConfig {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();

        // Pre-fill from draft in a single lock acquisition so name and encrypted
        // always come from the same consistent snapshot.
        let (saved_name, saved_enc) = GROUP_DRAFT
            .lock()
            .map(|d| (d.name.clone(), d.encrypted))
            .unwrap_or_else(|_| (String::new(), true));

        let name: State<String> = use_state(|| saved_name);
        let mut encrypted: State<bool> = use_state(|| saved_enc);
        let mut error: State<Option<String>> = use_state(|| None);

        let is_encrypted = *encrypted.read();
        let err_msg = error.read().clone();

        let invitee_previews: Vec<(String, String, Option<String>)> = GROUP_DRAFT
            .lock()
            .map(|d| {
                d.invitees
                    .iter()
                    .map(|u| (u.user_id.clone(), u.display_name.clone(), u.avatar_mxc.clone()))
                    .collect()
            })
            .unwrap_or_default();

        // Save name + encryption to draft, then navigate to PendingGroup.
        let mut do_next = move || {
            let room_name = name.read().trim().to_string();
            if room_name.is_empty() {
                *error.write() = Some("Please enter a group name.".to_string());
                return;
            }
            let has_invitees = GROUP_DRAFT
                .lock()
                .map(|d| !d.invitees.is_empty())
                .unwrap_or(false);
            if !has_invitees {
                *error.write() = Some("No participants selected.".to_string());
                return;
            }
            if let Ok(mut draft) = GROUP_DRAFT.lock() {
                draft.name = room_name;
                draft.encrypted = is_encrypted;
            }
            let _ = RouterContext::get().push(Route::PendingGroup);
        };

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Group settings".to_string()),
                on_back: Some(Arc::new(|| {
                    let _ = RouterContext::get().push(Route::NewGroup);
                })),
                actions: vec![],
            })
            // Participants recap
            .child(
                rect()
                    .vertical()
                    .width(Size::fill())
                    .padding(Gaps::new(16., 16., 8., 16.))
                    .spacing(8.)
                    .child(
                        label()
                            .text("Participants")
                            .font_size(13.)
                            .color(c.on_surface_muted),
                    )
                    .child({
                        let mut row = rect().horizontal().width(Size::fill()).spacing(12.);
                        for (uid, display_name, avatar_mxc) in &invitee_previews {
                            let initial = display_name
                                .chars()
                                .next()
                                .map(|ch| ch.to_uppercase().to_string())
                                .unwrap_or_else(|| "?".to_string());
                            let color = user_color(uid);
                            row = row.child(
                                rect()
                                    .vertical()
                                    .spacing(4.)
                                    .cross_align(Alignment::Center)
                                    .child(Avatar {
                                        size: 44.,
                                        bytes: None,
                                        fetch_key: avatar_mxc.clone(),
                                        initial,
                                        color,
                                        image_key: uid.clone(),
                                    })
                                    .child(
                                        label()
                                            .text(
                                                display_name.chars().take(8).collect::<String>(),
                                            )
                                            .font_size(11.)
                                            .color(c.on_surface_variant),
                                    ),
                            );
                        }
                        row
                    }),
            )
            // Group name input
            .child(
                rect()
                    .vertical()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 16., 8., 16.))
                    .spacing(8.)
                    .child(
                        label()
                            .text("Group name")
                            .font_size(13.)
                            .color(c.on_surface_muted),
                    )
                    .child(
                        rect()
                            .width(Size::fill())
                            .corner_radius(8.)
                            .background(c.surface_container)
                            .padding(Gaps::new(0., 4., 0., 12.))
                            .child(
                                Input::new(name)
                                    .flat()
                                    .auto_focus(true)
                                    .placeholder("Enter group name…")
                                    .width(Size::fill())
                                    .on_submit(move |_: String| do_next()),
                            ),
                    ),
            )
            // Encryption toggle
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 16., 8., 16.))
                    .content(Content::Flex)
                    .cross_align(Alignment::Center)
                    .child(
                        rect()
                            .vertical()
                            .width(Size::flex(1.0))
                            .spacing(2.)
                            .child(
                                label()
                                    .text("Enable encryption")
                                    .font_size(15.)
                                    .color(c.on_surface),
                            )
                            .child(
                                label()
                                    .text("Messages will be end-to-end encrypted")
                                    .font_size(12.)
                                    .color(c.on_surface_muted),
                            ),
                    )
                    .child(Switch::new().toggled(is_encrypted).on_toggle(move |_| {
                        *encrypted.write() = !*encrypted.read();
                    })),
            )
            // Error
            .maybe_child(err_msg.map(|msg| {
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(0., 16., 4., 16.))
                    .child(label().text(msg).font_size(13.).color(c.error))
            }))
            // Next button
            .child(
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 16., 16., 16.))
                    .child(
                        Button::new()
                            .on_press(move |_| do_next())
                            .child(
                                rect()
                                    .horizontal()
                                    .spacing(8.)
                                    .cross_align(Alignment::Center)
                                    .child(label().text("Next"))
                                    .child(
                                        svg(freya_icons::lucide::arrow_right())
                                            .width(Size::px(16.))
                                            .height(Size::px(16.)),
                                    ),
                            ),
                    ),
            )
    }
}
