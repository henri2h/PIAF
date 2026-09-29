//! Desktop keyboard navigation (vim-style). `Layout` turns raw keys into
//! [`KeyCommand`]s and publishes them on the [`KeyNav`] bus; each component
//! reacts to the commands for its area. Keys are ignored while a text field
//! has focus, except `Esc`.

use std::cell::Cell;
use std::rc::Rc;
use std::time::{Duration, Instant};

use freya::prelude::*;

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum KeyCommand {
    Down,
    Up,
    Top,
    Bottom,
    NextUnread,
    PrevUnread,
    Open,
    Back,
    HalfPageDown,
    HalfPageUp,
    FocusComposer,
    Search,
    ToggleFavourite,
    ToggleRead,
    Archive,
}

/// Which pane keys go to. In narrow layouts it follows the route instead.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum Area {
    List,
    Room,
}

/// Shared keyboard state, provided by the desktop `Layout`.
#[derive(Clone, Copy, PartialEq)]
pub struct KeyNav {
    /// Latest command, with a sequence number so repeats are distinct.
    pub command: State<Option<(u64, KeyCommand)>>,
    pub area: State<Area>,
    /// Room highlighted in the list (keyboard cursor).
    pub selected: State<Option<String>>,
    pub help_open: State<bool>,
}

impl KeyNav {
    pub fn send(&self, command: KeyCommand) {
        let mut bus = self.command;
        let seq = bus.peek().map_or(0, |(seq, _)| seq + 1);
        bus.set(Some((seq, command)));
    }
}

pub fn use_provide_key_nav() -> KeyNav {
    let nav = KeyNav {
        command: use_state(|| None),
        area: use_state(|| Area::List),
        selected: use_state(|| None),
        help_open: use_state(|| false),
    };
    use_provide_context(|| nav);
    nav
}

/// `None` where keyboard navigation isn't set up (Android).
pub fn use_key_nav() -> Option<KeyNav> {
    use_try_consume::<KeyNav>()
}

/// Calls `handler` for each new command. Commands sent before the calling
/// component mounted are skipped, so remounting never replays one. No-op
/// without keyboard navigation (Android).
pub fn use_key_commands(mut handler: impl FnMut(KeyNav, KeyCommand) + 'static) {
    let nav = use_key_nav();
    let handled = use_hook(|| {
        Rc::new(Cell::new(
            nav.and_then(|n| (*n.command.peek()).map(|(seq, _)| seq)),
        ))
    });
    use_side_effect(move || {
        let Some(nav) = nav else { return };
        let Some((seq, command)) = *nav.command.read() else {
            return;
        };
        if handled.replace(Some(seq)) != Some(seq) {
            handler(nav, command);
        }
    });
}

/// True while typing into a text field, when single-letter keys must not act.
pub fn text_input_focused() -> bool {
    let node = Platform::get().focused_accessibility_node;
    matches!(
        node.read().role(),
        AccessibilityRole::TextInput
            | AccessibilityRole::MultilineTextInput
            | AccessibilityRole::PasswordInput
            | AccessibilityRole::SearchInput
    )
}

/// Maximum gap between the two keys of a sequence like `gg`.
const SEQUENCE_TIMEOUT: Duration = Duration::from_millis(800);

/// What a key press means, given the previous key (for `gg`).
#[derive(Debug, PartialEq)]
pub enum Parsed {
    Command(KeyCommand),
    ToggleHelp,
    /// First key of a sequence; remember it.
    Pending,
    None,
}

pub fn parse(key: &Key, ctrl: bool, pending_g: Option<Instant>, now: Instant) -> Parsed {
    use KeyCommand::*;
    let g_pending = pending_g.is_some_and(|t| now.duration_since(t) < SEQUENCE_TIMEOUT);
    match key {
        Key::Named(NamedKey::ArrowDown) => Parsed::Command(Down),
        Key::Named(NamedKey::ArrowUp) => Parsed::Command(Up),
        Key::Named(NamedKey::Enter) => Parsed::Command(Open),
        Key::Named(NamedKey::Escape) => Parsed::Command(Back),
        Key::Character(c) => match (c.as_str(), ctrl) {
            ("d", true) => Parsed::Command(HalfPageDown),
            ("u", true) => Parsed::Command(HalfPageUp),
            (_, true) => Parsed::None,
            ("g", false) if g_pending => Parsed::Command(Top),
            ("g", false) => Parsed::Pending,
            ("j", _) => Parsed::Command(Down),
            ("k", _) => Parsed::Command(Up),
            ("G", _) => Parsed::Command(Bottom),
            ("J", _) => Parsed::Command(NextUnread),
            ("K", _) => Parsed::Command(PrevUnread),
            ("l" | "o", _) => Parsed::Command(Open),
            ("h", _) => Parsed::Command(Back),
            ("i", _) => Parsed::Command(FocusComposer),
            ("/", _) => Parsed::Command(Search),
            ("f", _) => Parsed::Command(ToggleFavourite),
            ("u", _) => Parsed::Command(ToggleRead),
            ("x", _) => Parsed::Command(Archive),
            ("?", _) => Parsed::ToggleHelp,
            _ => Parsed::None,
        },
        _ => Parsed::None,
    }
}

/// Shown by `?`.
pub const HELP: &[(&str, &str)] = &[
    ("j / k", "Next / previous room, or scroll the room"),
    ("g g / G", "Top / bottom"),
    ("J / K", "Next / previous unread room"),
    ("Enter / l", "Open room"),
    ("h / Esc", "Back to the room list"),
    ("Ctrl-d / Ctrl-u", "Scroll half a page"),
    ("i", "Write a message"),
    ("/", "Search"),
    ("f", "Toggle favourite"),
    ("u", "Toggle read / unread"),
    ("x", "Archive"),
    ("?", "This help"),
];

#[cfg(test)]
mod tests {
    use super::*;

    fn ch(c: &str) -> Key {
        Key::Character(c.into())
    }

    #[test]
    fn single_keys() {
        let now = Instant::now();
        assert_eq!(
            parse(&ch("j"), false, None, now),
            Parsed::Command(KeyCommand::Down)
        );
        assert_eq!(
            parse(&ch("G"), false, None, now),
            Parsed::Command(KeyCommand::Bottom)
        );
        assert_eq!(
            parse(&ch("u"), true, None, now),
            Parsed::Command(KeyCommand::HalfPageUp)
        );
        assert_eq!(
            parse(&ch("u"), false, None, now),
            Parsed::Command(KeyCommand::ToggleRead)
        );
        assert_eq!(parse(&ch("?"), false, None, now), Parsed::ToggleHelp);
    }

    #[test]
    fn gg_sequence_expires() {
        let start = Instant::now();
        assert_eq!(parse(&ch("g"), false, None, start), Parsed::Pending);
        assert_eq!(
            parse(
                &ch("g"),
                false,
                Some(start),
                start + Duration::from_millis(200)
            ),
            Parsed::Command(KeyCommand::Top)
        );
        assert_eq!(
            parse(&ch("g"), false, Some(start), start + Duration::from_secs(2)),
            Parsed::Pending
        );
    }

    #[test]
    fn ctrl_combos_do_not_trigger_letters() {
        assert_eq!(parse(&ch("j"), true, None, Instant::now()), Parsed::None);
    }
}
