mod jni_push;

use std::sync::OnceLock;

use freya::android::AndroidPlugin;
use freya::prelude::*;
#[cfg(feature = "perf-overlay")]
use freya_metrics_plugin::MetricsPlugin;
use winit::platform::android::activity::AndroidApp;
use winit::{event_loop::EventLoop, platform::android::EventLoopBuilderExtAndroid};

use crate::utils::push::{ANDROID_APP_CONTEXT, APP_CLASS_LOADER, JAVA_VM};

pub static TOKIO_HANDLE: OnceLock<tokio::runtime::Handle> = OnceLock::new();
/// Runtime created by JNI push calls while the app is killed; kept alive for `TOKIO_HANDLE`.
pub static PUSH_RT: OnceLock<tokio::runtime::Runtime> = OnceLock::new();

#[unsafe(no_mangle)]
fn android_main(droid_app: AndroidApp) {
    crate::logging::init();

    let data_path = droid_app
        .internal_data_path()
        .expect("No internal data path on Android");

    let rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("Failed to build tokio runtime");
    let _ = TOKIO_HANDLE.set(rt.handle().clone());

    cache_jni_globals(&droid_app);

    // Kept entered for the app lifetime: freya calls `tokio::spawn` internally.
    let _rt_guard = rt.enter();
    crate::app::state::init(data_path);

    let event_loop = EventLoop::<NativeEvent>::with_user_event()
        .with_android_app(droid_app.clone())
        .build()
        .expect("Failed to build event loop");

    let launch_config = LaunchConfig::new()
        .with_plugin(AndroidPlugin::new(droid_app))
        .with_window(WindowConfig::new(crate::app::app))
        .with_event_loop(event_loop);

    #[cfg(feature = "perf-overlay")]
    let launch_config =
        launch_config.with_plugin(MetricsPlugin::default().with_visible_performance(true));

    launch(launch_config)
}

/// Caches JavaVM, app context and class loader so background threads can call
/// into Java (e.g. dismiss notifications) without a Kotlin callback.
fn cache_jni_globals(droid_app: &AndroidApp) {
    let vm_ptr = droid_app.vm_as_ptr() as *mut jni::sys::JavaVM;
    let Ok(vm) = (unsafe { jni::JavaVM::from_raw(vm_ptr) }) else {
        return;
    };
    if let Ok(mut env) = vm.attach_current_thread() {
        let activity = unsafe {
            jni::objects::JObject::from_raw(droid_app.activity_as_ptr() as jni::sys::jobject)
        };
        let ctx_obj = env
            .call_method(
                &activity,
                "getApplicationContext",
                "()Landroid/content/Context;",
                &[],
            )
            .and_then(|v| v.l());
        if let Ok(ctx_obj) = ctx_obj {
            let loader = env
                .call_method(&ctx_obj, "getClassLoader", "()Ljava/lang/ClassLoader;", &[])
                .and_then(|v| v.l())
                .and_then(|obj| env.new_global_ref(obj));
            if let Ok(global) = loader {
                let _ = APP_CLASS_LOADER.set(global);
            }
            if let Ok(global) = env.new_global_ref(&ctx_obj) {
                let _ = ANDROID_APP_CONTEXT.set(global);
            }
        }
    }
    let _ = JAVA_VM.set(vm);
}
