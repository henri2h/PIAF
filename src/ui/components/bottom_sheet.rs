use freya::animation::*;
use freya::prelude::*;

use super::HoverableExt;
use crate::utils::use_app_colors;

/// Modal sheet sliding up from the bottom over a dimmed backdrop. Pressing
/// the backdrop or Esc calls `on_close`; the caller decides whether it shows.
pub struct BottomSheet {
    pub title: Option<String>,
    pub on_close: EventHandler<()>,
    children: Vec<Element>,
}

impl BottomSheet {
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

impl ChildrenExt for BottomSheet {
    fn get_children(&mut self) -> &mut Vec<Element> {
        &mut self.children
    }
}

/// The handler is left out: sheets only re-render on what they show.
impl PartialEq for BottomSheet {
    fn eq(&self, other: &Self) -> bool {
        self.title == other.title && self.children == other.children
    }
}

impl Component for BottomSheet {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let animation = use_animation(|conf| {
            conf.on_creation(OnCreation::Run);
            (
                AnimNum::new(0., 160.).time(200).ease(Ease::Out),
                AnimNum::new(1., 0.)
                    .time(250)
                    .ease(Ease::Out)
                    .function(Function::Expo),
            )
        });
        let (backdrop, hidden) = {
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
            .background((0u8, 0u8, 0u8, backdrop as u8))
            .on_press(move |_| close.call(()))
            .on_global_key_down(move |e: Event<KeyboardEventData>| {
                if e.key == Key::Named(NamedKey::Escape) {
                    close_esc.call(());
                }
            })
            .child(
                rect()
                    .position(Position::new_absolute().bottom(0.).left(0.))
                    .offset_y(hidden * 300.)
                    .width(Size::fill())
                    .vertical()
                    .corner_radius(20.)
                    .background(c.surface)
                    .padding(Gaps::new(8., 0., 24., 0.))
                    .on_press(|e: Event<PressEventData>| e.stop_propagation())
                    .maybe_child(self.title.clone().map(|title| {
                        label()
                            .margin(Gaps::new(12., 24., 8., 24.))
                            .text(title)
                            .font_size(18.)
                            .font_weight(FontWeight::BOLD)
                            .color(c.on_surface)
                    }))
                    .children(self.children.clone()),
            )
    }
}

/// Confirmation sheet: `message`, then Cancel and a destructive `confirm` button.
pub fn confirm_sheet(
    title: impl Into<String>,
    message: impl Into<String>,
    confirm: &'static str,
    mut on_cancel: impl FnMut() + Clone + 'static,
    mut on_confirm: impl FnMut() + 'static,
) -> BottomSheet {
    let mut cancel = on_cancel.clone();
    BottomSheet::new(move |_| on_cancel())
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
        let button = |text: &'static str, bg, fg, handler: EventHandler<()>| {
            rect()
                .width(Size::fill())
                .padding(Gaps::new(12., 0., 12., 0.))
                .background(bg)
                .center()
                .on_press(move |_| handler.call(()))
                .child(label().text(text).font_size(14.).color(fg))
                .hoverable(Size::flex(1.), Size::auto(), 8.)
        };
        rect()
            .vertical()
            .width(Size::fill())
            .padding(Gaps::new(0., 24., 0., 24.))
            .spacing(20.)
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
                    .content(Content::Flex)
                    .spacing(12.)
                    .child(button(
                        "Cancel",
                        c.surface_container,
                        c.on_surface,
                        self.on_cancel.clone(),
                    ))
                    .child(button(
                        self.confirm,
                        c.error,
                        c.on_primary,
                        self.on_confirm.clone(),
                    )),
            )
    }
}
