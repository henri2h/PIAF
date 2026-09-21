use std::time::Duration;

use freya::prelude::*;

use crate::utils::const_values::AppColors;

const SWIPE_THRESHOLD: f64 = 12.0;
const COMMIT_THRESHOLD: f32 = 88.0;
const MAX_OFFSET: f64 = 120.0;
const LONG_PRESS_DELAY: Duration = Duration::from_millis(350);
const LONG_PRESS_HIGHLIGHT: Duration = Duration::from_millis(500);

/// Per-row gesture state for Android: swipe-to-reveal (recontact / archive)
/// bundled with the existing long-press highlight, since a recognized swipe
/// must cancel an in-flight long press.
#[derive(Clone, Copy)]
pub struct SwipeState {
    press_gen: State<u64>,
    pub long_pressed: State<bool>,
    drag_start: State<Option<(f64, f64)>>,
    is_swiping: State<bool>,
    pub offset_x: State<f32>,
}

pub fn use_swipe_state() -> SwipeState {
    SwipeState {
        press_gen: use_state(|| 0u64),
        long_pressed: use_state(|| false),
        drag_start: use_state(|| None),
        is_swiping: use_state(|| false),
        offset_x: use_state(|| 0.0f32),
    }
}

impl SwipeState {
    fn start_long_press(&self) {
        let mut press_gen = self.press_gen;
        let mut long_pressed = self.long_pressed;
        let next_gen = *press_gen.read() + 1;
        *press_gen.write() = next_gen;
        spawn(async move {
            tokio::time::sleep(LONG_PRESS_DELAY).await;
            if *press_gen.read() == next_gen {
                *long_pressed.write() = true;
                tokio::time::sleep(LONG_PRESS_HIGHLIGHT).await;
                if *press_gen.read() == next_gen {
                    *long_pressed.write() = false;
                }
            }
        });
    }

    fn cancel_long_press(&self) {
        *self.press_gen.write_unchecked() += 1;
        *self.long_pressed.write_unchecked() = false;
    }
}

/// Wraps `outer` with the swipe-to-reveal touch handlers and the layered
/// recontact/archive background panels revealed behind `highlighted`.
pub fn attach_swipe(
    outer: Rect,
    state: SwipeState,
    room_id: String,
    c: AppColors,
    highlighted: Element,
) -> Rect {
    let room_id_recontact = room_id.clone();
    let room_id_archive = room_id;

    let offset = *state.offset_x.read();
    let reveal_recontact = offset > 4.0;
    let reveal_archive = offset < -4.0;

    let action_panels = rect()
        .width(Size::fill())
        .height(Size::fill())
        .horizontal()
        .content(Content::Flex)
        .child(
            rect()
                .width(Size::flex(1.0))
                .height(Size::fill())
                .background(c.primary)
                .center()
                .maybe_child(reveal_recontact.then(|| {
                    SvgViewer::new(freya_icons::lucide::user_check())
                        .width(Size::px(22.))
                        .height(Size::px(22.))
                        .color(c.on_primary)
                        .into_element()
                })),
        )
        .child(
            rect()
                .width(Size::flex(1.0))
                .height(Size::fill())
                .background(c.surface_container_high)
                .center()
                .maybe_child(reveal_archive.then(|| {
                    SvgViewer::new(freya_icons::lucide::archive())
                        .width(Size::px(22.))
                        .height(Size::px(22.))
                        .color(c.on_surface)
                        .into_element()
                })),
        );

    let shifted = rect()
        .width(Size::fill())
        .height(Size::fill())
        .offset_x(offset)
        .child(highlighted);

    let mut drag_start = state.drag_start;
    let mut is_swiping = state.is_swiping;
    let mut offset_x = state.offset_x;

    outer
        .on_touch_start(move |e: Event<TouchEventData>| {
            drag_start.set(Some((e.global_location.x, e.global_location.y)));
            state.start_long_press();
        })
        .on_touch_move(move |e: Event<TouchEventData>| {
            let Some((sx, sy)) = *drag_start.peek() else {
                return;
            };
            let dx = e.global_location.x - sx;
            let dy = e.global_location.y - sy;

            if !*is_swiping.peek() {
                if dx.abs() > SWIPE_THRESHOLD && dx.abs() > dy.abs() * 1.5 {
                    is_swiping.set(true);
                    state.cancel_long_press();
                } else {
                    state.cancel_long_press();
                    return;
                }
            }

            offset_x.set(dx.clamp(-MAX_OFFSET, MAX_OFFSET) as f32);
        })
        .on_touch_end(move |_: Event<TouchEventData>| {
            state.cancel_long_press();
            if *is_swiping.peek() {
                let dx = *offset_x.peek();
                if dx > COMMIT_THRESHOLD {
                    let room_id = room_id_recontact.clone();
                    tokio::spawn(async move {
                        crate::utils::room_mailbox::toggle_recontact(&room_id).await;
                    });
                } else if dx < -COMMIT_THRESHOLD {
                    let room_id = room_id_archive.clone();
                    tokio::spawn(async move {
                        crate::utils::room_mailbox::archive_room(&room_id).await;
                    });
                }
            }
            // Snap back immediately. Animating this back to 0 with
            // use_animation is a natural follow-up polish pass.
            offset_x.set(0.0);
            is_swiping.set(false);
            drag_start.set(None);
        })
        .on_touch_cancel(move |_: Event<TouchEventData>| {
            state.cancel_long_press();
            offset_x.set(0.0);
            is_swiping.set(false);
            drag_start.set(None);
        })
        .child(
            rect()
                .width(Size::fill())
                .height(Size::fill())
                .overflow(Overflow::Clip)
                .child(action_panels)
                .child(shifted),
        )
}
