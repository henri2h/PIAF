pub mod attachments;
pub mod ime;
mod jni_push;
pub mod share;

use std::sync::OnceLock;

use freya::android::AndroidPlugin;
use freya::prelude::*;
#[cfg(feature = "perf-overlay")]
use freya_metrics_plugin::MetricsPlugin;
use winit::platform::android::activity::AndroidApp;
use winit::{event_loop::EventLoop, platform::android::EventLoopBuilderExtAndroid};

use crate::utils::push::{ANDROID_APP_CONTEXT, APP_CLASS_LOADER, JAVA_VM};

static RUNTIME: OnceLock<tokio::runtime::Runtime> = OnceLock::new();

/// The process' tokio runtime, shared by the activity and JNI push calls (app
/// killed). Never dropped: the process outlives an activity, and a new one
/// (`android_main` again) must find the client, sync and worker still running.
pub fn runtime() -> &'static tokio::runtime::Runtime {
    RUNTIME.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .worker_threads(crate::TOKIO_WORKERS)
            .enable_all()
            .build()
            .expect("Failed to build tokio runtime")
    })
}

#[unsafe(no_mangle)]
fn android_main(droid_app: AndroidApp) {
    // Panics in logcat come with a backtrace (nothing else sets the env here).
    // SAFETY: first thing in the process' main, before any other thread starts.
    unsafe { std::env::set_var("RUST_BACKTRACE", "1") };
    crate::logging::init();

    let data_path = droid_app
        .internal_data_path()
        .expect("No internal data path on Android");

    cache_jni_globals(&droid_app);
    init_tls_verifier(&droid_app);

    // Kept entered for the app lifetime: freya calls `tokio::spawn` internally.
    let _rt_guard = runtime().enter();
    crate::app::state::init(data_path);

    let event_loop = match EventLoop::<NativeEvent>::with_user_event()
        .with_android_app(droid_app.clone())
        .build()
    {
        Ok(event_loop) => event_loop,
        // winit builds one event loop per process: a new activity in a process
        // that already ran one (e.g. after a panic) can only start fresh.
        Err(winit::error::EventLoopError::RecreationAttempt) => {
            tracing::warn!("event loop already used in this process: restarting");
            crate::app::restart::restart()
        }
        Err(e) => panic!("Failed to build event loop: {e}"),
    };

    let launch_config = LaunchConfig::new()
        .with_plugin(AndroidPlugin::new(droid_app))
        .with_window(WindowConfig::new(crate::app::app))
        .with_event_loop(event_loop);

    #[cfg(feature = "perf-overlay")]
    let launch_config =
        launch_config.with_plugin(MetricsPlugin::default().with_visible_performance(true));

    launch(launch_config)
}

/// HTTPS (reqwest, rustls-platform-verifier) checks certificates against
/// Android's trust store through JNI: without this every request panics.
fn init_tls_verifier(droid_app: &AndroidApp) {
    init_tls_verifier_raw(droid_app.vm_as_ptr(), droid_app.activity_as_ptr());
}

/// `init_tls_verifier` from raw JNI pointers: also run by the push path, where
/// no activity (nor `android_main`) exists. A no-op once initialised.
pub(crate) fn init_tls_verifier_raw(vm: *mut std::ffi::c_void, context: *mut std::ffi::c_void) {
    // SAFETY: the VM and context pointers come from the running app.
    let vm = unsafe { jni22::JavaVM::from_raw(vm as *mut jni22::sys::JavaVM) };
    let result = vm.attach_current_thread(|env| -> Result<(), jni22::errors::Error> {
        let context =
            unsafe { jni22::objects::JObject::from_raw(env, context as jni22::sys::jobject) };
        rustls_platform_verifier::android::init_with_env(env, context)
    });
    if let Err(e) = result {
        tracing::error!("TLS verifier init failed: {e}");
    }
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
