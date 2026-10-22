mod gesture;

use std::rc::Rc;

use bytes::Bytes;
use freya::prelude::*;

use crate::utils::insets::status_bar_inset;
use freya_query::prelude::QueryCapability;
use matrix_sdk::ruma::events::room::MediaSource;

use crate::utils::{
    media::save_to_downloads,
    queries::{FetchMediaContent, media_source_key},
    timeline_media::{MediaContent, MediaEntry},
};

use super::{IconButton, MediaThumbnail, use_fade};
use crate::utils::insets;
use gesture::{Gesture, Point, Release};
use std::time::{Duration, Instant};

#[derive(Clone)]
pub enum ViewerSource {
    Bytes(Vec<u8>),
    Remote(MediaSource),
}

impl PartialEq for ViewerSource {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::Bytes(a), Self::Bytes(b)) => a == b,
            (Self::Remote(a), Self::Remote(b)) => media_source_key(a) == media_source_key(b),
            _ => false,
        }
    }
}

#[derive(Clone, PartialEq)]
pub struct MediaViewerItem {
    pub key: String,
    pub source: ViewerSource,
    /// (sender_name, timestamp) shown in the viewer header.
    pub info: Option<(String, String)>,
    pub caption: Option<String>,
    pub blurhash: Option<String>,
    pub thumbnail_source: Option<ViewerSource>,
}

impl MediaViewerItem {
    /// Viewer item for an image entry; `None` for files and links.
    pub fn from_entry(entry: &MediaEntry) -> Option<Self> {
        let MediaContent::Image {
            source,
            caption,
            blurhash,
            thumbnail_source,
        } = &entry.content
        else {
            return None;
        };
        Some(Self {
            key: entry.key.clone(),
            source: ViewerSource::Remote(source.clone()),
            info: Some((entry.sender_name.clone(), entry.timestamp.clone())),
            caption: caption.clone(),
            blurhash: blurhash.clone(),
            thumbnail_source: thumbnail_source.clone().map(ViewerSource::Remote),
        })
    }
}

// ── Public: full-screen viewer with prev/next navigation ──────────────────────

const PREFETCH_AHEAD: usize = 2;

pub struct MediaViewer {
    pub items: Vec<MediaViewerItem>,
    pub selected_key: State<Option<String>>,
    pub on_load_more: Option<Rc<dyn Fn()>>,
    /// Shows a "Show in chat" button; called with the item key (its event ID).
    pub on_show_in_chat: Option<Rc<dyn Fn(String)>>,
}

impl PartialEq for MediaViewer {
    fn eq(&self, other: &Self) -> bool {
        self.items == other.items && self.selected_key == other.selected_key
    }
}

impl Component for MediaViewer {
    fn render(&self) -> impl IntoElement {
        let items = self.items.clone();
        let mut selected_key = self.selected_key;
        let on_load_more = self.on_load_more.clone();
        let on_show_in_chat = self.on_show_in_chat.clone();

        // ── current_bytes: full-res image bytes for the selected item ────────
        //
        // WHY two states instead of just clearing in the effect:
        // Effects fire *after* the render that detects the dep change. Clearing
        // bytes there means the current render still draws the old image (one
        // stale frame). Instead we clear inline during the render, using
        // `last_fetched_key` to detect when the selection changed. The write
        // happens before `dl_bytes` is read further down, so the old bytes are
        // invisible from the very first render after navigation.
        let mut current_bytes: State<Option<Vec<u8>>> = use_state(|| None);
        let mut last_fetched_key: State<Option<String>> = use_state(|| None);

        let current_key = selected_key.read().clone(); // Ref dropped at ;
        let prev_key = last_fetched_key.read().clone(); // Ref dropped at ;
        // Touch state of the shown image; the controls (hidden by a tap).
        let mut gesture = use_state(Gesture::default);
        let anim_gen = use_state(|| 0u64);
        let mut chrome = use_state(|| true);
        let clock = *use_hook(|| std::rc::Rc::new(Instant::now()));
        let chrome_opacity = use_fade(
            *chrome.read() && gesture.read().dismiss_progress() < 0.05,
            150,
        );
        if current_key != prev_key {
            *current_bytes.write() = None;
            *last_fetched_key.write() = current_key.clone();
            // Another image: unzoomed, in place.
            gesture.write().reset();
        }

        // Start the fetch whenever the selection changes.
        // The in-flight stale guard prevents a slow earlier fetch from
        // overwriting bytes that a faster later fetch already wrote.
        let key_dep = current_key;
        let items_for_fetch = items.clone();
        use_side_effect_with_deps(&key_dep, move |key| {
            let Some(k) = key.as_deref() else { return };
            if let Some(item) = items_for_fetch.iter().find(|i| i.key == k) {
                match &item.source {
                    ViewerSource::Bytes(b) => {
                        *current_bytes.write() = Some(b.clone());
                    }
                    ViewerSource::Remote(s) => {
                        let fetch_key = media_source_key(s);
                        let expected_key = item.key.clone();
                        spawn(async move {
                            if let Ok(b) = FetchMediaContent.run(&fetch_key).await {
                                // Extract to bool before write() so the Ref is dropped.
                                let still_current =
                                    selected_key.read().as_deref() == Some(expected_key.as_str());
                                if still_current {
                                    *current_bytes.write() = Some(b);
                                }
                            }
                        });
                    }
                }
            }
        });

        // Preemptively load more when near the beginning of the loaded list.
        // Dep on selected key so this fires only on navigation, not on every render.
        let items_for_prefetch = items.clone();
        let on_load_more_prefetch = on_load_more.clone();
        let prefetch_key_dep = selected_key.read().clone();
        use_side_effect_with_deps(&prefetch_key_dep, move |key| {
            if let Some(k) = key.as_deref() {
                if let Some(i) = items_for_prefetch.iter().position(|it| it.key == k) {
                    if i < PREFETCH_AHEAD {
                        if let Some(f) = &on_load_more_prefetch {
                            f();
                        }
                    }
                }
            }
        });

        // "Want next" state: user pressed right at the boundary, waiting for new items.
        // known_count is initialised to the current item count so we only react to growth.
        let mut want_next: State<bool> = use_state(|| false);
        let items_len = items.len();
        let mut known_count: State<usize> = use_state(move || items_len);

        let prev_count = *known_count.read();
        let cur_count = items.len();
        if cur_count > prev_count {
            let items_snap = items.clone();
            let want = *want_next.read();
            spawn(async move {
                *known_count.write() = cur_count;
                if want {
                    // Navigate to the first newly-loaded item.
                    if let Some(item) = items_snap.get(prev_count) {
                        *selected_key.write() = Some(item.key.clone());
                    }
                    *want_next.write() = false;
                }
            });
        }

        let key_str = selected_key.read().clone();
        let idx = key_str
            .as_deref()
            .and_then(|k| items.iter().position(|i| i.key == k));

        let Some(idx) = idx else {
            return rect().into_element();
        };

        let total = items.len();
        let item = &items[idx];
        let has_prev = idx > 0;
        let has_next = idx + 1 < total;
        let can_load_more = on_load_more.is_some();
        let is_waiting_next = *want_next.read();

        // ── Navigation ───────────────────────────────────────────────────────
        let go_prev = {
            let items = items.clone();
            let on_load_more = on_load_more.clone();
            move || {
                let (mut selected_key, mut want_next) = (selected_key, want_next);
                want_next.set(false);
                if has_prev {
                    selected_key.set(Some(items[idx - 1].key.clone()));
                } else if let Some(f) = &on_load_more {
                    f();
                }
            }
        };
        let go_next = {
            let items = items.clone();
            let on_load_more = on_load_more.clone();
            move || {
                let (mut selected_key, mut want_next) = (selected_key, want_next);
                if has_next {
                    want_next.set(false);
                    selected_key.set(Some(items[idx + 1].key.clone()));
                } else if let Some(f) = &on_load_more {
                    f();
                    want_next.set(true);
                }
            }
        };
        let close = move || {
            let (mut selected_key, mut want_next) = (selected_key, want_next);
            selected_key.set(None);
            want_next.set(false);
        };

        let on_key_down = {
            let (go_prev, go_next) = (go_prev.clone(), go_next.clone());
            move |e: Event<KeyboardEventData>| match &e.key {
                Key::Named(NamedKey::ArrowLeft) | Key::Named(NamedKey::ArrowUp) => go_prev(),
                Key::Named(NamedKey::ArrowRight) | Key::Named(NamedKey::ArrowDown) => go_next(),
                Key::Named(NamedKey::Escape) => close(),
                _ => {}
            }
        };

        // ── Touch: swipe between images, swipe down to close, zoom ───────────
        let touch_gesture = gesture;
        let on_touch = {
            let (go_prev, go_next) = (go_prev.clone(), go_next.clone());
            move |e: Event<TouchEventData>| {
                let at = Point::new(e.global_location.x as f32, e.global_location.y as f32);
                let time = clock.elapsed().as_secs_f64() * 1000.;
                let mut gesture = touch_gesture;
                match e.phase {
                    TouchPhase::Started => {
                        // A finger takes over from any settling animation.
                        let mut anim_gen = anim_gen;
                        *anim_gen.write() += 1;
                        gesture.write().down(e.finger_id, at, time);
                    }
                    TouchPhase::Moved => {
                        gesture.write().moved(e.finger_id, at, has_prev, has_next);
                    }
                    TouchPhase::Ended | TouchPhase::Cancelled => {
                        let release = gesture
                            .write()
                            .up(e.finger_id, at, time, has_prev, has_next);
                        if gesture.peek().is_active() {
                            return;
                        }
                        let width = gesture.peek().viewport.x;
                        let height = gesture.peek().viewport.y;
                        match release {
                            Release::Next => {
                                let go_next = go_next.clone();
                                settle(gesture, anim_gen, -width, 0., move || go_next());
                            }
                            Release::Prev => {
                                let go_prev = go_prev.clone();
                                settle(gesture, anim_gen, width, 0., move || go_prev());
                            }
                            Release::Close => {
                                let to = height * gesture.peek().dy.signum();
                                settle(gesture, anim_gen, 0., to, close);
                            }
                            Release::Tap => {
                                let tap = gesture.peek().tap_count();
                                spawn(async move {
                                    timer(Duration::from_millis(Gesture::DOUBLE_TAP_MS as u64))
                                        .await;
                                    if gesture.peek().tap_is_current(tap) {
                                        chrome.toggle();
                                    }
                                });
                            }
                            Release::Zoomed => {}
                            Release::None => settle(gesture, anim_gen, 0., 0., || {}),
                        }
                    }
                }
            }
        };

        // ── Panes: previous, current, next, side by side ─────────────────────
        let g = gesture.read().clone();
        let (width, height) = (g.viewport.x, g.viewport.y);
        let dismiss = g.dismiss_progress();
        let dl_bytes = current_bytes.read().clone();
        let dl_available = dl_bytes.is_some();
        let caption = item.caption.clone();

        let current = if is_waiting_next {
            rect()
                .expanded()
                .center()
                .child(CircularLoader::new())
                .into_element()
        } else if let Some(b) = dl_bytes.clone() {
            ImageViewer::new((item.key.clone(), Bytes::from(b)))
                .width(Size::fill())
                .height(Size::fill())
                .aspect_ratio(AspectRatio::Min)
                .image_cover(ImageCover::Center)
                .into_element()
        } else {
            // The thumbnail (or blurhash) while the full image loads.
            rect()
                .expanded()
                .child(placeholder(item))
                .child(
                    rect()
                        .position(Position::new_absolute().top(0.).left(0.))
                        .expanded()
                        .center()
                        .child(CircularLoader::new().size(40.)),
                )
                .into_element()
        };
        let shrink = g.scale * (1. - 0.15 * dismiss);
        let pane = |x: f32, child: Element| {
            rect()
                .position(Position::new_absolute().top(0.).left(x))
                .width(Size::px(width))
                .height(Size::px(height))
                .child(child)
        };
        let strip = rect()
            .expanded()
            .overflow(Overflow::Clip)
            .maybe_child(has_prev.then(|| pane(g.dx - width, placeholder(&items[idx - 1]))))
            .child(
                pane(g.dx, current)
                    .key(item.key.clone())
                    .offset_x(g.offset.x)
                    .offset_y(g.offset.y + g.dy)
                    .scale((shrink, shrink)),
            )
            .maybe_child(has_next.then(|| pane(g.dx + width, placeholder(&items[idx + 1]))));

        // ── Controls over the image ──────────────────────────────────────────
        const WHITE: (u8, u8, u8) = (255, 255, 255);
        let icon = |svg: Bytes, tooltip: &'static str, on_press: Box<dyn FnMut()>| {
            let mut on_press = on_press;
            IconButton::new(svg, WHITE, move |_| on_press())
                .tooltip(tooltip)
                .size(44., 22.)
                .into_element()
        };
        let subtitle = {
            let counter = (total > 1).then(|| format!("{} of {}", idx + 1, total));
            match (item.info.as_ref().map(|(_, ts)| ts.clone()), counter) {
                (Some(ts), Some(n)) => format!("{ts} · {n}"),
                (Some(ts), None) => ts,
                (None, Some(n)) => n,
                (None, None) => String::new(),
            }
        };
        let title = item
            .info
            .as_ref()
            .map(|(sender, _)| sender.clone())
            .unwrap_or_else(|| "Image".to_string());
        let share = cfg!(target_os = "android").then(|| {
            let bytes = dl_bytes.clone();
            let name = format!("{}.{}", item.key.replace(['$', ':', '/'], ""), "img");
            icon(
                freya_icons::lucide::share_2(),
                "Share",
                Box::new(move || {
                    if let Some(b) = bytes.clone() {
                        crate::utils::media::share_image(&name, b);
                    }
                }),
            )
        });
        let show_in_chat = on_show_in_chat.map(|f| {
            let key = item.key.clone();
            icon(
                freya_icons::lucide::message_square(),
                "Show in chat",
                Box::new(move || f(key.clone())),
            )
        });
        let download = {
            let bytes = dl_bytes.clone();
            IconButton::new(
                freya_icons::lucide::download(),
                if dl_available { WHITE } else { (110, 110, 110) },
                move |_| {
                    if let Some(b) = bytes.clone() {
                        tokio::task::spawn(async move { save_to_downloads(&b).await });
                    }
                },
            )
            .tooltip("Download")
            .size(44., 22.)
        };
        // Touches on the controls are theirs, not the image's gestures.
        let own_touches = |el: Rect| {
            el.on_touch_start(|e: Event<TouchEventData>| e.stop_propagation())
                .on_touch_move(|e: Event<TouchEventData>| e.stop_propagation())
                .on_touch_end(|e: Event<TouchEventData>| e.stop_propagation())
        };
        let top_bar = rect()
            .position(Position::new_absolute().top(0.).left(0.))
            .width(Size::fill())
            .opacity(chrome_opacity)
            .padding(Gaps::new(status_bar_inset(), 4., 24., 4.))
            .background(
                LinearGradient::new()
                    .angle(180.)
                    .stop(((0u8, 0u8, 0u8, 170u8), 0.))
                    .stop(((0u8, 0u8, 0u8, 0u8), 100.)),
            )
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .height(Size::px(56.))
                    .content(Content::Flex)
                    .cross_align(Alignment::Center)
                    .spacing(4.)
                    .child(icon(
                        freya_icons::lucide::arrow_left(),
                        "Close",
                        Box::new(close),
                    ))
                    .child(
                        rect()
                            .vertical()
                            .width(Size::flex(1.))
                            .spacing(2.)
                            .child(
                                label()
                                    .width(Size::fill())
                                    .text(title)
                                    .max_lines(1)
                                    .text_overflow(TextOverflow::Ellipsis)
                                    .font_weight(FontWeight::MEDIUM)
                                    .font_size(16.)
                                    .color(WHITE),
                            )
                            .maybe_child((!subtitle.is_empty()).then(|| {
                                label()
                                    .text(subtitle)
                                    .font_size(12.)
                                    .color((210u8, 210u8, 210u8))
                            })),
                    )
                    .maybe_child(show_in_chat)
                    .maybe_child(share)
                    .child(download),
            );
        let bottom = caption.map(|cap| {
            own_touches(rect())
                .position(Position::new_absolute().bottom(0.).left(0.))
                .width(Size::fill())
                .opacity(chrome_opacity)
                .padding(Gaps::new(32., 16., 24. + insets::current().bottom, 16.))
                .background(
                    LinearGradient::new()
                        .angle(180.)
                        .stop(((0u8, 0u8, 0u8, 0u8), 0.))
                        .stop(((0u8, 0u8, 0u8, 170u8), 100.)),
                )
                .child(
                    label()
                        .width(Size::fill())
                        .text(cap)
                        .max_lines(6)
                        .text_overflow(TextOverflow::Ellipsis)
                        .font_size(14.)
                        .color(WHITE),
                )
        });
        // Desktop: round arrows over the image's sides (touch swipes instead).
        let arrows = (!cfg!(target_os = "android")).then(|| {
            let arrow = |svg: Bytes,
                         tooltip: &'static str,
                         enabled: bool,
                         side: Position,
                         on_press: Box<dyn FnMut()>| {
                let mut on_press = on_press;
                rect()
                    .position(side)
                    .opacity(chrome_opacity)
                    .corner_radius(24.)
                    .background((0u8, 0u8, 0u8, 120u8))
                    .child(
                        IconButton::new(
                            svg,
                            if enabled { WHITE } else { (110, 110, 110) },
                            move |_| on_press(),
                        )
                        .tooltip(tooltip)
                        .size(48., 26.),
                    )
            };
            let middle = height / 2. - 24.;
            rect()
                .position(Position::new_absolute().top(0.).left(0.))
                .expanded()
                .child(arrow(
                    freya_icons::lucide::chevron_left(),
                    "Previous",
                    has_prev || can_load_more,
                    Position::new_absolute().top(middle).left(12.),
                    Box::new(go_prev.clone()),
                ))
                .child(arrow(
                    freya_icons::lucide::chevron_right(),
                    "Next",
                    has_next || can_load_more,
                    Position::new_absolute().top(middle).right(12.),
                    Box::new(go_next.clone()),
                ))
        });

        let backdrop = (1. - dismiss) * 255.;
        rect()
            .expanded()
            .background((0u8, 0u8, 0u8, backdrop as u8))
            .on_global_key_down(on_key_down)
            .on_sized(move |e: Event<SizedEventData>| {
                let size = Point::new(e.area.width(), e.area.height());
                if gesture.peek().viewport != size {
                    gesture.write().viewport = size;
                }
            })
            .on_touch_start(on_touch.clone())
            .on_touch_move(on_touch.clone())
            .on_touch_end(on_touch.clone())
            .on_touch_cancel(on_touch)
            .child(strip)
            // Fully faded controls leave: no invisible buttons to hit.
            .maybe_child(arrows.filter(|_| chrome_opacity > 0.))
            .maybe_child((chrome_opacity > 0.).then(|| own_touches(top_bar)))
            .maybe_child(bottom.filter(|_| chrome_opacity > 0.))
            .into()
    }
}

/// The thumbnail (or blurhash) of `item`: neighbours, and the current image
/// while it loads. Keyed so it remounts per item.
fn placeholder(item: &MediaViewerItem) -> Element {
    rect()
        .key(format!("{}-ph", item.key))
        .expanded()
        .child(MediaThumbnail {
            item_key: item.key.clone(),
            blurhash: item.blurhash.clone(),
            thumbnail_source: item.thumbnail_source.clone(),
            fallback_source: None,
            thumb_size: None,
        })
        .into_element()
}

/// Eases the paging / dismiss offsets to `(to_dx, to_dy)`, then runs `done`
/// (and puts the offsets back at rest). A new touch cancels it.
fn settle(
    mut gesture: State<Gesture>,
    mut anim_gen: State<u64>,
    to_dx: f32,
    to_dy: f32,
    done: impl FnOnce() + 'static,
) {
    const MS: f32 = 220.;
    let generation = *anim_gen.peek() + 1;
    anim_gen.set(generation);
    let (from_dx, from_dy) = {
        let g = gesture.peek();
        (g.dx, g.dy)
    };
    spawn(async move {
        let start = Instant::now();
        loop {
            if *anim_gen.peek() != generation {
                return;
            }
            let t = (start.elapsed().as_secs_f32() * 1000. / MS).min(1.);
            // Ease out (cubic).
            let k = 1. - (1. - t).powi(3);
            {
                let mut g = gesture.write();
                g.dx = from_dx + (to_dx - from_dx) * k;
                g.dy = from_dy + (to_dy - from_dy) * k;
            }
            if t >= 1. {
                break;
            }
            timer(Duration::from_millis(16)).await;
        }
        done();
        let mut g = gesture.write();
        g.dx = 0.;
        g.dy = 0.;
    });
}

#[cfg(test)]
mod tests {
    use std::cell::RefCell;
    use std::time::Duration;

    use freya::prelude::*;
    use freya_testing::prelude::*;

    use super::{MediaViewer, MediaViewerItem, ViewerSource};

    thread_local! {
        static SELECTED: RefCell<Option<String>> = const { RefCell::new(None) };
    }

    fn item(key: &str) -> MediaViewerItem {
        MediaViewerItem {
            key: key.to_string(),
            source: ViewerSource::Bytes(vec![]),
            info: Some(("Henri".into(), "Apr 22".into())),
            caption: Some("A caption".into()),
            blurhash: None,
            thumbnail_source: None,
        }
    }

    fn app() -> impl IntoElement {
        use_init_theme(dark_theme);
        let selected = use_state(|| Some("b".to_string()));
        SELECTED.with(|s| *s.borrow_mut() = selected.read().clone());
        MediaViewer {
            items: vec![item("a"), item("b"), item("c")],
            selected_key: selected,
            on_load_more: None,
            on_show_in_chat: None,
        }
    }

    fn runner() -> (tokio::runtime::Runtime, TestingRunner) {
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let test = {
            let _guard = runtime.enter();
            let (mut test, _) = TestingRunner::new(app, Size2D::new(400., 800.), |_| {}, 1.0);
            test.sync_and_update();
            test
        };
        (runtime, test)
    }

    fn drag(test: &mut TestingRunner, from: (f64, f64), to: (f64, f64)) {
        test.press_touch(from);
        for i in 1..=6 {
            let f = i as f64 / 6.;
            test.move_touch((from.0 + (to.0 - from.0) * f, from.1 + (to.1 - from.1) * f));
        }
        test.release_touch(to);
        // The settle animation, then the switch.
        test.poll(Duration::from_millis(16), Duration::from_millis(400));
    }

    fn selected() -> Option<String> {
        SELECTED.with(|s| s.borrow().clone())
    }

    fn controls_shown(test: &TestingRunner) -> bool {
        test.find(|_, element| Label::try_downcast(element).filter(|l| l.text.as_ref() == "Henri"))
            .is_some()
    }

    #[test]
    fn swipe_left_shows_the_next_image() {
        let (runtime, mut test) = runner();
        let _guard = runtime.enter();
        drag(&mut test, (300., 400.), (60., 410.));
        assert_eq!(selected().as_deref(), Some("c"));
    }

    #[test]
    fn swipe_down_closes() {
        let (runtime, mut test) = runner();
        let _guard = runtime.enter();
        drag(&mut test, (200., 300.), (205., 560.));
        assert_eq!(selected(), None);
    }

    #[test]
    fn a_tap_toggles_the_controls() {
        let (runtime, mut test) = runner();
        let _guard = runtime.enter();
        assert!(controls_shown(&test));
        test.press_touch((200., 400.));
        test.release_touch((200., 400.));
        test.poll(Duration::from_millis(16), Duration::from_millis(600));
        assert!(!controls_shown(&test), "hidden after a tap");
        test.press_touch((200., 400.));
        test.release_touch((200., 400.));
        test.poll(Duration::from_millis(16), Duration::from_millis(600));
        assert!(controls_shown(&test), "back after another");
    }
}
