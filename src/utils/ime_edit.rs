//! Applying the soft keyboard's edits (`ImeEvent`) to a Freya text editor:
//! shared by the composer and the Android search field.

use std::cell::RefCell;
use std::rc::Rc;

use freya::text_edit::*;

use crate::utils::ime::ImeEvent;

/// The soft keyboard's word in progress, as a UTF-16 range of ordinary text.
/// Not the editor's preedit: that keeps its own copy of the range, which goes
/// stale (and panics) when the text changes under it. This one is clamped to
/// the text at every use.
pub type Composing = Rc<RefCell<Option<(usize, usize)>>>;

/// Applies what the soft keyboard did (see [`ImeEvent`]) to the editor.
pub fn apply_ime_event(
    editor: &mut RopeEditor,
    composing: &RefCell<Option<(usize, usize)>>,
    event: ImeEvent,
) {
    let len = editor.len_utf16_cu();
    let clamp = |(a, b): (usize, usize)| (a.min(b).min(len), a.max(b).min(len));
    // The composition, else the selection: what typed text replaces.
    let target = composing
        .borrow()
        .or_else(|| editor.get_selection_range())
        .unwrap_or_else(|| {
            let cursor = editor.cursor_pos();
            (cursor, cursor)
        });
    let (start, end) = clamp(target);
    let mut replace = |text: &str| {
        if end > start {
            editor.remove(start..end);
        }
        editor.insert(text, start);
        let text_end = start + text.encode_utf16().count();
        *editor.selection_mut() = TextSelection::new_cursor(text_end);
        text_end
    };
    match event {
        ImeEvent::Commit(text) => {
            replace(&text);
            *composing.borrow_mut() = None;
        }
        ImeEvent::Preedit(text) => {
            let text_end = replace(&text);
            *composing.borrow_mut() = (!text.is_empty()).then_some((start, text_end));
        }
        ImeEvent::ComposingRegion { start, end } => {
            *composing.borrow_mut() = Some(clamp((start, end))).filter(|(a, b)| b > a);
        }
        ImeEvent::Select { start, end } => {
            let (start, end) = (start.min(len), end.min(len));
            *editor.selection_mut() = if start == end {
                TextSelection::new_cursor(start)
            } else {
                TextSelection::new_range((start, end))
            };
        }
        // Around the selection (Android's `deleteSurroundingText`); the
        // composition shifts with the text.
        // Handled by the field (search), not an edit.
        ImeEvent::Action => {}
        ImeEvent::Delete { before, after } => {
            let (sel_start, sel_end) = editor
                .get_selection_range()
                .unwrap_or_else(|| (editor.cursor_pos(), editor.cursor_pos()));
            let (sel_start, sel_end) = clamp((sel_start, sel_end));
            let removed_after = (sel_end, (sel_end + after).min(len));
            let removed_before = (sel_start.saturating_sub(before), sel_start);
            for (a, b) in [removed_after, removed_before] {
                if b > a {
                    editor.remove(a..b);
                    let shift = |pos: usize| {
                        if pos <= a {
                            pos
                        } else if pos >= b {
                            pos - (b - a)
                        } else {
                            a
                        }
                    };
                    let range = *composing.borrow();
                    *composing.borrow_mut() = range
                        .map(|(s, e)| (shift(s), shift(e)))
                        .filter(|(s, e)| e > s);
                }
            }
            let cursor = removed_before.0;
            *editor.selection_mut() = if sel_end > sel_start {
                TextSelection::new_range((cursor, cursor + (sel_end - sel_start)))
            } else {
                TextSelection::new_cursor(cursor)
            };
        }
    }
}

/// Before an edit that doesn't come from the keyboard: the word in progress
/// stays as plain text.
pub fn finish_composition(composing: &RefCell<Option<(usize, usize)>>) {
    composing.borrow_mut().take();
}

#[cfg(test)]
mod tests {
    use std::time::Duration;

    use super::*;

    fn editor(text: &str, cursor: usize) -> RopeEditor {
        RopeEditor::new(
            text.to_string(),
            TextSelection::new_cursor(cursor),
            0,
            EditorHistory::new(Duration::from_millis(10)),
        )
    }

    fn text(editor: &RopeEditor) -> String {
        editor.rope().to_string()
    }

    #[test]
    fn composition_is_rewritten_in_place_then_committed() {
        let mut e = editor("", 0);
        let composing = RefCell::new(None);
        apply_ime_event(&mut e, &composing, ImeEvent::Preedit("he".into()));
        apply_ime_event(&mut e, &composing, ImeEvent::Preedit("hel".into()));
        apply_ime_event(&mut e, &composing, ImeEvent::Commit("hello ".into()));
        assert_eq!(text(&e), "hello ");
        assert_eq!(e.cursor_pos(), 6);
        assert_eq!(*composing.borrow(), None);
    }

    #[test]
    fn composing_region_re_edits_a_word_without_duplicating_it() {
        let mut e = editor("hel world", 3);
        let composing = RefCell::new(None);
        apply_ime_event(
            &mut e,
            &composing,
            ImeEvent::ComposingRegion { start: 0, end: 3 },
        );
        apply_ime_event(&mut e, &composing, ImeEvent::Preedit("help".into()));
        assert_eq!(text(&e), "help world");
    }

    #[test]
    fn stale_ranges_are_clamped_instead_of_panicking() {
        // The crashes: a range from longer text after select all / cut.
        let mut e = editor("short", 5);
        let composing = RefCell::new(Some((100, 141)));
        apply_ime_event(
            &mut e,
            &composing,
            ImeEvent::ComposingRegion {
                start: 141,
                end: 221,
            },
        );
        apply_ime_event(&mut e, &composing, ImeEvent::Preedit("x".into()));
        apply_ime_event(&mut e, &composing, ImeEvent::Commit("y".into()));
        apply_ime_event(
            &mut e,
            &composing,
            ImeEvent::Delete {
                before: 50,
                after: 50,
            },
        );
        apply_ime_event(
            &mut e,
            &composing,
            ImeEvent::Select {
                start: 99,
                end: 300,
            },
        );
        assert!(text(&e).len() <= "shorty".len());
    }

    #[test]
    fn delete_shifts_the_composition() {
        let mut e = editor("ab cd", 5);
        let composing = RefCell::new(Some((3, 5)));
        *e.selection_mut() = TextSelection::new_cursor(3);
        apply_ime_event(
            &mut e,
            &composing,
            ImeEvent::Delete {
                before: 1,
                after: 0,
            },
        );
        assert_eq!(text(&e), "abcd");
        assert_eq!(*composing.borrow(), Some((2, 4)));
    }

    #[test]
    fn commit_replaces_a_selection() {
        let mut e = editor("hello", 0);
        e.set_selection((0, 5));
        let composing = RefCell::new(None);
        apply_ime_event(&mut e, &composing, ImeEvent::Commit("bye".into()));
        assert_eq!(text(&e), "bye");
    }
}
