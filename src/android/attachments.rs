//! The composer's attachment picker (`AttachmentPicker.kt`): gallery, camera
//! or file; the picked file comes back over JNI.

use std::sync::Mutex;

use futures::channel::oneshot;
use jni::JNIEnv;
use jni::objects::{JByteArray, JClass, JString, JValue};

use crate::utils::media::{AttachSource, PickedFile};
use crate::utils::push::{JAVA_VM, find_app_class};

/// The pick in progress: answered (or dropped by a newer pick) once.
static PENDING: Mutex<Option<oneshot::Sender<Option<PickedFile>>>> = Mutex::new(None);

fn answer(file: Option<PickedFile>) {
    if let Some(tx) = PENDING.lock().unwrap().take() {
        let _ = tx.send(file);
    }
}

/// Opens the picker; `None` when cancelled or unreadable.
pub async fn pick(source: AttachSource) -> Option<PickedFile> {
    let (tx, rx) = oneshot::channel();
    *PENDING.lock().unwrap() = Some(tx);
    let kind = match source {
        AttachSource::Gallery => 0,
        AttachSource::Camera => 1,
        AttachSource::File => 2,
    };
    let result = (|| -> jni::errors::Result<()> {
        let vm = JAVA_VM.get().ok_or(jni::errors::Error::NullPtr("JavaVM"))?;
        let mut env = vm.attach_current_thread()?;
        let class = find_app_class(&mut env, "dev/piaf/app/AttachmentPicker")
            .ok_or(jni::errors::Error::NullPtr("AttachmentPicker"))?;
        env.call_static_method(&class, "pick", "(I)V", &[JValue::Int(kind)])?;
        Ok(())
    })();
    if let Err(e) = result {
        tracing::warn!("AttachmentPicker.pick failed: {e}");
        answer(None);
    }
    rx.await.ok().flatten()
}

#[unsafe(no_mangle)]
pub extern "C" fn Java_dev_piaf_app_AttachmentPicker_nativePicked(
    mut env: JNIEnv,
    _class: JClass,
    name: JString,
    mime: JString,
    bytes: JByteArray,
) {
    let file = (|| {
        let name: String = env.get_string(&name).ok()?.into();
        let mime: String = env.get_string(&mime).ok()?.into();
        let bytes = env.convert_byte_array(&bytes).ok()?;
        Some(PickedFile {
            file_name: name,
            mime: mime.parse().unwrap_or(mime::APPLICATION_OCTET_STREAM),
            bytes,
        })
    })();
    answer(file);
}

#[unsafe(no_mangle)]
pub extern "C" fn Java_dev_piaf_app_AttachmentPicker_nativeCancelled(_env: JNIEnv, _class: JClass) {
    answer(None);
}
