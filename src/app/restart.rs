//! Relaunching the app, used to sign in again after the session is gone:
//! `CLIENT` is set once per process, so a new login needs a new process.

/// Starts a new instance with the same arguments, then exits this one.
#[cfg(not(target_os = "android"))]
pub fn restart() -> ! {
    match std::env::current_exe() {
        Ok(exe) => {
            let args: Vec<_> = std::env::args_os().skip(1).collect();
            if let Err(e) = std::process::Command::new(exe).args(args).spawn() {
                tracing::error!("restart: could not spawn new instance: {e}");
            }
        }
        Err(e) => tracing::error!("restart: current_exe unavailable: {e}"),
    }
    std::process::exit(0)
}

/// Relaunches the launcher activity in a fresh task, then exits this process.
/// Falls back to a plain exit (the user reopens the app) if JNI fails.
#[cfg(target_os = "android")]
pub fn restart() -> ! {
    if let Err(e) = relaunch_activity() {
        tracing::error!("restart: could not relaunch activity: {e}");
    }
    std::process::exit(0)
}

#[cfg(target_os = "android")]
fn relaunch_activity() -> jni::errors::Result<()> {
    use crate::utils::push::{ANDROID_APP_CONTEXT, JAVA_VM};
    use jni::objects::{JObject, JValue};

    const FLAG_ACTIVITY_NEW_TASK: i32 = 0x1000_0000;
    const FLAG_ACTIVITY_CLEAR_TASK: i32 = 0x0000_8000;

    let (Some(vm), Some(ctx)) = (JAVA_VM.get(), ANDROID_APP_CONTEXT.get()) else {
        return Err(jni::errors::Error::NullPtr("JavaVM or app context not cached"));
    };
    let mut env = vm.attach_current_thread()?;
    let ctx = ctx.as_obj();

    let package = env
        .call_method(ctx, "getPackageName", "()Ljava/lang/String;", &[])?
        .l()?;
    let pm = env
        .call_method(
            ctx,
            "getPackageManager",
            "()Landroid/content/pm/PackageManager;",
            &[],
        )?
        .l()?;
    let intent = env
        .call_method(
            &pm,
            "getLaunchIntentForPackage",
            "(Ljava/lang/String;)Landroid/content/Intent;",
            &[JValue::Object(&package)],
        )?
        .l()?;
    if intent.is_null() {
        return Err(jni::errors::Error::NullPtr("no launch intent"));
    }
    env.call_method(
        &intent,
        "addFlags",
        "(I)Landroid/content/Intent;",
        &[JValue::Int(FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_CLEAR_TASK)],
    )?;
    env.call_method(
        ctx,
        "startActivity",
        "(Landroid/content/Intent;)V",
        &[JValue::Object(&JObject::from(intent))],
    )?;
    Ok(())
}
