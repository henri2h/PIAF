use freya::animation::*;
use freya::prelude::*;

use crate::utils::haptics::{self, Haptic};

/// Horizontal travel before a touch counts as a swipe.
const SWIPE_SLOP: f64 = 12.0;
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
            if allowed && dx.abs() > SWIPE_SLOP && dx.abs() > dy.abs() * 1.5 {
                swiping.set(true);
            } else {
                return dx != 0. || dy != 0.;
            }
        }

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
        let (mut start, mut swiping, mut offset, mut release, mut armed) =
            (self.start, self.swiping, self.offset, self.release, self.armed);
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
