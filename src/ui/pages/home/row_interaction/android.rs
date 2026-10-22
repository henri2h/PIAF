use std::time::Duration;

use freya::animation::*;
use freya::prelude::*;

use super::super::room_list::RoomListCtx;
use crate::ui::components::{Swipe, SwipeBounds, use_swipe};
use crate::utils::const_values::AppColors;
use crate::utils::haptics::{self, Haptic};

const SWIPE: SwipeBounds = SwipeBounds {
    max_left: 120.,
    max_right: 120.,
    commit: 88.,
};
/// A finger resting this long is a press, not the start of a scroll.
const TAP_TIMEOUT: Duration = Duration::from_millis(90);
/// How long a quick tap stays highlighted.
const TAP_FLASH: Duration = Duration::from_millis(160);
const LONG_PRESS_DELAY: Duration = Duration::from_millis(350);
const LONG_PRESS_HIGHLIGHT: Duration = Duration::from_millis(500);
/// Layers grow with nesting depth: the sliding row is lifted above the
/// panels' icons (nested deeper than its background).
const ROW_LAYER: i16 = 2;
/// Fade of the colour flash confirming a committed swipe.
const COMMIT_FLASH_MS: u64 = 450;

/// Android row: press highlight, swipe to recontact / archive, long-press menu.
/// Bundled because a recognized swipe or scroll must cancel the press.
#[derive(Clone, Copy)]
pub struct RowInteraction {
    press_gen: State<u64>,
    pressed: State<bool>,
    long_pressed: State<bool>,
    /// Set when the touch was a swipe or long press, until the next touch: its
    /// lift is no tap. Checked by the row's `on_press`, which can run before
    /// or after `on_touch_end` cancels it.
    press_consumed: State<bool>,
    swipe: Swipe,
    /// `(commit count, recontact?)`: each committed swipe flashes the row in
    /// its panel's colour.
    commit_flash: State<(u64, bool)>,
    /// Opacity of that flash, fading out.
    flash_opacity: f32,
    /// The list's scroll: it cancels the row's touch events once it claims a
    /// touch, so timers check its `touch_generation` instead.
    scroll: Option<ScrollController>,
}

pub fn use_row_interaction() -> RowInteraction {
    let commit_flash = use_state(|| (0u64, false));
    let flashed = *commit_flash.read();
    let flash = use_animation_with_dependencies(&flashed, |conf, _| {
        conf.on_creation(OnCreation::Finish);
        conf.on_change(OnChange::Rerun);
        AnimNum::new(0.85, 0.)
            .time(COMMIT_FLASH_MS)
            .ease(Ease::In)
            .function(Function::Quad)
    });
    let flash_opacity = flash.get().value();
    RowInteraction {
        commit_flash,
        flash_opacity,
        press_gen: use_state(|| 0u64),
        pressed: use_state(|| false),
        long_pressed: use_state(|| false),
        press_consumed: use_state(|| false),
        swipe: use_swipe(),
        scroll: try_consume_context::<RoomListCtx>().map(|ctx| ctx.scroll),
    }
}

impl RowInteraction {
    /// Whether the touch being lifted is a tap that should open the room.
    pub fn allows_press(&self) -> bool {
        !*self.press_consumed.peek() && !self.swipe.is_swiping() && !*self.long_pressed.peek()
    }

    pub fn is_highlighted(&self) -> bool {
        *self.pressed.read() || *self.long_pressed.read()
    }

    pub fn feedback(&self, inner: Rect) -> Element {
        inner.into()
    }

    /// No hover buttons over the timestamp on touch screens.
    pub fn meta_opacity(&self) -> f32 {
        1.
    }

    /// Changes once the list takes over this touch or sees it end (the row
    /// then gets neither `touchmove` nor `touchend`).
    fn touch_generation(&self) -> Option<u64> {
        self.scroll.map(|scroll| scroll.touch_generation())
    }

    /// Highlights after the tap timeout, then opens the menu after the long-press delay.
    fn start_press(&self, on_menu: super::OnMenu) {
        let this = *self;
        let (mut press_gen, mut pressed, mut long_pressed) =
            (self.press_gen, self.pressed, self.long_pressed);
        let next_gen = *press_gen.peek() + 1;
        press_gen.set(next_gen);
        let touch = this.touch_generation();
        spawn(async move {
            let still_down = || *press_gen.peek() == next_gen && this.touch_generation() == touch;
            timer(TAP_TIMEOUT).await;
            if !still_down() {
                return;
            }
            pressed.set(true);
            timer(LONG_PRESS_DELAY - TAP_TIMEOUT).await;
            if !still_down() {
                // Its end may never reach the row: clear the highlight here.
                if *press_gen.peek() == next_gen {
                    pressed.set(false);
                }
                return;
            }
            pressed.set(false);
            long_pressed.set(true);
            haptics::play(Haptic::HeavyClick);
            on_menu(false);
            timer(LONG_PRESS_HIGHLIGHT).await;
            if *press_gen.peek() == next_gen {
                long_pressed.set(false);
            }
        });
    }

    fn cancel_press(&self) {
        *self.press_gen.write_unchecked() += 1;
        *self.pressed.write_unchecked() = false;
        *self.long_pressed.write_unchecked() = false;
    }

    /// Keeps a quick tap visible for a moment: it lifts before the tap timeout.
    fn flash_tap(&self) {
        let (mut press_gen, mut pressed) = (self.press_gen, self.pressed);
        let next_gen = *press_gen.peek() + 1;
        press_gen.set(next_gen);
        pressed.set(true);
        spawn(async move {
            timer(TAP_FLASH).await;
            if *press_gen.peek() == next_gen {
                pressed.set(false);
            }
        });
    }

    /// Adds touch handlers and the recontact/archive panels revealed behind `highlighted`.
    pub fn attach(
        self,
        outer: Rect,
        room_id: String,
        c: AppColors,
        highlighted: Element,
        on_menu: super::OnMenu,
    ) -> Rect {
        let state = self;
        let swipe = self.swipe;
        let room_id_recontact = room_id.clone();
        let room_id_archive = room_id;

        let offset = swipe.offset();
        let reveal_recontact = offset > 4.0;
        let reveal_archive = offset < -4.0;
        let past_commit = offset.abs() > SWIPE.commit;
        let icon_size = if past_commit { 26. } else { 22. };

        // Absolute so the row draws over the panels instead of sharing their
        // height. No negative layer for them: the page's background would
        // paint over it.
        let action_panels = rect()
            .position(
                Position::new_absolute()
                    .top(0.)
                    .bottom(0.)
                    .left(0.)
                    .right(0.),
            )
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
                            .width(Size::px(icon_size))
                            .height(Size::px(icon_size))
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
                            .width(Size::px(icon_size))
                            .height(Size::px(icon_size))
                            .color(c.on_surface)
                            .into_element()
                    })),
            );

        let shifted = rect()
            .width(Size::fill())
            .height(Size::fill())
            .layer(ROW_LAYER)
            .offset_x(offset)
            .child(highlighted);

        let commit_flash = self.commit_flash;
        let commit = move |released: f32| {
            let mut commit_flash = commit_flash;
            let count = commit_flash.peek().0 + 1;
            commit_flash.set((count, released > 0.));
            haptics::play(Haptic::Click);
            if released > 0. {
                let room_id = room_id_recontact.clone();
                tokio::spawn(async move {
                    crate::utils::room_mailbox::toggle_recontact(&room_id).await;
                });
            } else {
                let room_id = room_id_archive.clone();
                tokio::spawn(async move {
                    crate::utils::room_mailbox::archive_room(&room_id).await;
                });
            }
        };
        let commit_fallback = commit.clone();

        outer
            .on_touch_start(move |e: Event<TouchEventData>| {
                *state.press_consumed.write_unchecked() = false;
                swipe.start(e.global_location);
                state.start_press(on_menu.clone());
            })
            .on_touch_move(move |e: Event<TouchEventData>| {
                if swipe.moved(e.global_location, SWIPE) {
                    state.cancel_press();
                }
            })
            .on_touch_end(move |e: Event<TouchEventData>| {
                let long_pressed = *state.long_pressed.peek();
                let swiped = swipe.is_swiping();
                // The lift after a long press (menu open) or a swipe is not a tap:
                // otherwise `on_press` opens the room just archived.
                if long_pressed || swiped {
                    *state.press_consumed.write_unchecked() = true;
                    e.prevent_default();
                    state.cancel_press();
                } else {
                    state.flash_tap();
                }
                if let Some(released) = swipe.end(SWIPE) {
                    commit(released);
                }
            })
            // The list cancels `touchend` for rows once it claims the drag, and
            // the finger may lift off another row: finish here too.
            .on_global_pointer_up(move |_: Event<PointerEventData>| {
                if !swipe.is_touching() {
                    return;
                }
                if swipe.is_swiping() || *state.long_pressed.peek() {
                    *state.press_consumed.write_unchecked() = true;
                }
                state.cancel_press();
                if let Some(released) = swipe.end(SWIPE) {
                    commit_fallback(released);
                }
            })
            .on_touch_cancel(move |_: Event<TouchEventData>| {
                state.cancel_press();
                swipe.cancel();
            })
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::fill())
                    .overflow(Overflow::Clip)
                    // Hidden at rest: fully covered by the row.
                    .maybe_child((reveal_recontact || reveal_archive).then(|| action_panels))
                    .child(shifted)
                    .maybe_child((self.flash_opacity > 0.01).then(|| {
                        let recontact = self.commit_flash.peek().1;
                        rect()
                            .position(
                                Position::new_absolute()
                                    .top(0.)
                                    .bottom(0.)
                                    .left(0.)
                                    .right(0.),
                            )
                            .width(Size::fill())
                            .height(Size::fill())
                            .layer(ROW_LAYER + 2)
                            .background(if recontact {
                                c.primary
                            } else {
                                c.surface_container_high
                            })
                            .opacity(self.flash_opacity)
                    })),
            )
    }
}
