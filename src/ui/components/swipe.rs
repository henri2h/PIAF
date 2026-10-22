use freya::animation::*;
use freya::prelude::*;

use crate::utils::haptics::{self, Haptic};

/// Travel before a touch picks its direction. The scroll view decides with
/// the same rule (`claim_drag`: 8px, vertical when `|dy| >= |dx|`), so a drag
/// is always either the list's or the row's, never neither.
const SWIPE_SLOP: f64 = 8.0;
const SNAP_BACK_MS: u64 = 420;

/// Underdamped spring from 0 to 1: a slight overshoot past rest, then settles.
fn spring(t: f32, _: Ease) -> f32 {
    1. - (-7. * t).exp() * (9. * t).cos()
}

/// Limits of a swipe: how far each side can go and where it commits.
#[derive(Clone, Copy)]
pub struct SwipeBounds {
    /// Furthest leftwards travel (0 disables that side).
    pub max_left: f64,
    /// Furthest rightwards travel (0 disables that side).
    pub max_right: f64,
    /// Travel past which releasing triggers the action.
    pub commit: f32,
}

/// Horizontal swipe on a touch row: follows the finger, ticks when it passes
/// the commit point, and springs back on release. Wire `start` / `moved` /
/// `end` / `cancel` to the row's touch events and draw it at `offset()`.
#[derive(Clone, Copy, PartialEq)]
pub struct Swipe {
    start: State<Option<(f64, f64)>>,
    swiping: State<bool>,
    /// Finger offset while swiping.
    offset: State<f32>,
    /// `(release count, offset at release)`: each release springs from there to 0.
    release: State<(u64, f32)>,
    /// Whether the finger is past the commit point (for the haptic tick).
    armed: State<bool>,
    snap_offset: f32,
}

pub fn use_swipe() -> Swipe {
    let release = use_state(|| (0u64, 0.0f32));
    let released = *release.read();
    let snap = use_animation_with_dependencies(&released, |conf, &(_, from)| {
        conf.on_creation(OnCreation::Finish);
        conf.on_change(OnChange::Rerun);
        AnimNum::new(from, 0.)
            .time(SNAP_BACK_MS)
            .function(Function::Fn(spring))
    });
    let snap_offset = snap.get().value();
    Swipe {
        start: use_state(|| None),
        swiping: use_state(|| false),
        offset: use_state(|| 0.),
        release,
        armed: use_state(|| false),
        snap_offset,
    }
}

impl Swipe {
    /// Offset to draw the row at.
    pub fn offset(&self) -> f32 {
        if *self.swiping.read() {
            *self.offset.read()
        } else {
            self.snap_offset
        }
    }

    pub fn is_swiping(&self) -> bool {
        *self.swiping.peek()
    }

    /// Whether a touch on this row is in progress.
    pub fn is_touching(&self) -> bool {
        self.start.peek().is_some()
    }

    pub fn start(&self, location: CursorPoint) {
        let mut start = self.start;
        start.set(Some((location.x, location.y)));
    }

    /// Feeds a touch move. Returns whether the touch moved at all, so callers
    /// can cancel a pending long press.
    pub fn moved(&self, location: CursorPoint, bounds: SwipeBounds) -> bool {
        let Some((sx, sy)) = *self.start.peek() else {
            return false;
        };
        let (dx, dy) = (location.x - sx, location.y - sy);
        let (mut swiping, mut offset, mut armed) = (self.swiping, self.offset, self.armed);

        if !*swiping.peek() {
            let allowed = (dx > 0. && bounds.max_right > 0.) || (dx < 0. && bounds.max_left > 0.);
            if allowed && dx.abs().max(dy.abs()) > SWIPE_SLOP && dx.abs() > dy.abs() {
                swiping.set(true);
                // Follows the finger from here, without jumping by the slop.
                let mut start = self.start;
                start.set(Some((location.x, sy)));
            } else {
                return dx != 0. || dy != 0.;
            }
        }

        let dx = location.x - self.start.peek().map_or(location.x, |(x, _)| x);
        let value = dx.clamp(-bounds.max_left, bounds.max_right) as f32;
        offset.set(value);
        let past = value.abs() > bounds.commit;
        if past != *armed.peek() {
            armed.set(past);
            if past {
                haptics::play(Haptic::Tick);
            }
        }
        true
    }

    /// Ends the touch. Returns the released offset when it was a swipe past
    /// the commit point.
    pub fn end(&self, bounds: SwipeBounds) -> Option<f32> {
        let was_swiping = self.is_swiping();
        let released = *self.offset.peek();
        self.reset();
        (was_swiping && released.abs() > bounds.commit).then_some(released)
    }

    pub fn cancel(&self) {
        self.reset();
    }

    /// Springs back from wherever the row is.
    fn reset(&self) {
        let (mut start, mut swiping, mut offset, mut release, mut armed) = (
            self.start,
            self.swiping,
            self.offset,
            self.release,
            self.armed,
        );
        if *swiping.peek() {
            let count = release.peek().0 + 1;
            release.set((count, *offset.peek()));
        }
        swiping.set(false);
        offset.set(0.);
        armed.set(false);
        start.set(None);
    }
}

#[cfg(test)]
mod tests {
    use std::cell::Cell;

    use freya::prelude::*;
    use freya_testing::prelude::launch_test;

    use super::{SwipeBounds, use_swipe};

    const BOUNDS: SwipeBounds = SwipeBounds {
        max_left: 120.,
        max_right: 120.,
        commit: 88.,
    };

    thread_local! {
        static OFFSET: Cell<f32> = const { Cell::new(0.) };
        static COMMITTED: Cell<Option<f32>> = const { Cell::new(None) };
    }

    fn app() -> impl IntoElement {
        let swipe = use_swipe();
        OFFSET.with(|o| o.set(swipe.offset()));
        rect()
            .width(Size::px(300.))
            .height(Size::px(60.))
            .on_touch_start(move |e: Event<TouchEventData>| swipe.start(e.global_location))
            .on_touch_move(move |e: Event<TouchEventData>| {
                swipe.moved(e.global_location, BOUNDS);
            })
            .on_touch_end(move |_: Event<TouchEventData>| {
                COMMITTED.with(|c| c.set(swipe.end(BOUNDS)))
            })
    }

    /// A drag leaning horizontal past the scroll view's slop is the row's,
    /// even at a steep angle, and the row starts from where it was.
    #[test]
    fn diagonal_drag_swipes_without_jumping() {
        let mut test = launch_test(app);
        test.sync_and_update();
        test.press_touch((100., 30.));
        test.move_touch((110., 37.));
        test.sync_and_update();
        assert_eq!(OFFSET.with(Cell::get), 0.);
        test.move_touch((140., 45.));
        test.sync_and_update();
        assert_eq!(OFFSET.with(Cell::get), 30.);
        test.move_touch((230., 50.));
        test.release_touch((230., 50.));
        test.sync_and_update();
        assert_eq!(COMMITTED.with(Cell::get), Some(120.));
    }

    /// A drag leaning vertical is the list's scroll, not a swipe.
    #[test]
    fn vertical_drag_is_no_swipe() {
        let mut test = launch_test(app);
        test.sync_and_update();
        test.press_touch((100., 10.));
        test.move_touch((108., 20.));
        test.move_touch((200., 30.));
        test.sync_and_update();
        assert_eq!(OFFSET.with(Cell::get), 0.);
        test.release_touch((200., 30.));
        test.sync_and_update();
        assert_eq!(COMMITTED.with(Cell::get), None);
    }
}
