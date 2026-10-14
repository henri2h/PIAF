use std::rc::Rc;
use std::sync::Arc;

use crate::app::navigation::go_back_or_home;
use freya::prelude::*;

use crate::ui::components::{
    Chip, MediaViewer, MediaViewerItem, TopAppBar, TopAppBarTitle, empty_state, loading_state,
};
use crate::utils::const_values::AppColors;
use crate::utils::timeline_media::{MediaEntry, MediaKind};
use crate::utils::use_app_colors;

mod entry_list;
mod media_grid;
mod media_thumb;
mod use_room_media;

use entry_list::EntryList;
use media_grid::MediaGrid;
use use_room_media::{HistoryState, RoomMedia, use_room_media};

/// Start loading older history this close to the end of a list, in pixels.
const LOAD_AHEAD: f32 = 400.;

#[derive(Clone, Copy, PartialEq)]
enum Tab {
    Images,
    Files,
    Links,
}

impl Tab {
    const ALL: [Tab; 3] = [Tab::Images, Tab::Files, Tab::Links];

    fn label(self) -> &'static str {
        match self {
            Tab::Images => "Images",
            Tab::Files => "Files",
            Tab::Links => "Links",
        }
    }

    fn icon(self) -> Bytes {
        match self {
            Tab::Images => freya_icons::lucide::image(),
            Tab::Files => freya_icons::lucide::file(),
            Tab::Links => freya_icons::lucide::link(),
        }
    }

    fn kind(self) -> MediaKind {
        match self {
            Tab::Images => MediaKind::Image,
            Tab::Files => MediaKind::File,
            Tab::Links => MediaKind::Link,
        }
    }

    fn matches(self, entry: &MediaEntry) -> bool {
        entry.kind() == self.kind()
    }
}

/// Images, files and links shared in a room.
#[derive(Clone, PartialEq)]
pub struct RoomMediaPage {
    pub room_id: String,
}

impl Component for RoomMediaPage {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let media = use_room_media(&self.room_id);
        let tab = use_state(|| Tab::Images);
        let selected_key: State<Option<String>> = use_state(|| None);
        // Owned here: the viewer replaces the grid, and closing it must land
        // back where the user was.
        let grid_scroll = use_scroll_controller(ScrollConfig::default);

        if selected_key.read().is_some() {
            return viewer(media, selected_key, self.room_id.clone()).into_element();
        }

        let current = *tab.read();
        let entries = media.entries.read().clone();
        let body = if *media.loading.read() {
            loading_state(None, c).into_element()
        } else if *media.failed.read() {
            empty_state(
                freya_icons::lucide::circle_alert(),
                "Couldn't load this room's media",
                None,
                c,
            )
            .into_element()
        } else {
            match current {
                Tab::Images => MediaGrid {
                    media,
                    selected_key,
                    scroll: grid_scroll,
                }
                .into_element(),
                // Keyed: switching tabs must remount (the list's memo captures `kind`).
                Tab::Files => rect()
                    .key("files")
                    .expanded()
                    .child(EntryList {
                        media,
                        kind: MediaKind::File,
                        room_id: self.room_id.clone(),
                    })
                    .into_element(),
                // Keyed: switching tabs must remount (the list's memo captures `kind`).
                Tab::Links => rect()
                    .key("links")
                    .expanded()
                    .child(EntryList {
                        media,
                        kind: MediaKind::Link,
                        room_id: self.room_id.clone(),
                    })
                    .into_element(),
            }
        };

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            // The image viewer handles its own Esc; it isn't mounted with this.
            .on_global_key_down(|e: Event<KeyboardEventData>| {
                if e.key == Key::Named(NamedKey::Escape) {
                    go_back_or_home();
                }
            })
            .child(TopAppBar {
                title: TopAppBarTitle::Text("Media".to_string()),
                on_back: Some(Arc::new(go_back_or_home)),
                actions: vec![],
            })
            .child(tab_bar(tab, &entries))
            .child(
                rect()
                    .width(Size::fill())
                    .height(Size::flex(1.))
                    .child(body),
            )
            .into_element()
    }
}

fn viewer(media: RoomMedia, selected_key: State<Option<String>>, room_id: String) -> MediaViewer {
    let items: Vec<MediaViewerItem> = media
        .entries
        .read()
        .iter()
        .filter_map(|e| MediaViewerItem::from_entry(e))
        .collect();
    let on_load_more: Option<Rc<dyn Fn()>> = (media.history(MediaKind::Image)
        == HistoryState::More)
        .then(|| Rc::new(move || media.load_more(MediaKind::Image)) as Rc<dyn Fn()>);
    MediaViewer {
        items,
        selected_key,
        on_load_more,
        on_show_in_chat: Some(Rc::new(move |key: String| {
            if !key.starts_with("local-") {
                crate::app::navigation::navigate_to_room_at_event(room_id.clone(), key);
            }
        })),
    }
}

fn tab_bar(tab: State<Tab>, entries: &[Arc<MediaEntry>]) -> Element {
    let current = *tab.read();
    rect()
        .horizontal()
        .width(Size::fill())
        .content(Content::Flex)
        .padding(Gaps::new(4., 12., 8., 12.))
        .spacing(6.)
        .children(Tab::ALL.into_iter().map(|t| {
            let count = entries.iter().filter(|e| t.matches(e)).count();
            let text = if count > 0 {
                format!("{} {count}", t.label())
            } else {
                t.label().to_string()
            };
            let mut tab = tab;
            Chip::new(text, t == current, move |_| tab.set(t))
                .icon(t.icon())
                .width(Size::flex(1.))
                .height(34.)
                .into_element()
        }))
        .into_element()
}

/// Bottom of a `kind` list: spinner while loading, then the empty message
/// (when the list has nothing) and "Load older" while more history may exist.
fn list_footer(
    c: AppColors,
    media: RoomMedia,
    kind: MediaKind,
    empty: Option<&'static str>,
) -> Element {
    let history = media.history(kind);
    let loading = *media.paginating.read() || history == HistoryState::More;
    let footer = rect().center().width(Size::fill()).vertical().spacing(12.);
    let footer = match empty {
        Some(_) => footer.height(Size::px(240.)),
        None => footer.height(Size::px(60.)),
    };
    if loading {
        return footer.child(CircularLoader::new()).into_element();
    }
    footer
        .maybe_child(empty.map(|text| label().text(text).font_size(15.).color(c.on_surface_muted)))
        .maybe_child((history == HistoryState::Paused).then(|| {
            Button::new()
                .on_press(move |_| media.load_more(kind))
                .child("Load older")
        }))
        .into_element()
}

/// Loads older `kind` history while the end of a list is within `LOAD_AHEAD`
/// of the viewport. `content_height` computes the list's full height from
/// state (memos), not from the last render: a request's last entries and its
/// completion arrive together, before the list re-renders.
fn use_auto_load(
    media: RoomMedia,
    kind: MediaKind,
    scroll: ScrollController,
    viewport: State<Size2D>,
    content_height: impl Fn() -> f32 + 'static,
) {
    use_side_effect(move || {
        if *media.paginating.read() || *media.loading.read() {
            return;
        }
        let viewport = viewport.read().height;
        if media.history(kind) != HistoryState::More || viewport <= 0. {
            return;
        }
        let (_, y) = Into::<(i32, i32)>::into(scroll);
        if -y as f32 + viewport >= content_height() - LOAD_AHEAD {
            media.load_more(kind);
        }
    });
}
