use freya::prelude::*;
use freya_material_design::prelude::Ripple;

use crate::utils::use_app_colors;

pub(super) fn extract_urls(text: &str) -> Vec<String> {
    text.split_whitespace()
        .filter_map(|word| {
            let trimmed = word.trim_end_matches(|c: char| ".,;:!?)>]\"'".contains(c));
            if trimmed.starts_with("http://") || trimmed.starts_with("https://") {
                Some(trimmed.to_string())
            } else {
                None
            }
        })
        .collect()
}

pub(super) fn m3_list_item(
    icon: bytes::Bytes,
    item_label: &'static str,
    sublabel: Option<String>,
    icon_color: (u8, u8, u8),
    destructive: bool,
    container: impl ContainerExt + ChildrenExt + Into<Element>,
) -> Element {
    let c = use_app_colors();
    let text_color = if destructive { c.error } else { c.on_surface };

    container
        .child(
            Ripple::new()
                .color(if destructive { c.error } else { c.primary })
                .width(Size::fill())
                .child(
                    rect()
                        .horizontal()
                        .width(Size::fill())
                        .min_height(Size::px(56.))
                        .padding(Gaps::new(0., 24., 0., 16.))
                        .spacing(16.)
                        .cross_align(Alignment::Center)
                        .content(Content::Flex)
                        .child(
                            svg(icon)
                                .color(icon_color)
                                .width(Size::px(24.))
                                .height(Size::px(24.)),
                        )
                        .child(
                            rect()
                                .vertical()
                                .width(Size::flex(1.0))
                                .spacing(2.)
                                .child(label().text(item_label).font_size(16.).color(text_color))
                                .child(if let Some(sub) = sublabel {
                                    label()
                                        .text(sub)
                                        .font_size(14.)
                                        .color(c.on_surface_variant)
                                        .into_element()
                                } else {
                                    rect().into_element()
                                }),
                        )
                        .child(
                            svg(freya_icons::lucide::chevron_right())
                                .color(c.on_surface_variant)
                                .width(Size::px(20.))
                                .height(Size::px(20.)),
                        ),
                ),
        )
        .into()
}
