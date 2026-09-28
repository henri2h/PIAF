#[cfg(not(target_os = "android"))]
mod active_room_panel;
mod layout;
pub mod navigation;
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
