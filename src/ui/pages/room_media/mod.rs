use std::sync::Arc;

use freya::prelude::*;
use freya_router::prelude::RouterContext;
use futures::StreamExt;
use matrix_sdk::ruma::RoomId;
use matrix_sdk::ruma::events::room::{MediaSource, message::MessageType};
use matrix_sdk_ui::timeline::{RoomExt, TimelineDetails, TimelineItemContent};

use tokio::sync::mpsc::unbounded_channel;

use crate::ui::components::{
    MediaViewer, MediaViewerItem, TopAppBar, TopAppBarTitle, ViewerSource,
};
use crate::utils::{format_date_key, format_date_label, format_timestamp, matrix::CLIENT};

mod media_thumb;
use media_thumb::MediaThumb;

const HEADER_H: f32 = 36.0;
const ROW_PAD: f32 = 2.0;
const OVERDRAW: f32 = 400.0;

#[derive(Clone)]
pub(super) struct MediaItem {
    pub key: String,
    pub source: MediaSource,
    pub sender_name: String,
    pub timestamp: String,
    pub date_key: String,
    pub blurhash: Option<String>,
    pub thumbnail_source: Option<MediaSource>,
}

impl PartialEq for MediaItem {
    fn eq(&self, other: &Self) -> bool {
        self.key == other.key
    }
}

#[derive(Clone)]
pub(super) enum GridRow {
    DateHeader(String),
    Images(Vec<MediaItem>),
}

pub(super) fn row_height(row: &GridRow, cell_size: f32) -> f32 {
    match row {
        GridRow::DateHeader(_) => HEADER_H,
        GridRow::Images(_) => cell_size + ROW_PAD,
    }
}

pub(super) fn cols_for_width(width: f32) -> usize {
    ((width / 140.).floor() as usize).max(3)
}

pub(super) fn build_rows(display_items: &[MediaItem], cols: usize) -> Vec<GridRow> {
    let mut rows: Vec<GridRow> = Vec::new();
    let mut group_date = String::new();
    let mut group_buf: Vec<MediaItem> = Vec::new();

    let flush = |rows: &mut Vec<GridRow>, group_buf: &mut Vec<MediaItem>| {
        for chunk in group_buf.chunks(cols) {
            rows.push(GridRow::Images(chunk.to_vec()));
        }
        group_buf.clear();
    };

    for item in display_items.iter() {
        if item.date_key != group_date {
            flush(&mut rows, &mut group_buf);
            group_date = item.date_key.clone();
            rows.push(GridRow::DateHeader(item.date_key.clone()));
        }
        group_buf.push(item.clone());
    }
    flush(&mut rows, &mut group_buf);
    rows
}

pub(super) fn render_row(
    row: &GridRow,
    cell_size: f32,
    cols: usize,
    selected_key: State<Option<String>>,
) -> Element {
    match row {
        GridRow::DateHeader(date_key) => {
            let label_text = format_date_label(date_key);
            rect()
                .key(format!("header-{}", date_key))
                .width(Size::fill())
                .height(Size::px(HEADER_H))
                .padding(Gaps::new(8., 12., 4., 12.))
                .cross_align(Alignment::Center)
                .child(
                    label()
                        .text(label_text)
                        .font_size(13.)
                        .font_weight(FontWeight::MEDIUM)
                        .color((120u8, 120u8, 120u8)),
                )
                .into_element()
        }
        GridRow::Images(cells) => {
            let row_key = cells
                .first()
                .map(|item| format!("row-{}", item.key))
                .unwrap_or_else(|| "row-empty".to_string());
            let mut row_el = rect()
                .key(row_key)
                .horizontal()
                .width(Size::fill())
                .content(Content::Flex)
                .height(Size::px(cell_size + ROW_PAD))
                .spacing(2.)
                .padding(Gaps::new(1., 4., 1., 4.));

            for item in cells {
                row_el = row_el.child(MediaThumb {
                    item_key: item.key.clone(),
                    source: item.source.clone(),
                    blurhash: item.blurhash.clone(),
                    thumbnail_source: item.thumbnail_source.clone(),
                    cell_size,
                    selected_key,
                });
            }

            for _ in cells.len()..cols {
                row_el = row_el.child(rect().width(Size::flex(1.0)));
            }

            row_el.into_element()
        }
    }
}

pub(super) fn extract_media_meta(
    item: &std::sync::Arc<matrix_sdk_ui::timeline::TimelineItem>,
) -> Option<MediaItem> {
    let event = item.as_event()?;
    let message = match event.content() {
        TimelineItemContent::MsgLike(msg) => msg.as_message()?,
        _ => return None,
    };
    let img = match message.msgtype() {
        MessageType::Image(img) => img,
        _ => return None,
    };

    let key = event
        .event_id()
        .map(|id| id.to_string())
        .unwrap_or_else(|| format!("img-{}", u64::from(event.timestamp().get())));

    let sender = event.sender().to_string();
    let sender_name = match event.sender_profile() {
        TimelineDetails::Ready(profile) => profile
            .display_name
            .clone()
            .unwrap_or_else(|| sender.clone()),
        _ => sender,
    };
    let timestamp = event.timestamp();

    let blurhash = img.info.as_ref().and_then(|i| i.blurhash.clone());
    let thumbnail_source = img.info.as_ref().and_then(|i| i.thumbnail_source.clone());

    Some(MediaItem {
        key,
        source: img.source.clone(),
        sender_name,
        timestamp: format_timestamp(timestamp),
        date_key: format_date_key(timestamp),
        blurhash,
        thumbnail_source,
    })
}

#[derive(Clone, PartialEq)]
pub struct RoomMediaPage {
    pub room_id: String,
}

impl Component for RoomMediaPage {
    fn render(&self) -> impl IntoElement {
        let c = crate::utils::use_app_colors();
        let room_id = self.room_id.clone();

        let mut items: State<Vec<MediaItem>> = use_state(|| vec![]);
        let mut loading: State<bool> = use_state(|| true);
        let mut paginating: State<bool> = use_state(|| false);
        let mut auto_fill: State<bool> = use_state(|| false);
        let mut viewport_height: State<f32> = use_state(|| 0.0f32);
        let mut container_width: State<f32> = use_state(|| 0.0f32);
        let selected_key: State<Option<String>> = use_state(|| None);

        let scroll_controller = use_scroll_controller(|| ScrollConfig {
            default_vertical_position: ScrollPosition::Start,
            ..Default::default()
        });

        let request_fetch_history = use_hook(|| {
            let room_id = room_id.clone();

            let (request_history_tx, mut request_history_rx) = unbounded_channel::<()>();
            let (update_tx, mut update_rx) =
                futures::channel::mpsc::unbounded::<(Vec<MediaItem>, bool)>();

            let page_tx_auto = request_history_tx.clone();

            let (init_tx, init_rx) = futures::channel::oneshot::channel::<Vec<MediaItem>>();

            if let Some(client) = CLIENT.get().cloned() {
                let room_id2 = room_id.clone();
                let update_tx2 = update_tx.clone();
                tokio::task::spawn(async move {
                    let Ok(parsed_id) = RoomId::parse(&room_id2) else {
                        return;
                    };
                    let Some(room) = client.get_room(&parsed_id) else {
                        let _ = init_tx.send(vec![]);
                        return;
                    };

                    let Ok(timeline) = room.timeline_builder().build().await else {
                        let _ = init_tx.send(vec![]);
                        return;
                    };

                    let timeline = std::sync::Arc::new(timeline);
                    let (initial_items, _stream) = timeline.subscribe().await;

                    let mut media_items: Vec<MediaItem> = initial_items
                        .iter()
                        .filter_map(extract_media_meta)
                        .collect();

                    let mut known_count = media_items.len();
                    let _ = init_tx.send(media_items.clone());

                    loop {
                        let Some(()) = request_history_rx.recv().await else {
                            break;
                        };

                        let mut pages = 0u32;
                        let has_hit_end = loop {
                            let hit = timeline.paginate_backwards(40).await.unwrap_or(true);
                            pages += 1;
                            media_items = timeline
                                .items()
                                .await
                                .iter()
                                .filter_map(extract_media_meta)
                                .collect();

                            let found_new = media_items.len() > known_count;
                            known_count = media_items.len();
                            if found_new || hit || pages >= 10 {
                                // If we exhausted 10 pages without finding any images, treat
                                // this as a soft end so the scroll effect doesn't immediately
                                // re-trigger another batch. The "Load older media" button lets
                                // the user explicitly continue searching.
                                break hit || (!found_new && pages >= 10);
                            }
                        };
                        let _ = update_tx2.unbounded_send((media_items.clone(), has_hit_end));
                    }
                });
            }

            spawn(async move {
                if let Ok(initial) = init_rx.await {
                    *items.write() = initial;
                }
                *loading.write() = false;
                *auto_fill.write() = true;
                *paginating.write() = true;
                let _ = page_tx_auto.send(());

                while let Some((new_items, has_hit_end)) = update_rx.next().await {
                    *items.write() = new_items;
                    if has_hit_end {
                        *auto_fill.write() = false;
                    }
                    *paginating.write() = false;
                }
            });

            request_history_tx
        });

        let (_, scroll_y_raw) = scroll_controller.into();
        let scroll_offset = (-scroll_y_raw as f32).max(0.0);

        let display_items: Vec<MediaItem> = items.read().iter().rev().cloned().collect();

        let vp_h = *viewport_height.read();
        let cw = *container_width.read();
        let cols = cols_for_width(cw);
        let cell_size = if cw > 0.0 {
            ((cw - 8.) / cols as f32 - 2.).max(60.).min(300.)
        } else {
            120.
        };

        let rows = build_rows(&display_items, cols);
        let mut offsets = Vec::with_capacity(rows.len());
        let mut cum = 0.0f32;
        for row in &rows {
            offsets.push(cum);
            cum += row_height(row, cell_size);
        }
        let total_rows_h = cum;

        let request_history_scroll = request_fetch_history.clone();
        use_side_effect(move || {
            let (_, sy) = scroll_controller.into();
            let so = (-sy as f32).max(0.0);
            let vp = *viewport_height.read();
            let _ = items.read();

            if !*auto_fill.read() || *paginating.read() || vp <= 0.0 {
                return;
            }
            let near_bottom = if total_rows_h > vp {
                so + vp >= total_rows_h - OVERDRAW
            } else {
                true
            };
            if near_bottom {
                *paginating.write() = true;
                let _ = request_history_scroll.send(());
            }
        });

        let fetch_history_tx_btn = request_fetch_history.clone();

        let is_loading = *loading.read();
        let is_paging = *paginating.read();
        let should_fill = *auto_fill.read();
        let selected = selected_key.read().clone();
        let room_id_back = room_id.clone();

        let vis_top = (scroll_offset - OVERDRAW).max(0.0);
        let vis_bot = scroll_offset + vp_h + OVERDRAW;

        let mut first_vis: Option<usize> = None;
        let mut last_vis: Option<usize> = None;
        for (i, &offset) in offsets.iter().enumerate() {
            let rh = row_height(&rows[i], cell_size);
            if offset + rh > vis_top && offset < vis_bot {
                if first_vis.is_none() {
                    first_vis = Some(i);
                }
                last_vis = Some(i);
            }
        }

        let top_spacer_h = first_vis.map(|i| offsets[i]).unwrap_or(0.0);
        let bottom_spacer_h = match last_vis {
            Some(i) => (total_rows_h - offsets[i] - row_height(&rows[i], cell_size)).max(0.0),
            None => total_rows_h,
        };

        let vis_rows: Vec<Element> = match (first_vis, last_vis) {
            (Some(f), Some(l)) => rows[f..=l]
                .iter()
                .map(|row| render_row(row, cell_size, cols, selected_key))
                .collect(),
            _ => vec![],
        };

        let viewer_items: Vec<MediaViewerItem> = display_items
            .iter()
            .map(|item| MediaViewerItem {
                key: item.key.clone(),
                source: ViewerSource::Remote(item.source.clone()),
                info: Some((item.sender_name.clone(), item.timestamp.clone())),
                caption: None,
                blurhash: item.blurhash.clone(),
                thumbnail_source: item
                    .thumbnail_source
                    .as_ref()
                    .map(|s| ViewerSource::Remote(s.clone())),
            })
            .collect();

        // Pass load-more to the viewer only while more history exists.
        // The viewer is shown in place of the grid, so there is no visible
        // paginating indicator to update — just trigger the background request.
        let fetch_for_viewer = request_fetch_history.clone();
        let on_load_more_viewer: Option<std::rc::Rc<dyn Fn()>> = if should_fill {
            Some(std::rc::Rc::new(move || {
                let _ = fetch_for_viewer.send(());
            }))
        } else {
            None
        };

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(if selected.is_none() {
                TopAppBar {
                    title: TopAppBarTitle::Text("Media".to_string()),
                    on_back: Some(Arc::new(move || {
                        let _ = RouterContext::get().push(crate::Route::RoomSettings {
                            room_id: room_id_back.clone(),
                        });
                    })),
                    actions: vec![],
                }
                .into_element()
            } else {
                rect().height(Size::px(0.)).into_element()
            })
            .child(if selected.is_some() {
                MediaViewer {
                    items: viewer_items,
                    selected_key,
                    on_load_more: on_load_more_viewer,
                }
                .into_element()
            } else if is_loading {
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .center()
                    .child(CircularLoader::new())
                    .into_element()
            } else {
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.0))
                    .on_sized(move |e: Event<SizedEventData>| {
                        *viewport_height.write() = e.area.height();
                        *container_width.write() = e.area.width();
                    })
                    .child(
                        ScrollView::new_controlled(scroll_controller)
                            .width(Size::fill())
                            .height(Size::fill())
                            .child(
                                rect()
                                    .vertical()
                                    .width(Size::fill())
                                    .child(
                                        rect().width(Size::fill()).height(Size::px(top_spacer_h)),
                                    )
                                    .children(vis_rows.into_iter())
                                    .child(
                                        rect()
                                            .width(Size::fill())
                                            .height(Size::px(bottom_spacer_h)),
                                    )
                                    .child(
                                        rect()
                                            .center()
                                            .width(Size::fill())
                                            .padding(Gaps::new_all(8.))
                                            .child(if is_paging || should_fill {
                                                CircularLoader::new().into_element()
                                            } else {
                                                Button::new()
                                                    .on_press(move |_| {
                                                        *paginating.write() = true;
                                                        let _ = fetch_history_tx_btn.send(());
                                                    })
                                                    .child("Load older media")
                                                    .into_element()
                                            }),
                                    ),
                            ),
                    )
                    .into_element()
            })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use matrix_sdk::ruma::OwnedMxcUri;

    fn item(key: &str, date_key: &str) -> MediaItem {
        MediaItem {
            key: key.to_string(),
            source: MediaSource::Plain(OwnedMxcUri::try_from("mxc://example.org/test").unwrap()),
            sender_name: "Alice".to_string(),
            timestamp: "10:00".to_string(),
            date_key: date_key.to_string(),
            blurhash: None,
            thumbnail_source: None,
        }
    }

    // ── cols_for_width ────────────────────────────────────────────────────────

    #[test]
    fn cols_minimum_three_for_narrow_widths() {
        assert_eq!(cols_for_width(0.0), 3);
        assert_eq!(cols_for_width(1.0), 3);
        // 419 / 140 = 2.99 → floor = 2 → max(3) = 3
        assert_eq!(cols_for_width(419.9), 3);
    }

    #[test]
    fn cols_scales_with_width() {
        assert_eq!(cols_for_width(420.0), 3); // 420/140 = 3 exactly
        assert_eq!(cols_for_width(560.0), 4); // 560/140 = 4
        assert_eq!(cols_for_width(700.0), 5); // 700/140 = 5
    }

    // ── row_height ────────────────────────────────────────────────────────────

    #[test]
    fn row_height_date_header_is_constant() {
        assert_eq!(
            row_height(&GridRow::DateHeader("2024-01-01".to_string()), 100.0),
            HEADER_H,
        );
        // cell_size is irrelevant for date headers
        assert_eq!(
            row_height(&GridRow::DateHeader("2024-01-01".to_string()), 0.0),
            HEADER_H,
        );
    }

    #[test]
    fn row_height_images_is_cell_plus_padding() {
        assert_eq!(row_height(&GridRow::Images(vec![]), 100.0), 100.0 + ROW_PAD);
        assert_eq!(row_height(&GridRow::Images(vec![]), 60.0), 60.0 + ROW_PAD);
    }

    // ── build_rows ────────────────────────────────────────────────────────────

    #[test]
    fn build_rows_empty_input() {
        assert!(build_rows(&[], 3).is_empty());
    }

    #[test]
    fn build_rows_single_full_row() {
        let items = vec![
            item("e1", "2024-01-01"),
            item("e2", "2024-01-01"),
            item("e3", "2024-01-01"),
        ];
        let rows = build_rows(&items, 3);
        assert_eq!(rows.len(), 2); // [DateHeader, Images(3)]
        assert!(matches!(&rows[0], GridRow::DateHeader(d) if d == "2024-01-01"));
        assert!(matches!(&rows[1], GridRow::Images(c) if c.len() == 3));
    }

    #[test]
    fn build_rows_overflow_splits_into_two_rows() {
        let items: Vec<_> = (1..=4)
            .map(|i| item(&format!("e{i}"), "2024-01-01"))
            .collect();
        let rows = build_rows(&items, 3);
        // [DateHeader, Images([e1,e2,e3]), Images([e4])]
        assert_eq!(rows.len(), 3);
        assert!(matches!(&rows[1], GridRow::Images(c) if c.len() == 3));
        assert!(matches!(&rows[2], GridRow::Images(c) if c.len() == 1));
    }

    #[test]
    fn build_rows_two_dates_have_separate_headers() {
        let items = vec![
            item("e1", "2024-01-02"),
            item("e2", "2024-01-02"),
            item("e3", "2024-01-01"),
        ];
        let rows = build_rows(&items, 3);
        // [Header("2024-01-02"), Images([e1,e2]), Header("2024-01-01"), Images([e3])]
        assert_eq!(rows.len(), 4);
        assert!(matches!(&rows[0], GridRow::DateHeader(d) if d == "2024-01-02"));
        assert!(matches!(&rows[2], GridRow::DateHeader(d) if d == "2024-01-01"));
    }

    #[test]
    fn build_rows_preserves_key_order_within_row() {
        let items = vec![item("first", "2024-01-01"), item("second", "2024-01-01")];
        let rows = build_rows(&items, 3);
        let GridRow::Images(cells) = &rows[1] else {
            panic!("expected Images row");
        };
        assert_eq!(cells[0].key, "first");
        assert_eq!(cells[1].key, "second");
    }

    #[test]
    fn build_rows_date_boundary_flushes_partial_row() {
        // 2 items on day 1, then 1 item on day 2 — the partial row from day 1
        // must be flushed before the day 2 header appears.
        let items = vec![
            item("a", "2024-01-01"),
            item("b", "2024-01-01"),
            item("c", "2024-01-02"),
        ];
        let rows = build_rows(&items, 3);
        // [Header(day1), Images([a,b]), Header(day2), Images([c])]
        assert_eq!(rows.len(), 4);
        assert!(matches!(&rows[1], GridRow::Images(c) if c.len() == 2));
        assert!(matches!(&rows[3], GridRow::Images(c) if c.len() == 1));
    }
}
