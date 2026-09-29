use freya::prelude::*;
use freya_material_design::prelude::ButtonRippleExt;

use super::room_app_bar::room_app_bar;
use crate::app::navigation::close_room;
use crate::ui::components::{Avatar, user_color};
use crate::utils::const_values::AppColors;
use crate::utils::matrix::get_room;
use crate::utils::use_app_colors;

/// Resolved from our invite member event.
#[derive(Clone, PartialEq)]
struct InviteInfo {
    inviter_id: String,
    inviter_name: Option<String>,
    /// `is_direct` on the invite; `Room::is_dm` isn't reliable before joining.
    is_direct: bool,
}

#[derive(Clone, Copy, PartialEq)]
enum Busy {
    Accepting,
    Declining,
}

/// Pending invite: room info, inviter, Accept / Decline. `joined` is set once
/// accepted so the parent switches to the room.
#[derive(PartialEq)]
pub(super) struct InviteView {
    pub room_id: String,
    pub joined: State<bool>,
}

impl Component for InviteView {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut info: State<Option<InviteInfo>> = use_state(|| None);
        let mut busy: State<Option<Busy>> = use_state(|| None);
        let mut error: State<Option<String>> = use_state(|| None);
        let mut joined = self.joined;

        let room = get_room(&self.room_id);
        let name = room
            .as_ref()
            .and_then(|r| r.cached_display_name())
            .map(|n| n.to_string())
            .unwrap_or_else(|| "Unknown room".to_string());
        let topic = room.as_ref().and_then(|r| r.topic());

        let room_id = self.room_id.clone();
        use_hook(move || {
            let (tx, rx) = futures::channel::oneshot::channel();
            tokio::spawn(async move {
                let Some(room) = get_room(&room_id) else {
                    return;
                };
                let is_direct = room.is_direct().await.unwrap_or(false);
                if let Ok(d) = room.invite_details().await {
                    let _ = tx.send(InviteInfo {
                        inviter_id: d.inviter_id.to_string(),
                        inviter_name: d
                            .inviter
                            .and_then(|m| m.display_name().map(|n| n.to_string())),
                        is_direct,
                    });
                }
            });
            spawn(async move {
                if let Ok(details) = rx.await {
                    info.set(Some(details));
                }
            });
        });

        let mut respond = move |room_id: String, accept: bool| {
            if busy.peek().is_some() {
                return;
            }
            busy.set(Some(if accept {
                Busy::Accepting
            } else {
                Busy::Declining
            }));
            error.set(None);
            let (tx, rx) = futures::channel::oneshot::channel::<Result<(), String>>();
            tokio::spawn(async move {
                let result = match get_room(&room_id) {
                    Some(room) if accept => room.join().await.map_err(|e| e.to_string()),
                    Some(room) => room.leave().await.map_err(|e| e.to_string()),
                    None => Err("This room is no longer available.".to_string()),
                };
                crate::utils::room_list::refresh("invite_response");
                let _ = tx.send(result);
            });
            spawn(async move {
                let result = rx.await.unwrap_or_else(|_| Err("Cancelled".to_string()));
                busy.set(None);
                match result {
                    Ok(()) if accept => joined.set(true),
                    Ok(()) => close_room(),
                    Err(e) => error.set(Some(format!(
                        "Could not {} the invite: {e}",
                        if accept { "accept" } else { "decline" }
                    ))),
                }
            });
        };

        let invite_line = info.read().as_ref().map(|i| {
            let who = match &i.inviter_name {
                Some(name) => format!("{name} ({})", i.inviter_id),
                None => i.inviter_id.clone(),
            };
            if i.is_direct {
                format!("{who} wants to chat with you")
            } else {
                format!("{who} invited you to join")
            }
        });
        let busy_now = *busy.read();
        let (accept_id, decline_id) = (self.room_id.clone(), self.room_id.clone());

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(room_app_bar(&self.room_id, &name, c, false))
            .child(
                ScrollView::new()
                    .width(Size::fill())
                    .height(Size::flex(1.))
                    .child(
                        rect()
                            .width(Size::fill())
                            .padding(Gaps::new(40., 24., 32., 24.))
                            .cross_align(Alignment::Center)
                            .child(
                                rect()
                                    .vertical()
                                    .width(Size::fill())
                                    .max_width(Size::px(420.))
                                    .cross_align(Alignment::Center)
                                    .spacing(16.)
                                    .child(Avatar {
                                        size: 88.,
                                        bytes: None,
                                        fetch_key: Some(self.room_id.clone()),
                                        initial: initial_of(&name),
                                        color: user_color(&self.room_id),
                                        image_key: self.room_id.clone(),
                                    })
                                    .child(
                                        label()
                                            .text(name.clone())
                                            .font_size(24.)
                                            .font_weight(FontWeight::BOLD)
                                            .text_align(TextAlign::Center)
                                            .color(c.on_surface),
                                    )
                                    .maybe_child(invite_line.map(|line| {
                                        label()
                                            .text(line)
                                            .font_size(14.)
                                            .text_align(TextAlign::Center)
                                            .color(c.on_surface_variant)
                                    }))
                                    .maybe_child(topic.filter(|t| !t.is_empty()).map(|t| {
                                        label()
                                            .text(t)
                                            .font_size(13.)
                                            .max_lines(4)
                                            .text_align(TextAlign::Center)
                                            .color(c.on_surface_muted)
                                    }))
                                    .maybe_child(
                                        error
                                            .read()
                                            .clone()
                                            .map(|e| label().text(e).font_size(13.).color(c.error)),
                                    )
                                    .child(actions(
                                        c,
                                        busy_now,
                                        move || respond(decline_id.clone(), false),
                                        move || respond(accept_id.clone(), true),
                                    )),
                            ),
                    ),
            )
    }
}

fn actions(
    c: AppColors,
    busy: Option<Busy>,
    mut on_decline: impl FnMut() + 'static,
    mut on_accept: impl FnMut() + 'static,
) -> Rect {
    let idle = busy.is_none();
    let button_label = |text: &'static str, active: bool, color| {
        rect()
            .horizontal()
            .center()
            .spacing(8.)
            .maybe_child(active.then(|| CircularLoader::new().size(16.)))
            .child(label().text(text).font_size(15.).color(color))
    };
    rect()
        .horizontal()
        .width(Size::fill())
        .content(Content::Flex)
        .spacing(12.)
        .margin(Gaps::new(8., 0., 0., 0.))
        .child(
            rect().width(Size::flex(1.)).child(
                Button::new()
                    .outline()
                    .expanded()
                    .enabled(idle)
                    .on_press(move |_| on_decline())
                    .ripple()
                    .child(button_label(
                        "Decline",
                        busy == Some(Busy::Declining),
                        c.on_surface,
                    )),
            ),
        )
        .child(
            rect().width(Size::flex(1.)).child(
                Button::new()
                    .filled()
                    .expanded()
                    .enabled(idle)
                    .on_press(move |_| on_accept())
                    .ripple()
                    .child(button_label(
                        "Accept",
                        busy == Some(Busy::Accepting),
                        c.on_primary,
                    )),
            ),
        )
}

fn initial_of(name: &str) -> String {
    name.chars()
        .next()
        .map(|ch| ch.to_uppercase().to_string())
        .unwrap_or_else(|| "?".to_string())
}
