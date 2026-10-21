//! The system share sheet (`ShareSheet.kt`).

use jni::objects::JValue;

use crate::utils::push::{JAVA_VM, find_app_class};

/// Shares `bytes` as a file named `name` of type `mime`.
pub fn share_file(name: &str, mime: &str, bytes: &[u8]) {
    let result = (|| -> jni::errors::Result<()> {
        let vm = JAVA_VM.get().ok_or(jni::errors::Error::NullPtr("JavaVM"))?;
        let mut env = vm.attach_current_thread()?;
        let class = find_app_class(&mut env, "dev/piaf/app/ShareSheet")
            .ok_or(jni::errors::Error::NullPtr("ShareSheet"))?;
        let name = env.new_string(name)?;
        let mime = env.new_string(mime)?;
        let bytes = env.byte_array_from_slice(bytes)?;
        env.call_static_method(
            &class,
            "share",
            "(Ljava/lang/String;Ljava/lang/String;[B)V",
            &[JValue::Object(&name), JValue::Object(&mime), JValue::Object(&bytes)],
        )?;
        Ok(())
    })();
    if let Err(e) = result {
        tracing::warn!("ShareSheet.share failed: {e}");
    }
}
