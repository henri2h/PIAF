use std::time::Duration;

use freya::prelude::*;
use freya::text_edit::*;
use freya_core::elements::paragraph::ParagraphCursorExt;

use crate::utils::const_values::AppColors;
use crate::utils::haptics::{self, Haptic};

const LONG_PRESS: Duration = Duration::from_millis(400);
/// A finger moving further than this before the long press is a scroll.
const TOUCH_SLOP: f64 = 10.;

/// Touch editing in the composer: long press then drag moves the cursor, and
/// lifting it (or a double tap selecting a word) shows the edit menu.
#[derive(Clone, Copy, PartialEq)]
pub(super) struct ComposeTouch {
    /// Bumped by each touch start and end: a long-press timer only fires for its own touch.
    generation: State<u64>,
    /// Where the current touch started (global), until it moves too far for a long press.
    start: State<Option<CursorPoint>>,
    /// Whether a touch began in the composer and hasn't ended.
    active: State<bool>,
    /// The cursor follows the finger.
    dragging: State<bool>,
    menu: State<bool>,
}

pub(super) fn use_compose_touch() -> ComposeTouch {
    ComposeTouch {
        generation: use_state(|| 0),
        start: use_state(|| None),
        active: use_state(|| false),
        dragging: use_state(|| false),
        menu: use_state(|| false),
    }
}

impl ComposeTouch {
    pub fn show_menu(mut self, show: bool) {
        self.menu.set_if_modified(show);
    }

    pub fn is_dragging(&self) -> bool {
        *self.dragging.peek()
    }

    pub fn is_menu_shown(&self) -> bool {
        *self.menu.read()
    }

    pub fn touch_start(mut self, location: CursorPoint) {
        self.menu.set_if_modified(false);
        self.active.set(true);
        self.start.set(Some(location));
        let generation = *self.generation.peek() + 1;
        self.generation.set(generation);
        spawn(async move {
            timer(LONG_PRESS).await;
            if *self.generation.peek() == generation && self.start.peek().is_some() {
                self.dragging.set(true);
                haptics::play(Haptic::HeavyClick);
            }
        });
    }

    /// Cancels the pending long press once the finger moved too far.
    pub fn touch_move(mut self, location: CursorPoint) {
        let start = *self.start.peek();
        if let Some(start) = start
            && !*self.dragging.peek()
            && (location - start).length() > TOUCH_SLOP
        {
            self.start.set(None);
        }
    }

    /// `has_selection`: a double tap selected a word.
    pub fn touch_end(mut self, has_selection: bool) {
        if !*self.active.peek() {
            return;
        }
        let was_dragging = *self.dragging.peek();
        *self.generation.write() += 1;
        self.active.set(false);
        self.start.set(None);
        self.dragging.set_if_modified(false);
        if was_dragging || has_selection {
            self.menu.set(true);
        }
    }
}

/// Moves the cursor to `location` (relative to the line's paragraph).
pub(super) fn place_cursor(
    mut editable: UseEditable,
    holder: &ParagraphHolder,
    line_index: usize,
    location: CursorPoint,
) {
    let location = holder.visible_location(location);
    let index = {
        let inner = holder.0.borrow();
        let Some(inner) = inner.as_ref() else {
            return;
        };
        let point = location * inner.scale_factor;
        inner.paragraph.cursor_index_at_point(point.to_tuple())
    };
    let pos = editable
        .editor()
        .peek()
        .measure_selection(index, EditorLine::Paragraph(line_index))
        .pos();
    let cursor = TextSelection::new_cursor(pos);
    if *editable.editor().peek().selection() != cursor {
        *editable.editor_mut().write().selection_mut() = cursor;
    }
}

#[derive(Clone, Copy, PartialEq)]
pub(super) enum EditAction {
    Cut,
    Copy,
    Paste,
    SelectAll,
}

impl EditAction {
    fn label(self) -> &'static str {
        match self {
            Self::Cut => "Cut",
            Self::Copy => "Copy",
            Self::Paste => "Paste",
            Self::SelectAll => "Select all",
        }
    }

    /// The editor's own shortcut for it: the editor does the work (history,
    /// clipboard), like a hardware keyboard would.
    pub fn apply(self, mut editable: UseEditable) {
        let key = match self {
            Self::Cut => "x",
            Self::Copy => "c",
            Self::Paste => "v",
            Self::SelectAll => "a",
        };
        editable.process_event(EditableEvent::KeyDown {
            key: &Key::Character(key.into()),
            modifiers: Modifiers::CONTROL,
            editor_line: None,
            holder: None,
        });
    }
}

/// Floating bar above the composer: Cut / Copy (with a selection), Paste, Select all.
pub(super) fn edit_menu(
    c: AppColors,
    has_selection: bool,
    on_action: impl Fn(EditAction) + Clone + 'static,
) -> Element {
    let actions: &[EditAction] = if has_selection {
        &[EditAction::Cut, EditAction::Copy, EditAction::Paste, EditAction::SelectAll]
    } else {
        &[EditAction::Paste, EditAction::SelectAll]
    };
    rect()
        .position(Position::new_absolute().top(-44.).left(48.))
        // Above the timeline rows (layers grow per nesting level).
        .layer(1000)
        .horizontal()
        .padding(Gaps::new_all(4.))
        .corner_radius(20.)
        .background(c.surface_container_high)
        .shadow(Shadow::new().y(2.).blur(6.).color((0, 0, 0, 50)))
        .children(actions.iter().map(|&action| {
            let on_action = on_action.clone();
            rect()
                .padding(Gaps::new(8., 14., 8., 14.))
                .corner_radius(16.)
                .on_press(move |_| on_action(action))
                .child(label().text(action.label()).font_size(14.).color(c.on_surface))
                .into_element()
        }))
        .into_element()
}
