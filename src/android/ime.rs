//! The soft keyboard's editor (`ImeInput.kt`): what the keyboard types arrives
//! here over JNI and is queued for the focused composer; the composer shows,
//! hides and re-syncs the keyboard.

use std::collections::VecDeque;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Mutex, OnceLock};

use jni::JNIEnv;
use jni::objects::{JClass, JString, JValue};
use jni::sys::jint;
use tokio::sync::watch;

use crate::utils::ime::{ImeEvent, ImeKind};
use crate::utils::push::{JAVA_VM, find_app_class};

static QUEUE: Mutex<VecDeque<ImeEvent>> = Mutex::new(VecDeque::new());
/// Bumped for each queued event: the composer drains the queue on change.
static TICK: OnceLock<watch::Sender<u64>> = OnceLock::new();

fn tick() -> &'static watch::Sender<u64> {
    TICK.get_or_init(|| watch::channel(0).0)
}

pub fn events() -> watch::Receiver<u64> {
    tick().subscribe()
}

pub fn drain() -> Vec<ImeEvent> {
    QUEUE.lock().unwrap().drain(..).collect()
}

fn push(event: ImeEvent) {
    tracing::debug!(target: "piaf::composer", kind = event.kind(), "ime event");
    QUEUE.lock().unwrap().push_back(event);
    tick().send_modify(|n| *n += 1);
}

fn read(env: &mut JNIEnv, text: &JString) -> Option<String> {
    env.get_string(text).ok().map(String::from)
}

#[unsafe(no_mangle)]
pub extern "C" fn Java_dev_piaf_app_ImeBridge_nativeImeCommit(
    mut env: JNIEnv,
    _class: JClass,
    text: JString,
) {
    if let Some(text) = read(&mut env, &text) {
        push(ImeEvent::Commit(text));
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn Java_dev_piaf_app_ImeBridge_nativeImePreedit(
    mut env: JNIEnv,
    _class: JClass,
    text: JString,
) {
    if let Some(text) = read(&mut env, &text) {
        push(ImeEvent::Preedit(text));
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn Java_dev_piaf_app_ImeBridge_nativeImeDelete(
    _env: JNIEnv,
    _class: JClass,
    before: jint,
    after: jint,
) {
    push(ImeEvent::Delete {
        before: before.max(0) as usize,
        after: after.max(0) as usize,
    });
}

#[unsafe(no_mangle)]
pub extern "C" fn Java_dev_piaf_app_ImeBridge_nativeImeComposingRegion(
    _env: JNIEnv,
    _class: JClass,
    start: jint,
    end: jint,
) {
    push(ImeEvent::ComposingRegion {
        start: start.max(0) as usize,
        end: end.max(0) as usize,
    });
}

#[unsafe(no_mangle)]
pub extern "C" fn Java_dev_piaf_app_ImeBridge_nativeImeSelect(
    _env: JNIEnv,
    _class: JClass,
    start: jint,
    end: jint,
) {
    push(ImeEvent::Select {
        start: start.max(0) as usize,
        end: end.max(0) as usize,
    });
}

#[unsafe(no_mangle)]
pub extern "C" fn Java_dev_piaf_app_ImeBridge_nativeImeAction(_env: JNIEnv, _class: JClass) {
    push(ImeEvent::Action);
}

/// Arguments of an `ImeBridge` call.
enum BridgeArgs<'a> {
    None,
    Text(&'a str, usize),
    /// `show`: text, cursor and whether it's the search field.
    Show(&'a str, usize, bool),
}

/// Calls `ImeBridge.<method>`; logged on failure.
fn call_bridge(method: &str, args: BridgeArgs) {
    let result = (|| -> jni::errors::Result<()> {
        let vm = JAVA_VM.get().ok_or(jni::errors::Error::NullPtr("JavaVM"))?;
        let mut env = vm.attach_current_thread()?;
        let class = find_app_class(&mut env, "dev/piaf/app/ImeBridge")
            .ok_or(jni::errors::Error::NullPtr("ImeBridge"))?;
        match args {
            BridgeArgs::Text(text, cursor) => {
                let text = env.new_string(text)?;
                env.call_static_method(
                    &class,
                    method,
                    "(Ljava/lang/String;I)V",
                    &[JValue::Object(&text), JValue::Int(cursor as jint)],
                )?;
            }
            BridgeArgs::Show(text, cursor, search) => {
                let text = env.new_string(text)?;
                env.call_static_method(
                    &class,
                    method,
                    "(Ljava/lang/String;IZ)V",
                    &[
                        JValue::Object(&text),
                        JValue::Int(cursor as jint),
                        JValue::Bool(search.into()),
                    ],
                )?;
            }
            BridgeArgs::None => {
                env.call_static_method(&class, method, "()V", &[])?;
            }
        }
        Ok(())
    })();
    if let Err(e) = result {
        tracing::warn!(target: "piaf::composer", "ImeBridge.{method} failed: {e}");
    }
}

/// The composer the keyboard was last shown for.
static OWNER: AtomicU64 = AtomicU64::new(0);

/// Shows the keyboard on `text`; returns the owner token for [`hide`].
/// Events still queued were typed elsewhere: dropped.
pub fn show(text: &str, cursor: usize, kind: ImeKind) -> u64 {
    drain();
    let owner = OWNER.fetch_add(1, Ordering::Relaxed) + 1;
    call_bridge(
        "show",
        BridgeArgs::Show(text, cursor, kind == ImeKind::Search),
    );
    owner
}

/// Hides the keyboard, unless another composer showed it since `owner`'s show.
pub fn hide(owner: u64) {
    if OWNER.load(Ordering::Relaxed) == owner {
        call_bridge("hide", BridgeArgs::None);
    }
}

pub fn sync(text: &str, cursor: usize) {
    call_bridge("sync", BridgeArgs::Text(text, cursor));
}
