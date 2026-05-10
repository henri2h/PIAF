#![allow(dead_code)]

use freya::prelude::{ColorsSheet, Color};

/// User-configurable theme preference (stored as u8: 0=System, 1=Light, 2=Dark).
#[derive(Clone, Copy, PartialEq, Debug, Default)]
pub enum ThemePref {
    #[default]
    System = 0,
    Light = 1,
    Dark = 2,
}

impl ThemePref {
    pub fn from_u8(v: u8) -> Self {
        match v {
            1 => Self::Light,
            2 => Self::Dark,
            _ => Self::System,
        }
    }
    pub fn to_u8(self) -> u8 {
        self as u8
    }
    pub fn label(self) -> &'static str {
        match self {
            Self::System => "System",
            Self::Light => "Light",
            Self::Dark => "Dark",
        }
    }
}

// ── Platform insets ───────────────────────────────────────────────────────────

/// Top inset to clear the Android status bar.
/// Freya has no runtime inset API; 40 px matches the android example hardcoded value.
#[cfg(target_os = "android")]
pub const STATUS_BAR_INSET: f32 = 40.0;
#[cfg(not(target_os = "android"))]
pub const STATUS_BAR_INSET: f32 = 0.0;

// ── AppColors — M3 color scheme, light and dark ───────────────────────────────

/// All M3 color tokens for the app. Use `use_app_colors()` inside components.
#[derive(Clone, Copy, PartialEq, Debug)]
pub struct AppColors {
    // Brand
    pub primary: (u8, u8, u8),
    pub on_primary: (u8, u8, u8),
    // Surfaces
    pub surface: (u8, u8, u8),
    pub surface_container: (u8, u8, u8),
    pub surface_container_high: (u8, u8, u8),
    // Text
    pub on_surface: (u8, u8, u8),
    pub on_surface_variant: (u8, u8, u8),
    pub on_surface_muted: (u8, u8, u8),
    pub on_surface_faint: (u8, u8, u8),
    // Semantic
    pub error: (u8, u8, u8),
    // Borders
    pub outline: (u8, u8, u8),
    pub outline_variant: (u8, u8, u8),
    pub outline_variant_light: (u8, u8, u8),
    // Chat bubbles
    pub bubble_me_text: (u8, u8, u8),
    pub bubble_other_text: (u8, u8, u8),
    // Reply quotes
    pub reply_me_bg: (u8, u8, u8),
    pub reply_other_bg: (u8, u8, u8),
    pub reply_me_sender: (u8, u8, u8),
    pub reply_other_sender: (u8, u8, u8),
    pub reply_me_text: (u8, u8, u8),
    pub reply_other_text: (u8, u8, u8),
    // Timestamps / receipts
    pub timestamp_me: (u8, u8, u8),
    pub receipt_default: (u8, u8, u8),
    pub receipt_read: (u8, u8, u8),
    // Reaction pills
    pub reaction_active_bg: (u8, u8, u8),
    pub reaction_active_text: (u8, u8, u8),
    pub reaction_default_bg: (u8, u8, u8),
    pub reaction_default_text: (u8, u8, u8),
    // Misc
    pub date_separator_bg: (u8, u8, u8),
    pub overflow_badge_bg: (u8, u8, u8),
    pub status_online: (u8, u8, u8),
    pub compose_text: (u8, u8, u8),
    pub compose_edit_text: (u8, u8, u8),
    pub splash_bg: (u8, u8, u8),
}

impl AppColors {
    /// Derive all app colors from freya's ColorsSheet.
    /// Standard tokens come directly from the sheet; chat-specific tokens are
    /// computed from the base colors, varying by light vs dark (detected via
    /// text_primary brightness).
    pub fn from_colors(c: &ColorsSheet) -> Self {
        let is_dark = c.text_primary.r() > 128;
        let rgb = |color: Color| (color.r(), color.g(), color.b());

        let (
            reply_me_bg, reply_other_bg,
            reply_me_sender, reply_other_sender,
            reply_me_text, reply_other_text,
            timestamp_me, receipt_default,
            reaction_active_bg, reaction_active_text,
            reaction_default_text,
            date_separator_bg,
        ) = if is_dark {
            (
                (20, 100, 180), (42, 45, 58),
                (170, 215, 255), (120, 158, 205),
                (195, 228, 255), (175, 175, 195),
                (185, 222, 255), (185, 222, 255),
                (18, 58, 115), (125, 188, 255),
                (185, 185, 205),
                (48, 43, 62),
            )
        } else {
            (
                (20, 120, 200), (210, 213, 218),
                (180, 220, 255), (60, 100, 160),
                (200, 230, 255), (80, 80, 80),
                (190, 225, 255), (190, 225, 255),
                (200, 230, 255), (0, 80, 160),
                (60, 60, 60),
                (231, 224, 236),
            )
        };

        Self {
            primary:                rgb(c.primary),
            on_primary:             rgb(c.text_inverse),
            surface:                rgb(c.background),
            surface_container:      rgb(c.surface_primary),
            surface_container_high: rgb(c.surface_secondary),
            on_surface:             rgb(c.text_primary),
            on_surface_variant:     rgb(c.text_secondary),
            on_surface_muted:       rgb(c.text_secondary),
            on_surface_faint:       rgb(c.text_placeholder),
            error:                  rgb(c.error),
            outline:                rgb(c.border),
            outline_variant:        rgb(c.border_focus),
            outline_variant_light:  rgb(c.border_disabled),
            bubble_me_text:         rgb(c.text_inverse),
            bubble_other_text:      rgb(c.text_primary),
            reply_me_bg,
            reply_other_bg,
            reply_me_sender,
            reply_other_sender,
            reply_me_text,
            reply_other_text,
            timestamp_me,
            receipt_default,
            receipt_read:           rgb(c.success),
            reaction_active_bg,
            reaction_active_text,
            reaction_default_bg:    rgb(c.surface_primary),
            reaction_default_text,
            date_separator_bg,
            overflow_badge_bg:      rgb(c.surface_inverse),
            status_online:          rgb(c.success),
            compose_text:           rgb(c.text_primary),
            compose_edit_text:      rgb(c.text_secondary),
            splash_bg:              rgb(c.primary),
        }
    }
}

// ── Piaf color palettes for light and dark themes ─────────────────────────────

pub fn piaf_light_colors() -> ColorsSheet {
    ColorsSheet {
        primary:                  Color::from_rgb(29, 155, 240),
        secondary:                Color::from_rgb(29, 155, 240),
        tertiary:                 Color::from_rgb(15, 130, 200),
        success:                  Color::from_rgb(67, 160, 71),
        warning:                  Color::from_rgb(255, 193, 7),
        error:                    Color::from_rgb(186, 26, 26),
        info:                     Color::from_rgb(33, 150, 243),
        background:               Color::from_rgb(255, 255, 255),
        surface_primary:          Color::from_rgb(240, 242, 245),
        surface_secondary:        Color::from_rgb(232, 234, 237),
        surface_tertiary:         Color::from_rgb(248, 249, 250),
        surface_inverse:          Color::from_rgb(15, 15, 18),
        surface_inverse_secondary: Color::from_rgb(26, 28, 35),
        surface_inverse_tertiary: Color::from_rgb(36, 38, 48),
        border:                   Color::from_rgb(200, 205, 210),
        border_focus:             Color::from_rgb(202, 207, 212),
        border_disabled:          Color::from_rgb(225, 228, 232),
        text_primary:             Color::from_rgb(28, 27, 31),
        text_secondary:           Color::from_rgb(73, 89, 104),
        text_placeholder:         Color::from_rgb(130, 130, 130),
        text_inverse:             Color::WHITE,
        text_highlight:           Color::from_rgb(29, 155, 240),
        focus:                    Color::from_rgb(200, 232, 255),
        active:                   Color::from_rgb(232, 234, 237),
        disabled:                 Color::from_rgb(200, 205, 210),
        overlay:                  Color::from_argb(128, 0, 0, 0),
        shadow:                   Color::from_argb(51, 0, 0, 0),
    }
}

pub fn piaf_dark_colors() -> ColorsSheet {
    ColorsSheet {
        primary:                  Color::from_rgb(29, 155, 240),
        secondary:                Color::from_rgb(29, 155, 240),
        tertiary:                 Color::from_rgb(15, 130, 200),
        success:                  Color::from_rgb(78, 175, 88),
        warning:                  Color::from_rgb(255, 213, 79),
        error:                    Color::from_rgb(255, 100, 100),
        info:                     Color::from_rgb(100, 181, 246),
        background:               Color::from_rgb(15, 15, 18),
        surface_primary:          Color::from_rgb(26, 28, 35),
        surface_secondary:        Color::from_rgb(36, 38, 48),
        surface_tertiary:         Color::from_rgb(22, 22, 28),
        surface_inverse:          Color::from_rgb(240, 242, 245),
        surface_inverse_secondary: Color::from_rgb(232, 234, 237),
        surface_inverse_tertiary: Color::from_rgb(255, 255, 255),
        border:                   Color::from_rgb(55, 58, 70),
        border_focus:             Color::from_rgb(48, 52, 63),
        border_disabled:          Color::from_rgb(33, 36, 47),
        text_primary:             Color::from_rgb(228, 225, 235),
        text_secondary:           Color::from_rgb(155, 170, 190),
        text_placeholder:         Color::from_rgb(85, 88, 100),
        text_inverse:             Color::WHITE,
        text_highlight:           Color::from_rgb(29, 155, 240),
        focus:                    Color::from_rgb(18, 58, 115),
        active:                   Color::from_rgb(36, 38, 48),
        disabled:                 Color::from_rgb(55, 58, 70),
        overlay:                  Color::from_argb(51, 255, 255, 255),
        shadow:                   Color::from_argb(153, 0, 0, 0),
    }
}
