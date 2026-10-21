//! System clipboard: images (desktop), and the text clipboard Freya's editors
//! use on Android (copypasta has none there).

#[cfg(not(target_os = "android"))]
/// Encode raw RGBA pixels to a PNG byte vector.
fn encode_rgba_to_png(width: u32, height: u32, rgba: &[u8]) -> Option<Vec<u8>> {
    let mut buf = Vec::new();
    let mut enc = png::Encoder::new(&mut buf, width, height);
    enc.set_color(png::ColorType::Rgba);
    enc.set_depth(png::BitDepth::Eight);
    let mut writer = enc.write_header().ok()?;
    writer.write_image_data(rgba).ok()?;
    drop(writer);
    Some(buf)
}

#[cfg(not(target_os = "android"))]
/// The image on the system clipboard, as PNG.
/// Returns PNG bytes on success, `None` if clipboard has no image.
/// Safe to call from the UI/main thread.
pub fn read_image() -> Option<Vec<u8>> {
    let mut cb = arboard::Clipboard::new().ok()?;
    let img = cb.get_image().ok()?;
    encode_rgba_to_png(img.width as u32, img.height as u32, &img.bytes)
}

/// Gives Freya's clipboard (`Clipboard::get`/`set`, editor copy / cut / paste)
/// Android's `ClipboardManager`. Call once from the root component.
#[cfg(target_os = "android")]
pub fn install() {
    use freya::clipboard::Clipboard;
    freya::prelude::GlobalContexts::get()
        .insert_context(Clipboard::create(Some(Box::new(android::AndroidClipboard))));
}

#[cfg(target_os = "android")]
mod android {
    use jni::JNIEnv;
    use jni::objects::{JObject, JValue};

    use crate::utils::push::{ANDROID_APP_CONTEXT, JAVA_VM};

    type Result<T> = std::result::Result<T, Box<dyn std::error::Error + Send + Sync>>;

    pub struct AndroidClipboard;

    impl copypasta::ClipboardProvider for AndroidClipboard {
        fn get_contents(&mut self) -> Result<String> {
            with_env(|env, ctx, manager| {
                let clip = env
                    .call_method(manager, "getPrimaryClip", "()Landroid/content/ClipData;", &[])?
                    .l()?;
                if clip.is_null() {
                    return Ok(String::new());
                }
                let item = env
                    .call_method(&clip, "getItemAt", "(I)Landroid/content/ClipData$Item;", &[JValue::Int(0)])?
                    .l()?;
                let text = env
                    .call_method(
                        &item,
                        "coerceToText",
                        "(Landroid/content/Context;)Ljava/lang/CharSequence;",
                        &[JValue::Object(ctx)],
                    )?
                    .l()?;
                let text = env.call_method(&text, "toString", "()Ljava/lang/String;", &[])?.l()?;
                Ok(env.get_string(&text.into())?.into())
            })
        }

        fn set_contents(&mut self, contents: String) -> Result<()> {
            with_env(|env, _, manager| {
                let label = env.new_string("")?;
                let text = env.new_string(contents)?;
                let clip = env
                    .call_static_method(
                        "android/content/ClipData",
                        "newPlainText",
                        "(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Landroid/content/ClipData;",
                        &[JValue::Object(&label), JValue::Object(&text)],
                    )?
                    .l()?;
                env.call_method(
                    manager,
                    "setPrimaryClip",
                    "(Landroid/content/ClipData;)V",
                    &[JValue::Object(&clip)],
                )?;
                Ok(())
            })
        }
    }

    /// Runs `f` with the app context and its `ClipboardManager`.
    fn with_env<T>(
        f: impl FnOnce(&mut JNIEnv, &JObject, &JObject) -> jni::errors::Result<T>,
    ) -> Result<T> {
        let vm = JAVA_VM.get().ok_or("no JavaVM")?;
        let ctx = ANDROID_APP_CONTEXT.get().ok_or("no app context")?;
        let mut env = vm.attach_current_thread()?;
        let result = (|| {
            let name = env.new_string("clipboard")?;
            let manager = env
                .call_method(
                    ctx.as_obj(),
                    "getSystemService",
                    "(Ljava/lang/String;)Ljava/lang/Object;",
                    &[JValue::Object(&name)],
                )?
                .l()?;
            f(&mut env, ctx.as_obj(), &manager)
        })();
        if result.is_err() && env.exception_check().unwrap_or(false) {
            let _ = env.exception_clear();
        }
        Ok(result?)
    }
}
