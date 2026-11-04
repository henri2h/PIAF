use freya::prelude::*;

use crate::ui::components::IconButton;

use super::use_room_media::RoomMedia;
use super::{list_footer, use_auto_load};
use crate::ui::components::HoverableExt;
use crate::utils::const_values::AppColors;
use crate::utils::timeline_media::{FileKind, MediaContent, MediaEntry, MediaKind, SharedEntries};
use crate::utils::{format_date_label, use_app_colors};

const ROW_H: f32 = 60.;

/// Files or links, newest first. Files download on press, links open.
#[derive(PartialEq)]
pub(super) struct EntryList {
    pub media: RoomMedia,
    pub kind: MediaKind,
    pub room_id: String,
}

impl Component for EntryList {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let media = self.media;
        let kind = self.kind;
        let scroll = use_scroll_controller(ScrollConfig::default);
        let mut viewport = use_state(|| Size2D::new(0., 0.));

        let entries: Memo<SharedEntries> = use_memo(move || {
            media
                .entries
                .read()
                .iter()
                .filter(|e| e.kind() == kind)
                .cloned()
                .collect()
        });
        use_auto_load(media, kind, scroll, viewport, move || {
            entries.read().len() as f32 * ROW_H
        });

        let entries = entries.read().clone();
        let len = entries.len();
        let room_id = self.room_id.clone();

        rect()
            .expanded()
            .on_sized(move |e: Event<SizedEventData>| {
                viewport.set_if_modified(e.area.size);
            })
            .child(if len == 0 {
                let empty = match kind {
                    MediaKind::Link => "No links",
                    _ => "No files",
                };
                rect()
                    .expanded()
                    .center()
                    .child(list_footer(c, media, kind, Some(empty)))
                    .into_element()
            } else {
                // One extra item for the footer (loader / load older).
                VirtualScrollView::new_with_data_controlled(
                    (entries.clone(), room_id),
                    move |item, (entries, room_id)| match entries.get(item.index) {
                        Some(entry) => rect()
                            .key(&entry.key)
                            .width(Size::fill())
                            .child(entry_row(entry, room_id, c))
                            .into_element(),
                        None => list_footer(c, media, kind, None),
                    },
                    scroll,
                )
                .length(len + 1)
                .item_size(ROW_H)
                .height(Size::fill())
                .into_element()
            })
    }
}

fn entry_row(entry: &MediaEntry, room_id: &str, c: AppColors) -> Element {
    let (icon, title, detail, on_press): (_, _, _, Box<dyn Fn()>) = match &entry.content {
        MediaContent::File {
            kind,
            source,
            name,
            size,
        } => {
            let icon = match kind {
                FileKind::File => freya_icons::lucide::file(),
                FileKind::Video => freya_icons::lucide::film(),
                FileKind::Audio => freya_icons::lucide::music(),
            };
            let source = source.clone();
            (
                icon,
                name.clone(),
                size.map(crate::utils::media::format_file_size),
                Box::new(move || crate::utils::media::download(&source)),
            )
        }
        MediaContent::Link { url } => {
            let open = url.clone();
            (
                freya_icons::lucide::link(),
                url.clone(),
                None,
                Box::new(move || Platform::get().open_url(open.clone())),
            )
        }
        MediaContent::Image { .. } => return rect().into_element(),
    };
    let subtitle = [
        Some(entry.sender_name.clone()),
        Some(format!(
            "{} {}",
            format_date_label(&entry.date_key),
            entry.timestamp
        )),
        detail,
    ]
    .into_iter()
    .flatten()
    .collect::<Vec<_>>()
    .join(" · ");

    let show_in_chat = entry.event_id.clone().map(|event_id| {
        let room_id = room_id.to_string();
        IconButton::new(
            freya_icons::lucide::message_square(),
            c.on_surface_variant,
            move |_| {
                crate::app::navigation::navigate_to_room_at_event(room_id.clone(), event_id.clone())
            },
        )
        .tooltip("Show in chat")
        .size(36., 18.)
    });

    rect()
        .horizontal()
        .width(Size::fill())
        .height(Size::px(ROW_H))
        .content(Content::Flex)
        .cross_align(Alignment::Center)
        .padding(Gaps::new(0., 8., 0., 16.))
        .spacing(12.)
        .on_press(move |_| on_press())
        .child(
            rect()
                .center()
                .width(Size::px(36.))
                .height(Size::px(36.))
                .corner_radius(8.)
                .background(c.surface_container)
                .child(
                    SvgViewer::new(icon)
                        .color(c.primary)
                        .width(Size::px(18.))
                        .height(Size::px(18.)),
                ),
        )
        .child(
            rect()
                .vertical()
                .width(Size::flex(1.))
                .spacing(2.)
                .child(
                    label()
                        .text(title)
                        .font_size(14.)
                        .color(c.on_surface)
                        .max_lines(1)
                        .text_overflow(TextOverflow::Ellipsis),
                )
                .child(
                    label()
                        .text(subtitle)
                        .font_size(12.)
                        .color(c.on_surface_muted)
                        .max_lines(1)
                        .text_overflow(TextOverflow::Ellipsis),
                ),
        )
        .maybe_child(show_in_chat)
        .hoverable(Size::fill(), Size::px(ROW_H), 0.)
}
