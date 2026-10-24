use std::cell::Cell;
use std::collections::HashMap;
use std::rc::Rc;
use std::sync::Arc;
use std::sync::atomic::Ordering;
use std::time::Duration;

use freya::prelude::*;
use matrix_sdk_ui::timeline::{MsgLikeKind, TimelineItem, TimelineItemContent};

use super::focus::{event_offset, row_key, watch_focus_events};
use super::jump_to_latest::{JumpToLatest, distance_to_end};
use super::message_row::{GroupPosition, MessageRow};
use super::room_start_banner::RoomStartBanner;
use super::use_room_timeline::RoomTimeline;
use crate::app::keys::{Area, KeyCommand, use_key_commands};
use crate::logging::RenderTimer;
use crate::utils::matrix::my_user_id;
use crate::utils::{format_date_key, format_date_label, use_app_colors};

/// Load older messages once scrolled within this distance of the top.
const LOAD_MORE_THRESHOLD_PX: i32 = 400;
/// Within this distance of the end, the latest message counts as seen.
const AT_END_PX: f32 = 32.;
/// A message scrolled to (search, reply) is highlighted this long.
const FLASH: Duration = Duration::from_millis(1500);
/// Space kept above a message scrolled to.
const FOCUS_MARGIN: f32 = 80.;

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
        let scroll_controller = self.scroll_controller;

        let mut content_height = use_state(|| 0.0f32);
        let mut viewport_height = use_state(|| 0.0f32);
        use_room_keys(
            scroll_controller,
            content_height,
            viewport_height,
            super::ui_ctx::use_room_ui_ctx().compose_focus,
        );
        let heights: State<HashMap<String, f32>> = use_state(HashMap::new);
        // Row briefly highlighted after scrolling to it.
        let flash: State<Option<String>> = use_state(|| None);

        // A message to show (a tapped reply, a search result in this room):
        // scrolled to now, or once history loaded up to it.
        {
            let tl = tl.clone();
            use_hook(|| {
                watch_focus_events(self.room_id.clone(), move |eid| {
                    let mut pending_focus = st.pending_focus;
                    pending_focus.set(Some(eid));
                    scroll_to_pending_focus(&tl, heights, flash, scroll_controller);
                });
            });
        }

        // At the latest message, on screen: read receipt (not for a timeline
        // around a searched event, which isn't the room's end).
        {
            let tl = tl.clone();
            let marked = use_hook(|| Rc::new(Cell::new(0usize)));
            use_side_effect(move || {
                let len = st.messages.read().len();
                let distance = distance_to_end(
                    scroll_controller,
                    *content_height.read(),
                    *viewport_height.read(),
                );
                let visible = crate::APP_FOCUSED.load(Ordering::Relaxed);
                if tl.live && visible && len > 0 && distance < AT_END_PX && marked.get() != len {
                    marked.set(len);
                    tl.handle.mark_read();
                }
            });
        }

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

        let flashed = flash.read().clone();
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
        let groups = group_positions(
            &msgs.iter().map(|item| group_key(item)).collect::<Vec<_>>(),
            &date_labels.iter().map(Option::is_some).collect::<Vec<_>>(),
        );
        let rows =
            msgs.into_iter()
                .zip(date_labels)
                .zip(groups)
                .map(|((item, date_label), group)| {
                    let key = row_key(&item);
                    let highlighted = flashed.as_ref() == Some(&key);
                    let mut heights = heights;
                    rect()
                        .key(key.clone())
                        .width(Size::fill())
                        .maybe(highlighted, |r| r.background(c.primary_container))
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
                            group,
                            my_user_id: my_uid.clone(),
                            action_tx: action_tx.clone(),
                            is_dm,
                        })
                        .into_element()
                });

        let tl_focus = tl.clone();
        let content = rect()
            .vertical()
            .width(Size::fill())
            .padding(Gaps::new(4., 0., 4., 0.))
            .child(header)
            .on_sized(move |e: Event<SizedEventData>| {
                scroll_to_pending_focus(&tl_focus, heights, flash, scroll_controller);
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
            .child(JumpToLatest {
                scroll: scroll_controller,
                content_height,
                viewport_height,
                messages: st.messages,
                my_user_id: my_user_id(),
            })
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
            KeyCommand::Bottom => scroll.scroll_to(ScrollPosition::End, Direction::Vertical),
            KeyCommand::FocusComposer => *compose_focus.write() += 1,
            _ => {}
        }
    });
}

/// Scrolls to the pending focus event once its row is measured, and
/// highlights it; loads older pages until it is found or the room starts.
fn scroll_to_pending_focus(
    tl: &RoomTimeline,
    heights: State<HashMap<String, f32>>,
    mut flash: State<Option<String>>,
    mut scroll_controller: ScrollController,
) {
    let st = tl.state;
    let mut pending_focus = st.pending_focus;
    let Some(eid) = pending_focus.peek().clone() else {
        return;
    };
    match event_offset(&st.messages.peek(), &heights.peek(), &eid) {
        Some(y) => {
            pending_focus.set(None);
            scroll_controller.scroll_to_y(-((y - FOCUS_MARGIN).max(0.) as i32));
            flash.set(Some(eid.clone()));
            spawn(async move {
                timer(FLASH).await;
                if flash.peek().as_ref() == Some(&eid) {
                    flash.set(None);
                }
            });
        }
        None if *st.at_start.peek() => pending_focus.set(None),
        None => tl.request_page(),
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

/// Messages this close in time from one sender join a group.
const GROUP_GAP_MS: u64 = 5 * 60 * 1000;

/// `(sender, timestamp ms)` of a message that can join a group; `None` for
/// anything else (notices, read marker…), which breaks groups.
fn group_key(item: &TimelineItem) -> Option<(String, u64)> {
    let event = item.as_event()?;
    let TimelineItemContent::MsgLike(msg_like) = event.content() else {
        return None;
    };
    // The kinds shown as bubbles.
    if !matches!(
        msg_like.kind,
        MsgLikeKind::Message(_) | MsgLikeKind::Redacted | MsgLikeKind::UnableToDecrypt(_)
    ) {
        return None;
    }
    Some((event.sender().to_string(), event.timestamp().0.into()))
}

/// Each item's place in its run of consecutive messages from one sender:
/// same sender, at most [`GROUP_GAP_MS`] apart, not across a day divider
/// (`new_day[i]`: item `i` starts a new day).
fn group_positions(keys: &[Option<(String, u64)>], new_day: &[bool]) -> Vec<GroupPosition> {
    let joins = |i: usize| -> bool {
        // Whether item `i` continues the group of item `i - 1`.
        if i == 0 || new_day[i] {
            return false;
        }
        match (&keys[i - 1], &keys[i]) {
            (Some((prev_sender, prev_ts)), Some((sender, ts))) => {
                prev_sender == sender && ts.saturating_sub(*prev_ts) <= GROUP_GAP_MS
            }
            _ => false,
        }
    };
    (0..keys.len())
        .map(|i| GroupPosition {
            first: !joins(i),
            last: i + 1 >= keys.len() || !joins(i + 1),
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn msg(sender: &str, minute: u64) -> Option<(String, u64)> {
        Some((sender.to_string(), minute * 60 * 1000))
    }

    fn positions(keys: &[Option<(String, u64)>]) -> Vec<(bool, bool)> {
        group_positions(keys, &vec![false; keys.len()])
            .into_iter()
            .map(|g| (g.first, g.last))
            .collect()
    }

    #[test]
    fn consecutive_messages_from_one_sender_group() {
        let keys = [msg("a", 0), msg("a", 1), msg("a", 2), msg("b", 3)];
        assert_eq!(
            positions(&keys),
            [(true, false), (false, false), (false, true), (true, true)]
        );
    }

    #[test]
    fn a_long_pause_or_a_notice_breaks_the_group() {
        let keys = [msg("a", 0), msg("a", 10), None, msg("a", 11)];
        assert_eq!(
            positions(&keys),
            [(true, true), (true, true), (true, true), (true, true)]
        );
    }

    #[test]
    fn a_new_day_breaks_the_group() {
        let keys = [msg("a", 0), msg("a", 1)];
        let groups = group_positions(&keys, &[false, true]);
        assert!(groups[0].last && groups[1].first);
    }
}
