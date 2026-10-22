use freya::prelude::*;

use crate::utils::const_values::AppColors;

/// Welcome and login pages: two panes (brand | content) from this width.
const AUTH_WIDE_MIN_WIDTH: f32 = 720.;
/// Below this height they shrink the logo and drop the tagline.
const AUTH_SHORT_MAX_HEIGHT: f32 = 560.;
pub const TAGLINE: &str = "Chat on Matrix, the open network.";

/// A welcome / login page's measured size (a hook: [`use_auth_size`]).
#[derive(Clone, Copy)]
pub struct AuthSize(State<(f32, f32)>);

pub fn use_auth_size() -> AuthSize {
    AuthSize(use_state(|| (0., 0.)))
}

impl AuthSize {
    /// Two panes: the brand beside the content.
    pub fn is_wide(&self) -> bool {
        self.0.read().0 >= AUTH_WIDE_MIN_WIDTH
    }

    /// A smaller logo, no tagline.
    pub fn is_short(&self) -> bool {
        let height = self.0.read().1;
        height > 0. && height < AUTH_SHORT_MAX_HEIGHT
    }

    /// The page around `body`, measuring itself.
    pub fn page(self, body: impl IntoElement, c: AppColors) -> Rect {
        let mut size = self.0;
        rect()
            .expanded()
            .background(c.surface)
            .on_sized(move |e: Event<SizedEventData>| {
                let area = (e.area.width(), e.area.height());
                if *size.peek() != area {
                    size.set(area);
                }
            })
            .child(body)
    }
}

static LOGO: &[u8] = include_bytes!("../../../assets/piaf_logo.png");

/// The app logo (bird and name) on a white card `size` wide: it is navy, so it
/// needs a light ground in both themes.
pub fn brand_logo(size: f32) -> Rect {
    rect()
        .width(Size::px(size))
        .height(Size::px(size))
        .padding(Gaps::new_all(size * 0.1))
        .corner_radius(size * 0.22)
        .background((255, 255, 255))
        .shadow(Shadow::new().y(4.).blur(16.).color((0, 0, 0, 50)))
        .child(
            ImageViewer::new(LOGO)
                .width(Size::fill())
                .height(Size::fill()),
        )
}

/// Logo and tagline on the brand colour. `short`: a smaller logo, no
/// tagline. `top_inset`: room left for a status bar drawn over it.
pub fn brand_hero(c: AppColors, short: bool, top_inset: f32) -> Rect {
    rect()
        .vertical()
        .center()
        .spacing(20.)
        .padding(Gaps::new(16. + top_inset, 24., 16., 24.))
        .background(c.splash_bg)
        .child(brand_logo(if short { 72. } else { 136. }))
        .maybe_child((!short).then(|| {
            label()
                .width(Size::fill())
                .text(TAGLINE)
                .font_size(16.)
                .text_align(TextAlign::Center)
                .color((255, 255, 255, 220u8))
        }))
}
