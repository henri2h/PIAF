pub mod app;
pub mod logging;
pub mod ui;
pub mod utils;

#[cfg(target_os = "android")]
mod android;

pub use app::Route;
pub use app::state::*;

#[cfg(not(target_os = "android"))]
pub fn run_desktop() {
    use freya::prelude::*;
    #[cfg(feature = "perf-overlay")]
    use freya_metrics_plugin::MetricsPlugin;

    logging::init();

    let rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap();
    let _rt = rt.enter();

    let data_dir = dirs::data_dir().expect("no data_dir").join("piaf");
    app::state::init(data_dir);

    let launch_config =
        LaunchConfig::new().with_window(WindowConfig::new(app::app).with_size(500., 450.));

    #[cfg(feature = "perf-overlay")]
    let launch_config =
        launch_config.with_plugin(MetricsPlugin::default().with_visible_performance(true));

    launch(launch_config)
}
