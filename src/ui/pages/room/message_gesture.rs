use std::time::Duration;

use freya::prelude::*;

use super::ui_ctx::use_room_ui_ctx;
use crate::ui::components::{Swipe, SwipeBounds, use_swipe};
use crate::utils::const_values::AppColors;
use crate::utils::haptics::{self, Haptic};

const REPLY_SWIPE: SwipeBounds = SwipeBounds {
    max_left: 0.,
    max_right: 90.,
    commit: 64.,
};
const NO_SWIPE: SwipeBounds = SwipeBounds {
    max_left: 0.,
    max_right: 0.,
    commit: f32::MAX,
};
const LONG_PRESS_DELAY: Duration = Duration::from_millis(350);
const REPLY_ICON: f32 = 28.;

/// Android message row: swipe right to reply, long press for the actions.
#[derive(Clone, Copy)]
pub(super) struct MessageGesture {
    press_gen: State<u64>,
    /// Set once the long press fired, so its lift isn't a tap.
    long_pressed: State<bool>,
    /// The touch was a swipe, until the next touch: its lift isn't a tap.
    swiped: State<bool>,
    swipe: Swipe,
    /// The timeline cancels the row's touch moves once it drags, so the
    /// long-press timer checks it instead.
    scroll: ScrollController,
}

pub(super) fn use_message_gesture() -> MessageGesture {
    MessageGesture {
        press_gen: use_state(|| 0u64),
        long_pressed: use_state(|| false),
        swiped: use_state(|| false),
        swipe: use_swipe(),
        scroll: use_room_ui_ctx().scroll,
    }
}

impl MessageGesture {
    fn cancel_press(&self) {
        *self.press_gen.write_unchecked() += 1;
    }

    /// Whether the touch being lifted is a tap that parts of the message (image,
    /// reactions, avatar…) should act on. Their `on_press` can run before or
    /// after this row's `on_touch_end` cancels it, so they check this too.
    pub fn allows_press(&self) -> bool {
        !*self.swiped.peek() && !self.swipe.is_swiping() && !*self.long_pressed.peek()
    }

    /// Ends the swipe, remembering it so its lift isn't taken for a tap.
    fn end_swipe(&self, bounds: SwipeBounds) -> bool {
        if self.swipe.is_swiping() {
            *self.swiped.write_unchecked() = true;
        }
        self.swipe.end(bounds).is_some()
    }

    /// Wraps `row` (avatar + bubble). `on_reply` is `None` for messages that
    /// can't be replied to yet (unsent local echoes).
    pub fn attach(
        self,
        outer: Rect,
        row: Rect,
        c: AppColors,
        on_long_press: impl Fn() + Clone + 'static,
        on_reply: Option<impl Fn() + Clone + 'static>,
    ) -> Rect {
        let MessageGesture {
            mut press_gen,
            mut long_pressed,
            mut swiped,
            swipe,
            scroll,
        } = self;
        let bounds = if on_reply.is_some() {
            REPLY_SWIPE
        } else {
            NO_SWIPE
        };
        let offset = swipe.offset();
        let progress = (offset / bounds.commit).clamp(0., 1.);

        let reply_icon = (offset > 1.).then(|| {
            rect()
                .position(Position::new_absolute().left(12.).top(0.).bottom(0.))
                // Behind the row: layers grow with nesting depth.
                .layer(-100)
                .height(Size::fill())
                .main_align(Alignment::Center)
                .opacity(progress)
                .child(
                    rect()
                        .width(Size::px(REPLY_ICON))
                        .height(Size::px(REPLY_ICON))
                        .corner_radius(REPLY_ICON / 2.)
                        .background(c.surface_container_high)
                        .center()
                        .scale(0.6 + 0.4 * progress)
                        .child(
                            SvgViewer::new(freya_icons::lucide::reply())
                                .width(Size::px(16.))
                                .height(Size::px(16.))
                                .color(c.on_surface),
                        ),
                )
        });

        let reply = on_reply.clone();
        let reply_fallback = on_reply;
        let this = self;

        outer
            .on_touch_start(move |e: Event<TouchEventData>| {
                swipe.start(e.global_location);
                long_pressed.set(false);
                swiped.set(false);
                let next_gen = *press_gen.peek() + 1;
                press_gen.set(next_gen);
                let on_long_press = on_long_press.clone();
                // Changes once the timeline takes over this touch or sees it end.
                let touch = scroll.touch_generation();
                spawn(async move {
                    timer(LONG_PRESS_DELAY).await;
                    if *press_gen.peek() == next_gen && scroll.touch_generation() == touch {
                        long_pressed.set(true);
                        haptics::play(Haptic::HeavyClick);
                        on_long_press();
                    }
                });
            })
            .on_touch_move(move |e: Event<TouchEventData>| {
                if swipe.moved(e.global_location, bounds) {
                    this.cancel_press();
                }
            })
            .on_touch_end(move |e: Event<TouchEventData>| {
                this.cancel_press();
                // A swipe's or long press's lift must not press the bubble
                // (open an image, …).
                if swipe.is_swiping() || *long_pressed.peek() {
                    e.prevent_default();
                }
                if this.end_swipe(bounds)
                    && let Some(reply) = &reply
                {
                    reply();
                }
            })
            // The timeline cancels `touchend` once it claims the drag, and the
            // finger may lift off this row: finish here too.
            .on_global_pointer_up(move |_: Event<PointerEventData>| {
                if !swipe.is_touching() {
                    return;
                }
                this.cancel_press();
                if this.end_swipe(bounds)
                    && let Some(reply) = &reply_fallback
                {
                    reply();
                }
            })
            .on_touch_cancel(move |_: Event<TouchEventData>| {
                this.cancel_press();
                swipe.cancel();
            })
            .child(
                rect()
                    .width(Size::fill())
                    .overflow(Overflow::Clip)
                    .maybe_child(reply_icon)
                    .child(row.offset_x(offset)),
            )
    }
}
