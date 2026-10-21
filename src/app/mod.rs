#[cfg(not(target_os = "android"))]
mod active_room_panel;
pub mod keys;
mod layout;
pub mod navigation;
#[cfg(any(target_os = "android", test))]
#[cfg_attr(not(target_os = "android"), allow(dead_code))]
mod page_transition;
pub mod restart;
mod routes;
pub mod state;
pub mod theme;

use freya::prelude::*;
use freya_router::prelude::{Router, RouterConfig};

pub use routes::Route;

pub fn app() -> impl IntoElement {
    Router::<Route>::new(|| RouterConfig::default().with_initial_path(Route::WelcomePage))
}
