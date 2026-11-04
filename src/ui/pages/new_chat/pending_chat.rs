use std::sync::Arc;

use freya::prelude::*;
use futures::future::BoxFuture;

use crate::ui::components::TopAppBar;
use crate::utils::use_app_colors;

/// Creates the room and sends the first message (`String`); the room's ID.
pub(super) type CreateRoom = Arc<dyn Fn(String) -> BoxFuture<'static, Result<String, String>>>;

/// A chat that doesn't exist yet: `header` (who it's with), then a message
/// field. The room is created only when the first message is sent, then
/// opened.
#[derive(Clone)]
pub(super) struct PendingChat {
    pub title: String,
    pub header: Element,
    pub create: CreateRoom,
}

impl PartialEq for PendingChat {
    fn eq(&self, other: &Self) -> bool {
        self.title == other.title && self.header == other.header
    }
}

impl Component for PendingChat {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let text: State<String> = use_state(String::new);
        let mut sending = use_state(|| false);
        let mut error: State<Option<String>> = use_state(|| None);

        let is_sending = *sending.read();
        let is_empty = text.read().trim().is_empty();

        let create = self.create.clone();
        let mut send = move || {
            let msg = text.read().trim().to_string();
            if msg.is_empty() || *sending.peek() {
                return;
            }
            sending.set(true);
            error.set(None);
            let task = create(msg);
            spawn(async move {
                match crate::utils::on_tokio(task).await {
                    Some(Ok(room_id)) => crate::app::navigation::navigate_to_room(room_id),
                    Some(Err(e)) => {
                        error.set(Some(format!("Error: {e}")));
                        sending.set(false);
                    }
                    None => sending.set(false),
                }
            });
        };
        let mut on_submit = send.clone();

        rect()
            .expanded()
            .vertical()
            .content(Content::Flex)
            .background(c.surface)
            .child(TopAppBar::new(self.title.clone()))
            .child(self.header.clone())
            .child(
                rect().expanded().center().child(
                    label()
                        .text("No messages yet")
                        .font_size(14.)
                        .color(c.on_surface_muted),
                ),
            )
            .maybe_child(error.read().clone().map(|msg| {
                rect()
                    .width(Size::fill())
                    .padding(Gaps::new(0., 16., 4., 16.))
                    .child(label().text(msg).font_size(13.).color(c.error))
            }))
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .padding(Gaps::new(8., 8., 8., 8.))
                    .content(Content::Flex)
                    .cross_align(Alignment::Center)
                    .spacing(8.)
                    .background(c.surface)
                    .child(
                        rect()
                            .width(Size::flex(1.0))
                            .corner_radius(20.)
                            .background(c.surface_container)
                            .padding(Gaps::new(0., 4., 0., 12.))
                            .child(
                                Input::new(text)
                                    .flat()
                                    .auto_focus(true)
                                    .placeholder("Message")
                                    .width(Size::fill())
                                    .on_submit(move |_: String| on_submit()),
                            ),
                    )
                    .child(
                        Button::new()
                            .on_press(move |_| send())
                            .child(if is_sending {
                                rect()
                                    .center()
                                    .width(Size::px(18.))
                                    .height(Size::px(18.))
                                    .child(CircularLoader::new().size(16.))
                                    .into_element()
                            } else {
                                SvgViewer::new(freya_icons::lucide::send_horizontal())
                                    .color(if is_empty {
                                        c.on_surface_muted
                                    } else {
                                        c.primary
                                    })
                                    .width(Size::px(18.))
                                    .height(Size::px(18.))
                                    .into_element()
                            }),
                    ),
            )
    }
}
