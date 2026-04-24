#![allow(dead_code)]

use freya::prelude::PreferredTheme;

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
    pub fn light() -> Self {
        Self {
            primary: (29, 155, 240),
            on_primary: (255, 255, 255),
            surface: (255, 255, 255),
            surface_container: (240, 242, 245),
            surface_container_high: (232, 234, 237),
            on_surface: (28, 27, 31),
            on_surface_variant: (73, 89, 104),
            on_surface_muted: (100, 100, 100),
            on_surface_faint: (130, 130, 130),
            error: (186, 26, 26),
            outline: (200, 205, 210),
            outline_variant: (202, 207, 212),
            outline_variant_light: (225, 228, 232),
            bubble_me_text: (255, 255, 255),
            bubble_other_text: (20, 20, 20),
            reply_me_bg: (20, 120, 200),
            reply_other_bg: (210, 213, 218),
            reply_me_sender: (180, 220, 255),
            reply_other_sender: (60, 100, 160),
            reply_me_text: (200, 230, 255),
            reply_other_text: (80, 80, 80),
            timestamp_me: (190, 225, 255),
            receipt_default: (190, 225, 255),
            receipt_read: (80, 220, 140),
            reaction_active_bg: (200, 230, 255),
            reaction_active_text: (0, 80, 160),
            reaction_default_bg: (230, 232, 235),
            reaction_default_text: (60, 60, 60),
            date_separator_bg: (231, 224, 236),
            overflow_badge_bg: (150, 150, 150),
            status_online: (67, 160, 71),
            compose_text: (50, 50, 50),
            compose_edit_text: (80, 80, 80),
            splash_bg: (15, 163, 242),
        }
    }

    pub fn dark() -> Self {
        Self {
            primary: (29, 155, 240),
            on_primary: (255, 255, 255),
            surface: (15, 15, 18),
            surface_container: (26, 28, 35),
            surface_container_high: (36, 38, 48),
            on_surface: (228, 225, 235),
            on_surface_variant: (155, 170, 190),
            on_surface_muted: (125, 128, 140),
            on_surface_faint: (85, 88, 100),
            error: (255, 100, 100),
            outline: (55, 58, 70),
            outline_variant: (48, 52, 63),
            outline_variant_light: (33, 36, 47),
            bubble_me_text: (255, 255, 255),
            bubble_other_text: (222, 218, 230),
            reply_me_bg: (20, 100, 180),
            reply_other_bg: (42, 45, 58),
            reply_me_sender: (170, 215, 255),
            reply_other_sender: (120, 158, 205),
            reply_me_text: (195, 228, 255),
            reply_other_text: (175, 175, 195),
            timestamp_me: (185, 222, 255),
            receipt_default: (185, 222, 255),
            receipt_read: (75, 215, 135),
            reaction_active_bg: (18, 58, 115),
            reaction_active_text: (125, 188, 255),
            reaction_default_bg: (38, 41, 53),
            reaction_default_text: (185, 185, 205),
            date_separator_bg: (48, 43, 62),
            overflow_badge_bg: (85, 88, 100),
            status_online: (78, 175, 88),
            compose_text: (218, 213, 228),
            compose_edit_text: (185, 182, 198),
            splash_bg: (12, 140, 210),
        }
    }

    pub fn for_preference(pref: PreferredTheme) -> Self {
        match pref {
            PreferredTheme::Dark => Self::dark(),
            PreferredTheme::Light => Self::light(),
        }
    }

    pub fn for_theme_pref(pref: ThemePref, system: PreferredTheme) -> Self {
        match pref {
            ThemePref::Light => Self::light(),
            ThemePref::Dark => Self::dark(),
            ThemePref::System => Self::for_preference(system),
        }
    }
}
