use freya::prelude::*;
use freya_material_design::prelude::Ripple;

use crate::BOOKMARKS_RX;
use crate::utils::bookmarks::{BookmarkEntry, add_entry, create_list, mutate_bookmarks};
use crate::utils::const_values::AppColors;
use crate::utils::use_app_colors;

/// Popup shown after pressing "Bookmark" on a message: lets the user pick
/// which list to add the message to, or create a new one on the fly.
pub(super) struct BookmarkPickerOverlay {
    pub pending: State<Option<BookmarkEntry>>,
}

impl PartialEq for BookmarkPickerOverlay {
    fn eq(&self, other: &Self) -> bool {
        self.pending == other.pending
    }
}

impl Component for BookmarkPickerOverlay {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut pending = self.pending;
        let entry = self.pending.read().clone();
        let mut new_list_name: State<String> = use_state(String::new);

        let mut popup = Popup::new().on_close_request(move |_| *pending.write() = None);

        let Some(entry) = entry else {
            return popup.into_element();
        };

        let lists = BOOKMARKS_RX
            .get()
            .map(|rx| rx.borrow().lists.clone())
            .unwrap_or_default();

        popup = popup.child(
            rect()
                .vertical()
                .width(Size::fill())
                .spacing(4.)
                .child(
                    label()
                        .text("Bookmark to…")
                        .font_size(16.)
                        .font_weight(FontWeight::BOLD)
                        .color(c.on_surface),
                )
                .children(lists.into_iter().map(|list| {
                    let list_id = list.id.clone();
                    let entry = entry.clone();
                    list_row(&list.name, list.entries.len(), c, move || {
                        let list_id = list_id.clone();
                        let entry = entry.clone();
                        tokio::spawn(async move {
                            mutate_bookmarks(|content| add_entry(content, &list_id, entry)).await;
                        });
                        *pending.write() = None;
                    })
                    .into_element()
                }))
                .child(
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .padding(Gaps::new(8., 4., 8., 4.))
                        .spacing(8.)
                        .cross_align(Alignment::Center)
                        .child(
                            Input::new(new_list_name)
                                .placeholder("New list name")
                                .width(Size::flex(1.0))
                                .on_submit({
                                    let entry = entry.clone();
                                    move |name: String| {
                                        let name = name.trim().to_string();
                                        if name.is_empty() {
                                            return;
                                        }
                                        let entry = entry.clone();
                                        tokio::spawn(async move {
                                            mutate_bookmarks(|content| {
                                                let list_id = create_list(content, name);
                                                add_entry(content, &list_id, entry);
                                            })
                                            .await;
                                        });
                                        *pending.write() = None;
                                        new_list_name.set(String::new());
                                    }
                                }),
                        ),
                ),
        );

        popup.into_element()
    }
}

fn list_row(
    name: &str,
    entry_count: usize,
    c: AppColors,
    mut on_press: impl FnMut() + 'static,
) -> Element {
    rect()
        .width(Size::fill())
        .corner_radius(8.)
        .overflow(Overflow::Clip)
        .on_press(move |_| on_press())
        .child(
            Ripple::new().color(c.primary).width(Size::fill()).child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .content(Content::Flex)
                    .padding(Gaps::new(10., 8., 10., 8.))
                    .cross_align(Alignment::Center)
                    .child(
                        label()
                            .text(name.to_string())
                            .font_size(14.)
                            .color(c.on_surface)
                            .width(Size::flex(1.0)),
                    )
                    .child(
                        label()
                            .text(entry_count.to_string())
                            .font_size(12.)
                            .color(c.on_surface_muted),
                    ),
            ),
        )
        .into()
}
