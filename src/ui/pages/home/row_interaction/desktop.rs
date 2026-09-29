use freya::prelude::*;
use freya_material_design::prelude::Ripple;

use crate::utils::const_values::AppColors;

/// Desktop row: hover highlight, ripple, and recontact/archive buttons on hover.
#[derive(Clone, Copy)]
pub struct RowInteraction {
    hovered: State<bool>,
    recontact_hovered: State<bool>,
    archive_hovered: State<bool>,
}

pub fn use_row_interaction() -> RowInteraction {
    RowInteraction {
        hovered: use_state(|| false),
        recontact_hovered: use_state(|| false),
        archive_hovered: use_state(|| false),
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
        let hover_actions = hovered.read().then(|| {
            hover_action_buttons(c, &room_id, self.recontact_hovered, self.archive_hovered)
        });
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

fn hover_action_buttons(
    c: AppColors,
    room_id: &str,
    recontact_hovered: State<bool>,
    archive_hovered: State<bool>,
) -> Element {
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
            recontact_hovered,
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
            archive_hovered,
            move || {
                let room_id = room_id_archive.clone();
                tokio::spawn(async move {
                    crate::utils::room_mailbox::archive_room(&room_id).await;
                });
            },
        ))
        .into_element()
}

fn action_button(
    c: AppColors,
    tooltip_label: &'static str,
    icon: bytes::Bytes,
    mut hovered: State<bool>,
    mut on_press: impl FnMut() + 'static,
) -> Element {
    TooltipContainer::new(Tooltip::new_text(tooltip_label))
        .position(AttachedPosition::Top)
        .child(
            rect()
                .width(Size::px(32.))
                .height(Size::px(32.))
                .corner_radius(16.)
                .overflow(Overflow::Clip)
                .background(if *hovered.read() {
                    c.outline_variant_light
                } else {
                    c.surface_container_high
                })
                .on_pointer_over(move |_| hovered.set(true))
                .on_pointer_out(move |_| hovered.set(false))
                .on_press(move |e: Event<PressEventData>| {
                    e.stop_propagation();
                    on_press();
                })
                .child(
                    Ripple::new().color(c.primary).width(Size::fill()).child(
                        rect().center().expanded().child(
                            SvgViewer::new(icon)
                                .width(Size::px(16.))
                                .height(Size::px(16.))
                                .color(c.on_surface_variant),
                        ),
                    ),
                ),
        )
        .into_element()
}
