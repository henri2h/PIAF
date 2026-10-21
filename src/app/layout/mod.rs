#[cfg(target_os = "android")]
mod android;
#[cfg(target_os = "android")]
mod nav_bar;
#[cfg(not(target_os = "android"))]
mod desktop;

#[derive(PartialEq)]
pub struct Layout;
