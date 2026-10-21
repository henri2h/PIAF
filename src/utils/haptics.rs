//! Haptic feedback through Android's predefined vibration effects. No-op elsewhere.

/// `android.os.VibrationEffect` predefined effect ids.
#[derive(Clone, Copy)]
#[cfg_attr(not(target_os = "android"), allow(dead_code))]
pub enum Haptic {
    /// Light tap: navigation.
    Click = 0,
    /// Faint tick: a swipe passing its commit point.
    Tick = 2,
    /// Strong tap: a long press recognized.
    HeavyClick = 5,
}

/// Plays `haptic` off the UI thread (JNI + binder call).
pub fn play(haptic: Haptic) {
    #[cfg(target_os = "android")]
    {
        tokio::task::spawn_blocking(move || android::play(haptic));
    }
    #[cfg(not(target_os = "android"))]
    let _ = haptic;
}

#[cfg(target_os = "android")]
mod android {
    use std::sync::OnceLock;

    use jni::JNIEnv;
    use jni::objects::{GlobalRef, JValue};

    use super::Haptic;
    use crate::utils::push::{ANDROID_APP_CONTEXT, JAVA_VM};

    static VIBRATOR: OnceLock<Option<GlobalRef>> = OnceLock::new();

    pub fn play(haptic: Haptic) {
        let Some(vm) = JAVA_VM.get() else {
            return;
        };
        let Ok(mut env) = vm.attach_current_thread() else {
            return;
        };
        if let Err(e) = vibrate(&mut env, haptic) {
            if env.exception_check().unwrap_or(false) {
                let _ = env.exception_clear();
            }
            tracing::debug!("haptic feedback failed: {e}");
        }
    }

    fn vibrate(env: &mut JNIEnv, haptic: Haptic) -> jni::errors::Result<()> {
        let vibrator = VIBRATOR.get_or_init(|| default_vibrator(env).ok());
        let Some(vibrator) = vibrator else {
            return Ok(());
        };
        let effect = env
            .call_static_method(
                "android/os/VibrationEffect",
                "createPredefined",
                "(I)Landroid/os/VibrationEffect;",
                &[JValue::Int(haptic as i32)],
            )?
            .l()?;
        env.call_method(
            vibrator.as_obj(),
            "vibrate",
            "(Landroid/os/VibrationEffect;)V",
            &[(&effect).into()],
        )?;
        Ok(())
    }

    fn default_vibrator(env: &mut JNIEnv) -> jni::errors::Result<GlobalRef> {
        let ctx = ANDROID_APP_CONTEXT
            .get()
            .ok_or(jni::errors::Error::NullPtr("app context"))?;
        let name = env.new_string("vibrator_manager")?;
        let manager = env
            .call_method(
                ctx.as_obj(),
                "getSystemService",
                "(Ljava/lang/String;)Ljava/lang/Object;",
                &[(&name).into()],
            )?
            .l()?;
        let vibrator = env
            .call_method(&manager, "getDefaultVibrator", "()Landroid/os/Vibrator;", &[])?
            .l()?;
        env.new_global_ref(vibrator)
    }
}
