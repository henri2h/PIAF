use freya::prelude::*;
use freya_material_design::prelude::Ripple;

use crate::ui::components::{IconButton, use_fade};

use crate::utils::const_values::AppColors;

/// Desktop row: hover highlight, ripple, and recontact/archive buttons on hover.
#[derive(Clone, Copy)]
pub struct RowInteraction {
    hovered: State<bool>,
    /// Opacity of the hover buttons, fading with `hovered`.
    actions_opacity: f32,
}

pub fn use_row_interaction() -> RowInteraction {
    let hovered = use_state(|| false);
    RowInteraction {
        hovered,
        actions_opacity: use_fade(*hovered.read(), 120),
    }
}

impl RowInteraction {
    pub fn is_highlighted(&self) -> bool {
        *self.hovered.read()
    }

    pub fn feedback(&self, inner: Rect) -> Element {
        Ripple::new()
            .width(Size::fill())
            .height(Size::fill())
            .child(inner)
            .into()
    }

    pub fn attach(
        self,
        outer: Rect,
        room_id: String,
        c: AppColors,
        highlighted: Element,
        on_menu: super::OnMenu,
    ) -> Rect {
        let mut hovered = self.hovered;
        let opacity = self.actions_opacity;
        let hover_actions =
            (opacity > 0.).then(|| hover_action_buttons(c, &room_id).opacity(opacity));
        outer
            .on_secondary_down(move |_| on_menu(true))
            .on_pointer_over(move |_| {
                if !*hovered.peek() {
                    hovered.set(true);
                }
            })
            .on_pointer_out(move |_| {
                if *hovered.peek() {
                    hovered.set(false);
                }
            })
            .child(highlighted)
            .maybe_child(hover_actions)
    }
}

fn hover_action_buttons(c: AppColors, room_id: &str) -> Rect {
    let room_id_recontact = room_id.to_string();
    let room_id_archive = room_id.to_string();

    rect()
        .position(Position::new_absolute().top(0.).right(6.).bottom(0.))
        .height(Size::fill())
        .horizontal()
        .spacing(6.)
        .cross_align(Alignment::Center)
        .child(action_button(
            c,
            "Recontact",
            freya_icons::lucide::user_check(),
            move || {
                let room_id = room_id_recontact.clone();
                tokio::spawn(async move {
                    crate::utils::room_mailbox::toggle_recontact(&room_id).await;
                });
            },
        ))
        .child(action_button(
            c,
            "Archive",
            freya_icons::lucide::archive(),
            move || {
                let room_id = room_id_archive.clone();
                tokio::spawn(async move {
                    crate::utils::room_mailbox::archive_room(&room_id).await;
                });
            },
        ))
}

fn action_button(
    c: AppColors,
    tooltip: &'static str,
    icon: bytes::Bytes,
    mut on_press: impl FnMut() + 'static,
) -> Element {
    IconButton::new(icon, c.on_surface_variant, move |_| on_press())
        .tooltip(tooltip)
        .background(c.surface_container_high)
        .into_element()
}
