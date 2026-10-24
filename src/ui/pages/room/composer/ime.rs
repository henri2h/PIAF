//! The soft keyboard (Android) driving the composer through the IME bridge.

use std::cell::{Cell, RefCell};
use std::rc::Rc;

use freya::prelude::*;
use freya::text_edit::*;

use crate::utils::ime::{self, ImeKind};
use crate::utils::ime_edit::{Composing, apply_ime_event, finish_composition};

/// Shows the keyboard while `focus` is focused, applies what it types to
/// `editable` and re-syncs it when the text changes elsewhere (send, a
/// mention, a cursor tap).
pub(super) fn use_composer_ime(mut editable: UseEditable, focus: Memo<Focus>, preedit: Composing) {
    let is_focused = focus().is_focused();
    // The text and cursor the keyboard last saw: only changes made
    // elsewhere re-sync it.
    let ime_seen = use_hook(|| Rc::new(RefCell::new((String::new(), 0usize))));
    // Token of this composer's last `ime::show`: hiding never closes another's keyboard.
    let ime_owner = use_hook(|| Rc::new(Cell::new(0u64)));
    // `peek`: callers that must re-run on edits read the editor themselves.
    let editor_snapshot = move || {
        let editor = editable.editor().peek();
        (editor.rope().to_string(), editor.cursor_pos())
    };
    // Both a show and a re-sync restart the keyboard with no word in progress.
    {
        let ime_seen = ime_seen.clone();
        let ime_owner = ime_owner.clone();
        let preedit = preedit.clone();
        use_side_effect_with_deps(&is_focused, move |&focused| {
            tracing::debug!(target: "piaf::composer", focused, "focus changed");
            if focused {
                finish_composition(&preedit);
                let (text, cursor) = editor_snapshot();
                ime_owner.set(ime::show(&text, cursor, ImeKind::Composer));
                *ime_seen.borrow_mut() = (text, cursor);
            } else {
                ime::hide(ime_owner.get());
            }
        });
    }
    {
        let ime_seen = ime_seen.clone();
        let preedit = preedit.clone();
        use_side_effect(move || {
            // Subscribes: runs after every edit.
            let _ = editable.editor().read();
            let snapshot = editor_snapshot();
            if focus.peek().is_focused() && *ime_seen.borrow() != snapshot {
                tracing::debug!(target: "piaf::composer", "text changed outside the keyboard: sync");
                finish_composition(&preedit);
                ime::sync(&snapshot.0, snapshot.1);
                *ime_seen.borrow_mut() = snapshot;
            }
        });
    }
    {
        let ime_owner = ime_owner.clone();
        use_drop(move || ime::hide(ime_owner.get()));
    }
    use_hook(move || {
        crate::utils::bridge_watch(&ime::events(), move |_| {
            // Left queued for the focused composer (another one, mid-swap).
            if !focus.peek().is_focused() {
                return;
            }
            for event in ime::drain() {
                apply_ime_event(&mut editable.editor_mut().write(), &preedit, event);
            }
            *ime_seen.borrow_mut() = editor_snapshot();
        });
    });
}
