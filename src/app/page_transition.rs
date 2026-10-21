use std::cell::RefCell;
use std::rc::Rc;

use freya::animation::*;
use freya::prelude::*;
use freya_router::prelude::{Outlet, use_route};

use super::Route;

/// Distance the incoming page slides in from, in pixels.
const SLIDE: f32 = 48.;
const DURATION_MS: u64 = 260;

#[derive(Clone, Copy, PartialEq)]
enum Direction {
    /// Deeper page (room list → room): slides in from the right.
    Forward,
    /// Shallower page (back): slides in from the left.
    Back,
    /// Same depth (tab switch, room → room): fades only.
    Across,
}

/// Bottom navigation tabs: siblings, so switching between them only fades.
const TABS: [&str; 2] = ["/", "/more"];

/// Path depth: tabs are 0, `/room/x` is 2, `/room/x/settings` is 3.
fn depth(path: &str) -> usize {
    if TABS.contains(&path) {
        return 0;
    }
    path.split('/')
        .filter(|segment| !segment.is_empty())
        .count()
}

fn direction(from: &str, to: &str) -> Direction {
    match depth(to).cmp(&depth(from)) {
        std::cmp::Ordering::Greater => Direction::Forward,
        std::cmp::Ordering::Less => Direction::Back,
        std::cmp::Ordering::Equal => Direction::Across,
    }
}

/// The router outlet, with the incoming page sliding and fading in on each
/// navigation. Only the new page animates: the outgoing one isn't kept, so
/// nothing is rendered twice and the outlet never moves in the tree (which
/// would remount the page, e.g. restart a room's timeline).
#[derive(PartialEq)]
pub struct PageTransition;

impl Component for PageTransition {
    fn render(&self) -> impl IntoElement {
        let path = use_route::<Route>().to_string();
        let last = use_hook(|| Rc::new(RefCell::new((path.clone(), Direction::Across))));
        let dir = {
            let mut last = last.borrow_mut();
            if last.0 != path {
                last.1 = direction(&last.0, &path);
                last.0 = path.clone();
            }
            last.1
        };

        let animation = use_animation_with_dependencies(&(path, dir), |conf, (_, dir)| {
            conf.on_creation(OnCreation::Finish);
            conf.on_change(OnChange::Rerun);
            let from = match dir {
                Direction::Forward => SLIDE,
                Direction::Back => -SLIDE,
                Direction::Across => 0.,
            };
            (
                AnimNum::new(from, 0.)
                    .time(DURATION_MS)
                    .ease(Ease::Out)
                    .function(Function::Cubic),
                AnimNum::new(0., 1.)
                    .time(DURATION_MS * 3 / 4)
                    .ease(Ease::Out)
                    .function(Function::Quad),
            )
        });
        let (offset, opacity) = {
            let values = animation.get();
            (values.0.value(), values.1.value())
        };

        rect()
            .expanded()
            .offset_x(offset)
            .opacity(opacity)
            .child(Outlet::<Route>::new())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn deeper_paths_go_forward() {
        assert!(direction("/", "/room/!a:x") == Direction::Forward);
        assert!(direction("/room/!a:x", "/room/!a:x/settings") == Direction::Forward);
        assert!(direction("/room/!a:x/settings", "/room/!a:x") == Direction::Back);
        assert!(direction("/", "/more") == Direction::Across);
        assert!(direction("/", "/settings") == Direction::Forward);
        assert!(direction("/more", "/archived") == Direction::Forward);
        assert!(direction("/settings", "/settings/profile") == Direction::Forward);
        assert!(direction("/room/!a:x", "/room/!b:x") == Direction::Across);
    }
}
