#[cfg(target_os = "android")]
mod android;
#[cfg(not(target_os = "android"))]
mod desktop;
#[cfg(target_os = "android")]
mod nav_bar;

#[derive(PartialEq)]
pub struct Layout;
