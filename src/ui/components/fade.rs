use freya::animation::*;
use freya::prelude::*;

/// Opacity that eases to 1 when `visible` turns true and to 0 when it turns
/// false. Starts at its end value: nothing animates on mount, so remounts
/// (scrolling a virtual list) don't flash.
pub fn use_fade(visible: bool, ms: u64) -> f32 {
    let animation = use_animation_with_dependencies(&visible, move |conf, visible| {
        conf.on_creation(OnCreation::Finish);
        conf.on_change(OnChange::Rerun);
        let (from, to) = if *visible { (0., 1.) } else { (1., 0.) };
        AnimNum::new(from, to).time(ms).ease(Ease::Out)
    });
    animation.get().value()
}

/// For something that appears and disappears: `current` while it is `Some`,
/// then its last `Some` value while it fades out, with the opacity to draw
/// it at. `None` once fully hidden.
pub fn use_fading<T: Clone + PartialEq + 'static>(current: Option<T>, ms: u64) -> Option<(T, f32)> {
    let mut last = use_state(|| None::<T>);
    if current.is_some() && *last.peek() != current {
        last.set(current.clone());
    }
    let opacity = use_fade(current.is_some(), ms);
    let shown = match current {
        Some(value) => value,
        None if opacity > 0. => last.peek().clone()?,
        None => return None,
    };
    Some((shown, opacity))
}

/// `target`, easing from the previous colour whenever it changes (e.g. a
/// bar tinting as content scrolls under it). No animation on mount.
pub fn use_color_transition(target: (u8, u8, u8), ms: u64) -> Color {
    let previous = use_hook(|| std::rc::Rc::new(std::cell::Cell::new(target)));
    let animation = use_animation_with_dependencies(&target, move |conf, &to| {
        conf.on_creation(OnCreation::Finish);
        conf.on_change(OnChange::Rerun);
        let from = previous.replace(to);
        AnimColor::new(from, to).time(ms).ease(Ease::Out)
    });
    animation.get().value()
}
