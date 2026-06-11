use freya::prelude::*;

/// Styled search bar (white outer padding → rounded grey pill → icon + input).
/// `input` is bound live to the text field.  When `submit` is `Some(target)`,
/// pressing Enter writes the current text into `target`; otherwise the live
/// binding is the only output.
pub struct SearchBar {
    pub input: State<String>,
    pub placeholder: &'static str,
    /// When `Some`, pressing Enter copies the input value into this state.
    pub submit: Option<State<String>>,
}

impl PartialEq for SearchBar {
    fn eq(&self, _: &Self) -> bool {
        false
    }
}

impl Component for SearchBar {
    fn render(&self) -> impl IntoElement {
        let mut input_widget = Input::new(self.input)
            .flat()
            .placeholder(self.placeholder)
            .width(Size::fill());
        if let Some(mut target) = self.submit {
            input_widget = input_widget.on_submit(move |text: String| {
                *target.write() = text;
            });
        }

        rect()
            .horizontal()
            .width(Size::fill())
            .padding(Gaps::new(6., 12., 6., 12.))
            .background((255u8, 255u8, 255u8))
            .child(
                rect()
                    .horizontal()
                    .width(Size::fill())
                    .corner_radius(20.)
                    .background((240u8, 242u8, 245u8))
                    .padding(Gaps::new(0., 12., 0., 12.))
                    .cross_align(Alignment::Center)
                    .spacing(6.)
                    .child(
                        svg(freya_icons::lucide::search())
                            .color((130u8, 130u8, 130u8))
                            .width(Size::px(16.))
                            .height(Size::px(16.)),
                    )
                    .child(input_widget)
                    .child(if !self.input.read().is_empty() {
                        let mut input = self.input;
                        rect()
                            .center()
                            .width(Size::px(20.))
                            .height(Size::px(20.))
                            .corner_radius(10.)
                            .background((200u8, 202u8, 206u8))
                            .on_press(move |_| {
                                *input.write() = String::new();
                            })
                            .child(
                                svg(freya_icons::lucide::x())
                                    .color((80u8, 80u8, 80u8))
                                    .width(Size::px(12.))
                                    .height(Size::px(12.)),
                            )
                            .into_element()
                    } else {
                        rect().into_element()
                    }),
            )
    }
}
