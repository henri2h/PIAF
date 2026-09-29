//! Scroll-to-event: `FOCUS_EVENT` hand-off from search/bookmarks, and offsets.

use std::collections::HashMap;
use std::sync::Arc;

use matrix_sdk_ui::timeline::TimelineItem;

use crate::utils::bridge_watch;
use crate::{FOCUS_EVENT_RX, FOCUS_EVENT_TX};

const DEFAULT_MSG_HEIGHT: f32 = 60.0;

/// Takes the pending focus event if it targets `room_id`. Clears it either way,
/// so a focus from an aborted navigation can't leak into a later room.
pub(super) fn take_focus_event(room_id: &str) -> Option<String> {
    let pending = FOCUS_EVENT_RX
        .get()
        .expect("not initialized")
        .borrow()
        .clone();
    if pending.is_some() {
        let _ = FOCUS_EVENT_TX.get().expect("not initialized").send(None);
    }
    pending.and_then(|(rid, eid)| (rid == room_id).then_some(eid))
}

/// Calls `on_focus` for focus requests targeting `room_id` while it's mounted.
pub(super) fn watch_focus_events(room_id: String, mut on_focus: impl FnMut(String) + 'static) {
    bridge_watch(
        FOCUS_EVENT_RX.get().expect("not initialized"),
        move |pending| {
            if let Some((rid, eid)) = pending
                && rid == room_id
            {
                let _ = FOCUS_EVENT_TX.get().expect("not initialized").send(None);
                on_focus(eid);
            }
        },
    );
}

/// Row key: event id, or the stable `unique_id` for virtual items (date dividers, read markers).
pub(super) fn row_key(item: &TimelineItem) -> String {
    item.as_event()
        .and_then(|e| e.event_id())
        .map(|id| id.to_string())
        .unwrap_or_else(|| format!("virtual-{}", item.unique_id().0))
}

/// Y offset of `event_id` from the top, from measured row heights.
pub(super) fn event_offset(
    msgs: &[Arc<TimelineItem>],
    heights: &HashMap<String, f32>,
    event_id: &str,
) -> Option<f32> {
    let idx = msgs.iter().position(|item| {
        item.as_event()
            .and_then(|ev| ev.event_id())
            .is_some_and(|id| id.as_str() == event_id)
    })?;
    let offset = msgs[..idx]
        .iter()
        .map(|item| {
            heights
                .get(&row_key(item))
                .copied()
                .unwrap_or(DEFAULT_MSG_HEIGHT)
        })
        .sum();
    Some(offset)
}
