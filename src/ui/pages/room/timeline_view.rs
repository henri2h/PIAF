use std::collections::HashMap;
use std::sync::Arc;

use freya::prelude::*;
use matrix_sdk_ui::timeline::TimelineItem;

use super::focus::{event_offset, row_key, watch_focus_events};
use super::message_row::MessageRow;
use super::room_start_banner::RoomStartBanner;
use super::use_room_timeline::RoomTimeline;
use crate::app::keys::{Area, KeyCommand, use_key_commands};
use crate::logging::RenderTimer;
use crate::utils::matrix::my_user_id;
use crate::utils::{format_date_key, format_date_label, use_app_colors};

/// Load older messages once scrolled within this distance of the top.
const LOAD_MORE_THRESHOLD_PX: i32 = 400;

/// Scrollable message list. Anchored to the bottom: backfilled history lands
/// above without moving what's on screen, and short rooms rest on the composer.
/// `scroll_controller` is owned by `RoomPage` so the position survives the
/// media viewer unmounting this view.
#[derive(PartialEq)]
pub(super) struct TimelineView {
    pub room_id: String,
    pub timeline: RoomTimeline,
    pub scroll_controller: ScrollController,
}

impl Component for TimelineView {
    fn render(&self) -> impl IntoElement {
        let _timer = RenderTimer::new("TimelineView");
        let c = use_app_colors();
        let tl = self.timeline.clone();
        let st = tl.state;
        let mut scroll_controller = self.scroll_controller;

        let mut content_height = use_state(|| 0.0f32);
        let mut viewport_height = use_state(|| 0.0f32);
        use_room_keys(
            scroll_controller,
            content_height,
            viewport_height,
            super::ui_ctx::use_room_ui_ctx().compose_focus,
        );
        let mut heights: State<HashMap<String, f32>> = use_state(HashMap::new);

        use_hook(|| {
            watch_focus_events(self.room_id.clone(), move |eid| {
                let offset = event_offset(&st.messages.peek(), &heights.peek(), &eid);
                if let Some(y) = offset {
                    scroll_controller.scroll_to_y(y as i32);
                }
            });
        });

        // Driven by scroll position so wheel, touch, scrollbar and keys all paginate.
        {
            let tl = tl.clone();
            use_side_effect(move || {
                let (_, y) = Into::<(i32, i32)>::into(scroll_controller);
                if y >= -LOAD_MORE_THRESHOLD_PX {
                    tl.request_page();
                }
            });
        }

        if *st.loading.read() {
            return rect()
                .width(Size::fill())
                .height(Size::flex(1.0))
                .center()
                .child(CircularLoader::new())
                .into_element();
        }

        // Content shorter than the viewport can't scroll, so fetch until it fills.
        let auto_fill = {
            let tl = tl.clone();
            move || {
                let (vp, content) = (*viewport_height.peek(), *content_height.peek());
                if *st.auto_fill.peek() && vp > 0.0 && content > 0.0 && content < vp {
                    tl.request_page();
                }
            }
        };
        let auto_fill_on_content = auto_fill.clone();

        let msgs = st.messages.read().clone();
        let room_name = st.room_name.read().clone();
        let is_dm = *st.is_dm.read();

        let header = if *st.at_start.read() {
            RoomStartBanner {
                room_id: self.room_id.clone(),
                room_name,
                c,
            }
            .into_element()
        } else {
            rect()
                .center()
                .width(Size::fill())
                .padding(Gaps::new_all(8.))
                .maybe_child(st.paginating.read().then(CircularLoader::new))
                .into_element()
        };

        let my_uid = my_user_id();
        let action_tx = tl.handle.actions();
        let date_labels: Vec<Option<String>> =
            (0..msgs.len()).map(|i| date_label_for(&msgs, i)).collect();
        let rows = msgs.into_iter().zip(date_labels).map(|(item, date_label)| {
            let key = row_key(&item);
            rect()
                .key(key.clone())
                .width(Size::fill())
                .on_sized(move |e: Event<SizedEventData>| {
                    let h = e.area.height();
                    if heights.peek().get(&key) != Some(&h) {
                        heights.write().insert(key.clone(), h);
                    }
                })
                .child(MessageRow {
                    room_id: self.room_id.clone(),
                    item,
                    date_label,
                    my_user_id: my_uid.clone(),
                    action_tx: action_tx.clone(),
                    is_dm,
                })
                .into_element()
        });

        let content = rect()
            .vertical()
            .width(Size::fill())
            .padding(Gaps::new(4., 0., 4., 0.))
            .child(header)
            .on_sized(move |e: Event<SizedEventData>| {
                scroll_to_pending_focus(st, heights, scroll_controller);
                let new_h = e.inner_sizes.height;
                // Any change, not just growth: a prepend can shrink the first row.
                if (new_h - *content_height.peek()).abs() > 0.5 {
                    content_height.set(new_h);
                }
                auto_fill_on_content();
            })
            .children(rows);

        rect()
            .width(Size::fill())
            .height(Size::flex(1.0))
            .on_sized(move |e: Event<SizedEventData>| {
                let vp_h = e.area.height();
                if (*viewport_height.peek() - vp_h).abs() > 0.5 {
                    viewport_height.set(vp_h);
                }
                auto_fill();
            })
            .child(
                ScrollView::new_controlled(scroll_controller)
                    .width(Size::fill())
                    .height(Size::fill())
                    .child(content),
            )
            .into_element()
    }
}

/// Scroll step for `j` / `k`.
const LINE_PX: f32 = 60.;

/// j/k, Ctrl-d/u, gg/G and `i`, while the room has keyboard focus.
fn use_room_keys(
    mut scroll: ScrollController,
    content_height: State<f32>,
    viewport_height: State<f32>,
    mut compose_focus: State<u64>,
) {
    use_key_commands(move |nav, command| {
        if *nav.area.peek() != Area::Room {
            return;
        }
        let viewport = *viewport_height.peek();
        // Positions are measured from the top: newest content is at -max.
        let max = (*content_height.peek() - viewport).max(0.);
        let (_, y) = Into::<(i32, i32)>::into(scroll);
        let by = |dy: f32| (y as f32 - dy).clamp(-max, 0.) as i32;
        match command {
            KeyCommand::Down => {
                scroll.scroll_to_y(by(LINE_PX));
            }
            KeyCommand::Up => {
                scroll.scroll_to_y(by(-LINE_PX));
            }
            KeyCommand::HalfPageDown => {
                scroll.scroll_to_y(by(viewport / 2.));
            }
            KeyCommand::HalfPageUp => {
                scroll.scroll_to_y(by(-viewport / 2.));
            }
            KeyCommand::Top => {
                scroll.scroll_to_y(0);
            }
            KeyCommand::Bottom => {
                scroll.scroll_to_y(-(max as i32));
            }
            KeyCommand::FocusComposer => *compose_focus.write() += 1,
            _ => {}
        }
    });
}

/// One-shot scroll to the focus event, after the first layout measured the rows.
fn scroll_to_pending_focus(
    st: super::use_room_timeline::TimelineState,
    heights: State<HashMap<String, f32>>,
    mut scroll_controller: ScrollController,
) {
    let mut pending_focus = st.pending_focus;
    let Some(eid) = pending_focus.peek().clone() else {
        return;
    };
    pending_focus.set(None);
    if let Some(y) = event_offset(&st.messages.peek(), &heights.peek(), &eid) {
        scroll_controller.scroll_to_y(y as i32);
    }
}

/// Date divider label when `items[idx]` starts a new day.
fn date_label_for(items: &[Arc<TimelineItem>], idx: usize) -> Option<String> {
    let curr = items[idx]
        .as_event()
        .map(|e| format_date_key(e.timestamp()))?;
    let prev = idx
        .checked_sub(1)
        .and_then(|i| items[i].as_event().map(|e| format_date_key(e.timestamp())));
    (prev.as_deref() != Some(curr.as_str())).then(|| format_date_label(&curr))
}
