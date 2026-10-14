//! Room row gestures. Both platforms expose the same API:
//! `use_row_interaction()`, `is_highlighted()`, `feedback()`, `attach()`.

#[cfg(target_os = "android")]
mod android;
#[cfg(not(target_os = "android"))]
mod desktop;

/// Opens the row's context menu; `true` when triggered by a pointer down.
pub type OnMenu = std::rc::Rc<dyn Fn(bool)>;

#[cfg(target_os = "android")]
pub use android::use_row_interaction;
#[cfg(not(target_os = "android"))]
pub use desktop::use_row_interaction;
