//! Touch gestures of the media viewer, as a plain model (no Freya): paging
//! between images, swiping down (or up) to close, double tap and pinch to
//! zoom, panning a zoomed image, and single taps (toggle the controls).
//! Times are milliseconds from any fixed origin.

/// Travel before a touch counts as a drag rather than a tap.
const SLOP: f32 = 10.;
/// Two taps closer than this (time, distance) are a double tap.
const DOUBLE_TAP_MS: f64 = 300.;
const DOUBLE_TAP_DIST: f32 = 40.;
/// Zoom of a double tap; the pinch range.
pub const ZOOM_IN: f32 = 2.5;
const MIN_SCALE: f32 = 1.;
const MAX_SCALE: f32 = 4.;
/// A flick this fast (px / ms) commits, however short.
const FLICK: f32 = 0.5;
/// Paging past the first or last image only follows the finger this much.
const EDGE_RESISTANCE: f32 = 0.3;

#[derive(Clone, Copy, Debug, PartialEq, Default)]
pub struct Point {
    pub x: f32,
    pub y: f32,
}

impl Point {
    pub fn new(x: f32, y: f32) -> Self {
        Self { x, y }
    }

    fn dist(self, other: Point) -> f32 {
        ((self.x - other.x).powi(2) + (self.y - other.y).powi(2)).sqrt()
    }

    fn mid(self, other: Point) -> Point {
        Point::new((self.x + other.x) / 2., (self.y + other.y) / 2.)
    }
}

#[derive(Clone, Copy, Debug, PartialEq)]
enum Mode {
    Idle,
    /// One finger down, not moved past the slop yet: maybe a tap.
    Pressed { start: Point, time: f64 },
    /// Swiping between images.
    Page { start: Point, time: f64 },
    /// Swiping vertically to close.
    Dismiss { start: Point, time: f64 },
    /// Moving a zoomed image; `moved`: past the slop (else a tap).
    Pan {
        start: Point,
        last: Point,
        time: f64,
        moved: bool,
    },
    /// Two fingers: zoom around their midpoint.
    Pinch {
        dist: f32,
        mid: Point,
        scale: f32,
        offset: Point,
    },
}

/// What a lifted finger decided.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum Release {
    /// Nothing to do (or animate the offsets back to rest).
    None,
    Next,
    Prev,
    Close,
    /// A single tap: toggle the controls unless a second tap follows within
    /// [`Gesture::DOUBLE_TAP_MS`] (see [`Gesture::tap_is_current`]).
    Tap,
    /// A double tap toggled the zoom.
    Zoomed,
}

#[derive(Clone, Debug, PartialEq)]
pub struct Gesture {
    fingers: Vec<(u64, Point)>,
    mode: Mode,
    /// Paging offset of the image strip.
    pub dx: f32,
    /// Dismiss offset of the image.
    pub dy: f32,
    pub scale: f32,
    /// Pan of the zoomed image, from its centred position.
    pub offset: Point,
    /// Viewport size, for thresholds and pan limits.
    pub viewport: Point,
    /// Last single tap: (time, place, count of taps so far).
    last_tap: Option<(f64, Point, u64)>,
    taps: u64,
}

impl Default for Gesture {
    fn default() -> Self {
        Self {
            fingers: Vec::new(),
            mode: Mode::Idle,
            dx: 0.,
            dy: 0.,
            scale: 1.,
            offset: Point::default(),
            viewport: Point::new(400., 800.),
            last_tap: None,
            taps: 0,
        }
    }
}

impl Gesture {
    pub const DOUBLE_TAP_MS: f64 = DOUBLE_TAP_MS;

    pub fn is_zoomed(&self) -> bool {
        self.scale > 1.01
    }

    /// A finger is down: offsets follow it, nothing should animate them.
    pub fn is_active(&self) -> bool {
        !self.fingers.is_empty()
    }

    /// How far the dismiss swipe went, 0 to 1 (fades the background).
    pub fn dismiss_progress(&self) -> f32 {
        (self.dy.abs() / (self.viewport.y * 0.4)).min(1.)
    }

    /// Whether tap number `tap` (from [`Gesture::tap_count`]) is still the
    /// last one: the pending single tap was not followed by another.
    pub fn tap_is_current(&self, tap: u64) -> bool {
        self.taps == tap && self.last_tap.is_some()
    }

    pub fn tap_count(&self) -> u64 {
        self.taps
    }

    /// Back to a fresh, unzoomed image (another image is shown).
    pub fn reset(&mut self) {
        let viewport = self.viewport;
        *self = Self {
            viewport,
            ..Self::default()
        };
    }

    pub fn down(&mut self, id: u64, at: Point, time: f64) {
        self.fingers.retain(|(f, _)| *f != id);
        self.fingers.push((id, at));
        self.mode = match self.fingers.as_slice() {
            [(_, a), (_, b), ..] => Mode::Pinch {
                dist: a.dist(*b).max(1.),
                mid: a.mid(*b),
                scale: self.scale,
                offset: self.offset,
            },
            _ if self.is_zoomed() => Mode::Pan {
                start: at,
                last: at,
                time,
                moved: false,
            },
            _ => Mode::Pressed { start: at, time },
        };
    }

    pub fn moved(&mut self, id: u64, at: Point, has_prev: bool, has_next: bool) {
        if let Some(finger) = self.fingers.iter_mut().find(|(f, _)| *f == id) {
            finger.1 = at;
        } else {
            return;
        }
        match self.mode {
            Mode::Idle => {}
            Mode::Pressed { start, time } => {
                let (ddx, ddy) = (at.x - start.x, at.y - start.y);
                if ddx.abs().max(ddy.abs()) > SLOP {
                    self.mode = if ddx.abs() > ddy.abs() {
                        Mode::Page { start, time }
                    } else {
                        Mode::Dismiss { start, time }
                    };
                    self.moved(id, at, has_prev, has_next);
                }
            }
            Mode::Page { start, .. } => {
                let dx = at.x - start.x;
                let edge = (dx > 0. && !has_prev) || (dx < 0. && !has_next);
                self.dx = if edge { dx * EDGE_RESISTANCE } else { dx };
            }
            Mode::Dismiss { start, .. } => self.dy = at.y - start.y,
            Mode::Pan {
                start,
                last,
                time,
                moved,
            } => {
                self.offset.x += at.x - last.x;
                self.offset.y += at.y - last.y;
                self.mode = Mode::Pan {
                    start,
                    last: at,
                    time,
                    moved: moved || start.dist(at) > SLOP,
                };
                self.clamp_offset();
            }
            Mode::Pinch {
                dist,
                mid,
                scale,
                offset,
            } => {
                let [(_, a), (_, b), ..] = self.fingers.as_slice() else {
                    return;
                };
                let (now_dist, now_mid) = (a.dist(*b), a.mid(*b));
                self.scale = (scale * now_dist / dist).clamp(MIN_SCALE, MAX_SCALE);
                // The point under the fingers' midpoint stays under it.
                let centre = Point::new(self.viewport.x / 2., self.viewport.y / 2.);
                let ratio = self.scale / scale;
                self.offset = Point::new(
                    now_mid.x - centre.x - (mid.x - centre.x - offset.x) * ratio,
                    now_mid.y - centre.y - (mid.y - centre.y - offset.y) * ratio,
                );
                self.clamp_offset();
            }
        }
    }

    pub fn up(&mut self, id: u64, at: Point, time: f64, has_prev: bool, has_next: bool) -> Release {
        self.fingers.retain(|(f, _)| *f != id);
        let mode = self.mode;
        if !self.fingers.is_empty() {
            // One finger of a pinch left: it pans from here.
            if let Some(&(_, last)) = self.fingers.first() {
                self.mode = Mode::Pan {
                    start: last,
                    last,
                    time,
                    moved: true,
                };
            }
            return Release::None;
        }
        self.mode = Mode::Idle;
        // A pinch that barely zoomed goes back to the whole image.
        if matches!(mode, Mode::Pinch { .. } | Mode::Pan { .. }) && self.scale < 1.05 {
            self.scale = 1.;
            self.offset = Point::default();
        }
        match mode {
            Mode::Idle => Release::None,
            Mode::Pressed { .. } => self.tap(at, time),
            Mode::Page { start, time: t0 } => {
                let velocity = (at.x - start.x) / ((time - t0).max(1.) as f32);
                let far = self.dx.abs() > self.viewport.x / 3.;
                let flick = velocity.abs() > FLICK && self.dx.abs() > SLOP;
                match (far || flick, self.dx < 0.) {
                    (true, true) if has_next => Release::Next,
                    (true, false) if has_prev => Release::Prev,
                    _ => Release::None,
                }
            }
            Mode::Dismiss { start, time: t0 } => {
                let velocity = (at.y - start.y) / ((time - t0).max(1.) as f32);
                let far = self.dy.abs() > self.viewport.y * 0.15;
                if far || (velocity.abs() > FLICK && self.dy.abs() > SLOP) {
                    Release::Close
                } else {
                    Release::None
                }
            }
            Mode::Pan { moved: false, .. } => self.tap(at, time),
            Mode::Pan { .. } | Mode::Pinch { .. } => Release::None,
        }
    }

    fn tap(&mut self, at: Point, time: f64) -> Release {
        self.taps += 1;
        let double = self
            .last_tap
            .is_some_and(|(t, p, _)| time - t < DOUBLE_TAP_MS && p.dist(at) < DOUBLE_TAP_DIST);
        if !double {
            self.last_tap = Some((time, at, self.taps));
            return Release::Tap;
        }
        self.last_tap = None;
        if self.is_zoomed() {
            self.scale = 1.;
            self.offset = Point::default();
        } else {
            // The tapped point stays under the finger.
            let centre = Point::new(self.viewport.x / 2., self.viewport.y / 2.);
            self.scale = ZOOM_IN;
            self.offset = Point::new(
                (at.x - centre.x) * (1. - ZOOM_IN),
                (at.y - centre.y) * (1. - ZOOM_IN),
            );
            self.clamp_offset();
        }
        Release::Zoomed
    }

    /// A zoomed image can't be pulled past its edges.
    fn clamp_offset(&mut self) {
        let max_x = (self.scale - 1.) * self.viewport.x / 2.;
        let max_y = (self.scale - 1.) * self.viewport.y / 2.;
        self.offset.x = self.offset.x.clamp(-max_x, max_x);
        self.offset.y = self.offset.y.clamp(-max_y, max_y);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn gesture() -> Gesture {
        Gesture {
            viewport: Point::new(400., 800.),
            ..Gesture::default()
        }
    }

    /// One finger from `from` to `to` over `ms`.
    fn swipe(g: &mut Gesture, from: Point, to: Point, ms: f64, prev: bool, next: bool) -> Release {
        g.down(0, from, 0.);
        let steps = 5;
        for i in 1..=steps {
            let f = i as f32 / steps as f32;
            let at = Point::new(from.x + (to.x - from.x) * f, from.y + (to.y - from.y) * f);
            g.moved(0, at, prev, next);
        }
        g.up(0, to, ms, prev, next)
    }

    #[test]
    fn long_swipe_left_pages_to_the_next_image() {
        let mut g = gesture();
        let r = swipe(&mut g, Point::new(300., 400.), Point::new(100., 410.), 600., true, true);
        assert_eq!(r, Release::Next);
    }

    #[test]
    fn quick_short_flick_right_pages_back() {
        let mut g = gesture();
        let r = swipe(&mut g, Point::new(100., 400.), Point::new(180., 400.), 80., true, true);
        assert_eq!(r, Release::Prev);
    }

    #[test]
    fn slow_short_swipe_snaps_back() {
        let mut g = gesture();
        let r = swipe(&mut g, Point::new(200., 400.), Point::new(150., 400.), 800., true, true);
        assert_eq!(r, Release::None);
    }

    #[test]
    fn no_next_image_resists_and_does_not_page() {
        let mut g = gesture();
        g.down(0, Point::new(300., 400.), 0.);
        g.moved(0, Point::new(100., 400.), true, false);
        assert!(g.dx > -100., "resisted: {}", g.dx);
        assert_eq!(g.up(0, Point::new(100., 400.), 600., true, false), Release::None);
    }

    #[test]
    fn swipe_down_closes() {
        let mut g = gesture();
        let r = swipe(&mut g, Point::new(200., 300.), Point::new(205., 500.), 400., true, true);
        assert_eq!(r, Release::Close);
        assert!(g.dismiss_progress() > 0.5);
    }

    #[test]
    fn tap_then_double_tap_zooms_and_unzooms() {
        let mut g = gesture();
        g.down(0, Point::new(100., 200.), 0.);
        assert_eq!(g.up(0, Point::new(100., 200.), 50., false, false), Release::Tap);
        let first = g.tap_count();
        g.down(0, Point::new(102., 201.), 150.);
        assert_eq!(g.up(0, Point::new(102., 201.), 200., false, false), Release::Zoomed);
        assert!(!g.tap_is_current(first), "the single tap is cancelled");
        assert!(g.is_zoomed());
        // Zoomed on the tapped point: the image moves right and down.
        assert!(g.offset.x > 0. && g.offset.y > 0.);

        g.down(0, Point::new(200., 400.), 1000.);
        g.up(0, Point::new(200., 400.), 1050., false, false);
        g.down(0, Point::new(200., 400.), 1150.);
        assert_eq!(g.up(0, Point::new(200., 400.), 1200., false, false), Release::Zoomed);
        assert!(!g.is_zoomed());
    }

    #[test]
    fn zoomed_drag_pans_within_the_edges_instead_of_paging() {
        let mut g = gesture();
        g.scale = 2.;
        let r = swipe(&mut g, Point::new(300., 400.), Point::new(-500., 400.), 300., true, true);
        assert_eq!(r, Release::None);
        assert_eq!(g.dx, 0.);
        assert_eq!(g.offset.x, -200., "clamped to (scale - 1) * width / 2");
    }

    #[test]
    fn pinch_zooms_and_a_small_pinch_snaps_back() {
        let mut g = gesture();
        g.down(0, Point::new(150., 400.), 0.);
        g.down(1, Point::new(250., 400.), 10.);
        g.moved(0, Point::new(100., 400.), true, true);
        g.moved(1, Point::new(300., 400.), true, true);
        assert!((g.scale - 2.).abs() < 0.01, "spread twice as far: {}", g.scale);
        g.up(0, Point::new(100., 400.), 200., true, true);
        g.up(1, Point::new(300., 400.), 210., true, true);
        assert!(g.is_zoomed());

        let mut g = gesture();
        g.down(0, Point::new(150., 400.), 0.);
        g.down(1, Point::new(250., 400.), 10.);
        g.moved(1, Point::new(252., 400.), true, true);
        g.up(0, Point::new(150., 400.), 200., true, true);
        g.up(1, Point::new(252., 400.), 210., true, true);
        assert!(!g.is_zoomed());
    }
}
