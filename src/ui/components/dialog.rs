use freya::animation::*;
use freya::prelude::*;

use super::HoverableExt;
use crate::utils::use_app_colors;

/// Modal dialog centered over a dimmed backdrop. Pressing the backdrop or Esc
/// calls `on_close`; the caller decides whether it shows.
pub struct Dialog {
    pub title: Option<String>,
    pub on_close: EventHandler<()>,
    children: Vec<Element>,
}

impl Dialog {
    pub fn new(on_close: impl FnMut(()) + 'static) -> Self {
        Self {
            title: None,
            on_close: EventHandler::new(on_close),
            children: vec![],
        }
    }

    pub fn title(mut self, title: impl Into<String>) -> Self {
        self.title = Some(title.into());
        self
    }
}

impl ChildrenExt for Dialog {
    fn get_children(&mut self) -> &mut Vec<Element> {
        &mut self.children
    }
}

/// The handler is left out: dialogs only re-render on what they show.
impl PartialEq for Dialog {
    fn eq(&self, other: &Self) -> bool {
        self.title == other.title && self.children == other.children
    }
}

impl Component for Dialog {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let animation = use_animation(|conf| {
            conf.on_creation(OnCreation::Run);
            (
                AnimNum::new(0., 160.).time(200).ease(Ease::Out),
                AnimNum::new(0., 1.).time(150).ease(Ease::Out),
            )
        });
        let (backdrop, shown) = {
            let values = animation.get();
            (values.0.value(), values.1.value())
        };
        let close = self.on_close.clone();
        let close_esc = self.on_close.clone();

        rect()
            .position(Position::new_global().top(0.).left(0.))
            .layer(Layer::Overlay)
            .width(Size::window_percent(100.))
            .height(Size::window_percent(100.))
            .padding(Gaps::new_all(24.))
            .center()
            .background((0u8, 0u8, 0u8, backdrop as u8))
            .on_press(move |_| close.call(()))
            .on_global_key_down(move |e: Event<KeyboardEventData>| {
                if e.key == Key::Named(NamedKey::Escape) {
                    close_esc.call(());
                }
            })
            .child(
                rect()
                    .width(Size::fill())
                    .max_width(Size::px(400.))
                    .vertical()
                    .opacity(shown)
                    .offset_y((1. - shown) * 16.)
                    .corner_radius(28.)
                    .background(c.surface_container)
                    .padding(Gaps::new_all(24.))
                    .spacing(16.)
                    .on_press(|e: Event<PressEventData>| e.stop_propagation())
                    .maybe_child(
                        self.title
                            .clone()
                            .map(|title| label().text(title).font_size(22.).color(c.on_surface)),
                    )
                    .children(self.children.clone()),
            )
    }
}

/// Confirmation dialog: `message`, then Cancel and a destructive `confirm` button.
pub fn confirm_dialog(
    title: impl Into<String>,
    message: impl Into<String>,
    confirm: &'static str,
    mut on_cancel: impl FnMut() + Clone + 'static,
    mut on_confirm: impl FnMut() + 'static,
) -> Dialog {
    let mut cancel = on_cancel.clone();
    Dialog::new(move |_| on_cancel())
        .title(title)
        .child(ConfirmBody {
            message: message.into(),
            confirm,
            on_cancel: EventHandler::new(move |_| cancel()),
            on_confirm: EventHandler::new(move |_| on_confirm()),
        })
}

struct ConfirmBody {
    message: String,
    confirm: &'static str,
    on_cancel: EventHandler<()>,
    on_confirm: EventHandler<()>,
}

impl PartialEq for ConfirmBody {
    fn eq(&self, other: &Self) -> bool {
        self.message == other.message && self.confirm == other.confirm
    }
}

impl Component for ConfirmBody {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        rect()
            .vertical()
            .width(Size::fill())
            .spacing(24.)
            .child(
                label()
                    .text(self.message.clone())
                    .font_size(14.)
                    .color(c.on_surface_variant),
            )
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .main_align(Alignment::End)
                    .spacing(8.)
                    .child(dialog_button(
                        "Cancel",
                        None,
                        c.primary,
                        self.on_cancel.clone(),
                    ))
                    .child(dialog_button(
                        self.confirm,
                        Some(c.error),
                        c.on_primary,
                        self.on_confirm.clone(),
                    )),
            )
    }
}

/// Dialog action: a text button, or filled with `background`.
pub fn dialog_button(
    text: &'static str,
    background: Option<(u8, u8, u8)>,
    color: (u8, u8, u8),
    handler: EventHandler<()>,
) -> Element {
    rect()
        .padding(Gaps::new_symmetric(10., 20.))
        .corner_radius(20.)
        .maybe(background.is_some(), |r| {
            r.background(background.unwrap_or_default())
        })
        .on_press(move |_| handler.call(()))
        .child(
            label()
                .text(text)
                .font_size(14.)
                .font_weight(FontWeight::MEDIUM)
                .color(color),
        )
        .hoverable(Size::auto(), Size::auto(), 20.)
        .into_element()
}
