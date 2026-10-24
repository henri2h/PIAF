use std::rc::Rc;
use std::sync::Arc;

use freya::prelude::*;

use super::media_thumb::MediaThumb;
use super::use_room_media::RoomMedia;
use super::{list_footer, use_auto_load};
use crate::utils::timeline_media::{MediaEntry, MediaKind};
use crate::utils::{format_date_label, use_app_colors};

const HEADER_H: f32 = 36.0;
const ROW_PAD: f32 = 2.0;
/// Rows rendered beyond the viewport, in pixels.
const OVERDRAW: f32 = 400.0;
const MIN_CELL: f32 = 140.0;

#[derive(Clone)]
pub(super) enum GridRow {
    DateHeader(String),
    Images(Vec<Arc<MediaEntry>>),
}

/// By identity: entries are immutable once extracted.
impl PartialEq for GridRow {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::DateHeader(a), Self::DateHeader(b)) => a == b,
            (Self::Images(a), Self::Images(b)) => {
                a.len() == b.len() && a.iter().zip(b).all(|(a, b)| Arc::ptr_eq(a, b))
            }
            _ => false,
        }
    }
}

pub(super) fn row_height(row: &GridRow, cell_size: f32) -> f32 {
    match row {
        GridRow::DateHeader(_) => HEADER_H,
        GridRow::Images(_) => cell_size + ROW_PAD,
    }
}

fn cell_size(width: f32, cols: usize) -> f32 {
    if width > 0. {
        ((width - 8.) / cols as f32 - 2.).clamp(60., 300.)
    } else {
        120.
    }
}

pub(super) fn cols_for_width(width: f32) -> usize {
    ((width / MIN_CELL).floor() as usize).max(3)
}

/// Images grouped by day under a date header, `cols` per row.
pub(super) fn build_rows(images: &[Arc<MediaEntry>], cols: usize) -> Vec<GridRow> {
    let mut rows = Vec::new();
    let mut day: Vec<Arc<MediaEntry>> = Vec::new();
    let flush = |rows: &mut Vec<GridRow>, day: &mut Vec<Arc<MediaEntry>>| {
        rows.extend(day.chunks(cols).map(|c| GridRow::Images(c.to_vec())));
        day.clear();
    };
    for entry in images {
        if day.first().is_none_or(|d| d.date_key != entry.date_key) {
            flush(&mut rows, &mut day);
            rows.push(GridRow::DateHeader(entry.date_key.clone()));
        }
        day.push(entry.clone());
    }
    flush(&mut rows, &mut day);
    rows
}

/// Image grid with its own scrolling, so a scroll only re-renders the grid.
#[derive(PartialEq)]
pub(super) struct MediaGrid {
    pub media: RoomMedia,
    pub selected_key: State<Option<String>>,
    /// Owned by the page so the position survives the viewer.
    pub scroll: ScrollController,
}

impl Component for MediaGrid {
    fn render(&self) -> impl IntoElement {
        let _timer = crate::logging::RenderTimer::new("MediaGrid");
        let c = use_app_colors();
        let media = self.media;
        let selected_key = self.selected_key;
        let scroll = self.scroll;
        let mut viewport = use_state(|| Size2D::new(0., 0.));

        let cols = use_memo(move || cols_for_width(viewport.read().width));
        let rows: Memo<Rc<Vec<GridRow>>> = use_memo(move || {
            let images: Vec<Arc<MediaEntry>> = media
                .entries
                .read()
                .iter()
                .filter(|e| e.kind() == MediaKind::Image)
                .cloned()
                .collect();
            Rc::new(build_rows(&images, *cols.read()))
        });
        use_auto_load(media, MediaKind::Image, scroll, viewport, move || {
            let cell = cell_size(viewport.read().width, *cols.read());
            rows.read().iter().map(|r| row_height(r, cell)).sum()
        });

        let width = viewport.read().width;
        let cols = *cols.read();
        let cell_size = cell_size(width, cols);
        let rows = rows.read().clone();

        // Visible window, from the scroll position (positions are negative).
        let (_, y) = Into::<(i32, i32)>::into(scroll);
        let top = (-y as f32 - OVERDRAW).max(0.);
        let bottom = -y as f32 + viewport.read().height + OVERDRAW;
        let mut offset = 0.;
        let (mut top_spacer, mut bottom_spacer) = (0., 0.);
        let mut visible = Vec::new();
        for row in rows.iter() {
            let h = row_height(row, cell_size);
            if offset + h <= top {
                top_spacer += h;
            } else if offset >= bottom {
                bottom_spacer += h;
            } else {
                visible.push(render_row(
                    row,
                    cell_size,
                    cols,
                    selected_key,
                    c.on_surface_muted,
                ));
            }
            offset += h;
        }

        rect()
            .expanded()
            .on_sized(move |e: Event<SizedEventData>| {
                viewport.set_if_modified(e.area.size);
            })
            .child(
                ScrollView::new_controlled(scroll)
                    .width(Size::fill())
                    .height(Size::fill())
                    .child(rect().width(Size::fill()).height(Size::px(top_spacer)))
                    .children(visible)
                    .child(rect().width(Size::fill()).height(Size::px(bottom_spacer)))
                    .child(list_footer(
                        c,
                        media,
                        MediaKind::Image,
                        rows.is_empty().then_some("No images"),
                    )),
            )
    }
}

fn render_row(
    row: &GridRow,
    cell_size: f32,
    cols: usize,
    selected_key: State<Option<String>>,
    header_color: (u8, u8, u8),
) -> Element {
    match row {
        GridRow::DateHeader(date_key) => rect()
            .key(format!("header-{date_key}"))
            .width(Size::fill())
            .height(Size::px(HEADER_H))
            .padding(Gaps::new(8., 12., 4., 12.))
            .child(
                label()
                    .text(format_date_label(date_key))
                    .font_size(13.)
                    .font_weight(FontWeight::MEDIUM)
                    .color(header_color),
            )
            .into_element(),
        GridRow::Images(cells) => {
            let row_key = cells.first().map(|e| e.key.as_str()).unwrap_or_default();
            rect()
                .key(format!("row-{row_key}"))
                .horizontal()
                .width(Size::fill())
                .height(Size::px(cell_size + ROW_PAD))
                .content(Content::Flex)
                .spacing(2.)
                .padding(Gaps::new(1., 4., 1., 4.))
                .children(cells.iter().map(|entry| {
                    // Keyed wrapper: components can't take keys themselves.
                    rect()
                        .key(&entry.key)
                        .width(Size::flex(1.))
                        .child(MediaThumb {
                            entry: entry.clone(),
                            cell_size,
                            selected_key,
                        })
                        .into_element()
                }))
                .children((cells.len()..cols).map(|_| rect().width(Size::flex(1.)).into_element()))
                .into_element()
        }
    }
}

#[cfg(test)]
mod tests {
    use matrix_sdk::ruma::{OwnedMxcUri, events::room::MediaSource};

    use super::*;
    use crate::utils::timeline_media::MediaContent;

    fn image(key: &str, date_key: &str) -> Arc<MediaEntry> {
        Arc::new(MediaEntry {
            key: key.to_string(),
            event_id: Some(key.to_string()),
            sender_name: "Alice".to_string(),
            timestamp: "10:00".to_string(),
            date_key: date_key.to_string(),
            content: MediaContent::Image {
                source: MediaSource::Plain(
                    OwnedMxcUri::try_from("mxc://example.org/test").unwrap(),
                ),
                caption: None,
                blurhash: None,
                thumbnail_source: None,
            },
        })
    }

    fn sizes(rows: &[GridRow]) -> Vec<Option<usize>> {
        rows.iter()
            .map(|r| match r {
                GridRow::DateHeader(_) => None,
                GridRow::Images(c) => Some(c.len()),
            })
            .collect()
    }

    #[test]
    fn cols_have_a_minimum_and_scale_with_width() {
        assert_eq!(cols_for_width(0.0), 3);
        assert_eq!(cols_for_width(419.9), 3);
        assert_eq!(cols_for_width(560.0), 4);
        assert_eq!(cols_for_width(700.0), 5);
    }

    #[test]
    fn row_heights() {
        assert_eq!(
            row_height(&GridRow::DateHeader("d".into()), 100.0),
            HEADER_H
        );
        assert_eq!(row_height(&GridRow::Images(vec![]), 100.0), 100.0 + ROW_PAD);
    }

    #[test]
    fn empty_input_has_no_rows() {
        assert!(build_rows(&[], 3).is_empty());
    }

    #[test]
    fn overflow_splits_rows() {
        let items: Vec<_> = (1..=4).map(|i| image(&format!("e{i}"), "d1")).collect();
        assert_eq!(sizes(&build_rows(&items, 3)), vec![None, Some(3), Some(1)]);
    }

    #[test]
    fn each_day_gets_a_header_and_flushes_its_partial_row() {
        let items = vec![image("a", "d2"), image("b", "d2"), image("c", "d1")];
        let rows = build_rows(&items, 3);
        assert_eq!(sizes(&rows), vec![None, Some(2), None, Some(1)]);
        assert!(matches!(&rows[0], GridRow::DateHeader(d) if d == "d2"));
        assert!(matches!(&rows[2], GridRow::DateHeader(d) if d == "d1"));
    }

    #[test]
    fn order_is_preserved_within_a_row() {
        let rows = build_rows(&[image("first", "d"), image("second", "d")], 3);
        let GridRow::Images(cells) = &rows[1] else {
            panic!("expected Images row");
        };
        assert_eq!(cells[0].key, "first");
        assert_eq!(cells[1].key, "second");
    }
}
