use freya::prelude::*;

use crate::utils::const_values::AppColors;

pub(super) fn tab_btn(
    label_text: &'static str,
    value: u8,
    current: u8,
    mut tab: State<u8>,
    c: AppColors,
) -> impl IntoElement {
    let is_active = value == current;
    rect()
        .vertical()
        .padding(Gaps::new(12., 20., 0., 20.))
        .on_press(move |_| {
            *tab.write() = value;
        })
        .child(label().text(label_text).font_size(14.).color(if is_active {
            c.primary
        } else {
            c.on_surface_muted
        }))
        .child(
            rect()
                .width(Size::fill())
                .height(Size::px(2.))
                .background(if is_active { c.primary } else { c.surface }),
        )
}
