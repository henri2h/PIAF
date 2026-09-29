use std::sync::Arc;

use freya::prelude::*;
use matrix_sdk_ui::timeline::TimelineItem;

use super::timeline_task::{TimelineEvents, TimelineHandle, spawn_timeline};

/// Reactive timeline state, owned by the component that called `use_room_timeline`.
#[derive(Clone, Copy, PartialEq)]
pub(super) struct TimelineState {
    pub messages: State<Vec<Arc<TimelineItem>>>,
    pub room_name: State<String>,
    pub is_dm: State<bool>,
    pub loading: State<bool>,
    pub paginating: State<bool>,
    pub at_start: State<bool>,
    /// Keep paginating while content is shorter than the viewport.
    pub auto_fill: State<bool>,
    pub typing_users: State<Vec<String>>,
    /// Event to scroll to once rows are measured.
    pub pending_focus: State<Option<String>>,
}

#[derive(Clone, PartialEq)]
pub(super) struct RoomTimeline {
    pub handle: TimelineHandle,
    pub state: TimelineState,
}

impl RoomTimeline {
    /// Starts a page load unless one is running or history is exhausted.
    pub fn request_page(&self) {
        let mut paginating = self.state.paginating;
        if !*paginating.peek() && !*self.state.at_start.peek() {
            paginating.set(true);
            self.handle.paginate();
        }
    }
}

pub(super) fn use_room_timeline(room_id: &str, focus_event_id: Option<String>) -> RoomTimeline {
    let state = TimelineState {
        messages: use_state(Vec::new),
        room_name: use_state(|| room_id.to_string()),
        is_dm: use_state(|| false),
        loading: use_state(|| true),
        paginating: use_state(|| false),
        at_start: use_state(|| false),
        auto_fill: use_state(|| false),
        typing_users: use_state(Vec::new),
        pending_focus: use_state(|| None),
    };

    // The receive loop must not hold the handle: dropping it is what stops the task.
    let handle = use_hook(|| {
        let (handle, events) = spawn_timeline(room_id.to_string(), focus_event_id.clone());
        spawn(receive(state, events, focus_event_id));
        handle
    });

    RoomTimeline { handle, state }
}

/// Smol side: mirrors timeline task output into the states.
async fn receive(mut st: TimelineState, mut events: TimelineEvents, focus: Option<String>) {
    if let Ok((name, dm, msgs)) = events.init.await {
        st.room_name.set(name);
        st.is_dm.set(dm);
        st.pending_focus.set(focus);
        st.messages.set(msgs);
    }
    st.loading.set(false);
    st.auto_fill.set(true);

    loop {
        tokio::select! {
            done = events.page_done.recv() => {
                let Some(hit_start) = done else { break; };
                st.paginating.set(false);
                if hit_start {
                    st.at_start.set(true);
                    st.auto_fill.set(false);
                }
            }
            update = events.updates.recv() => {
                let Some(msgs) = update else { break; };
                let unchanged_len = msgs.len() == st.messages.peek().len();
                st.messages.set(msgs);
                st.paginating.set(false);
                if unchanged_len {
                    st.auto_fill.set(false);
                }
            }
            typing = events.typing.recv() => {
                let Some(users) = typing else { break; };
                st.typing_users.set(users);
            }
        }
    }
}
