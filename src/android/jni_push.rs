use jni::{
    JNIEnv,
    objects::{JClass, JString},
};
use matrix_sdk::ruma::exports::serde_json;

/// Initialise the Rust SDK in a push-notification context (app killed).
///
/// Spins up a Tokio runtime (if not already running) and restores the Matrix
/// client from the persisted session so all enrichment JNI functions work,
/// including decryption of E2E events.  Safe to call repeatedly — subsequent
/// calls are no-ops when already initialised.
///
/// Returns 1 on success, 0 on failure.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeInitForPush(
    mut env: JNIEnv,
    _class: JClass,
    data_dir: JString,
) -> jni::sys::jboolean {
    if super::TOKIO_HANDLE.get().is_some() && crate::utils::matrix::CLIENT.get().is_some() {
        return 1;
    }

    let data_dir_str: String = match env.get_string(&data_dir) {
        Ok(s) => s.into(),
        Err(_) => return 0,
    };

    if super::TOKIO_HANDLE.get().is_none() {
        // Push enrichment only: a couple of workers is plenty.
        let rt = match tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .enable_all()
            .build()
        {
            Ok(r) => r,
            Err(_) => return 0,
        };
        let _ = super::TOKIO_HANDLE.set(rt.handle().clone());
        let _ = super::PUSH_RT.set(rt);
    }

    let handle = match super::TOKIO_HANDLE.get() {
        Some(h) => h,
        None => return 0,
    };

    let base_dir = std::path::PathBuf::from(data_dir_str);
    let ok = handle.block_on(async move {
        crate::utils::matrix::restore_matrix_client(base_dir)
            .await
            .unwrap_or(false)
    });

    ok as jni::sys::jboolean
}

/// Called by Kotlin PushReceiver when a new UP endpoint is assigned.
/// Persists the endpoint and, if the Matrix client is available, registers
/// the HTTP pusher with the homeserver immediately.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeEndpointChanged(
    mut env: JNIEnv,
    _class: JClass,
    endpoint: JString,
) {
    let endpoint: String = match env.get_string(&endpoint) {
        Ok(s) => s.into(),
        Err(_) => return,
    };

    let handle = match super::TOKIO_HANDLE.get() {
        Some(h) => h,
        None => return,
    };

    if let Some(data_dir) = crate::utils::matrix::DATA_DIR.get() {
        let base_dir = data_dir.parent().unwrap_or(data_dir).to_path_buf();
        let endpoint_clone = endpoint.clone();
        handle.spawn(async move {
            crate::utils::push::persist_endpoint(&base_dir, &endpoint_clone).await;
        });
    }

    if let Some(client) = crate::utils::matrix::CLIENT.get() {
        let client = client.clone();
        handle.spawn(async move {
            crate::utils::push::register_pusher(&client, &endpoint).await;
        });
    }
}

/// Called by Kotlin PushReceiver to look up a room's display name from the
/// local Matrix store. Returns null if the room is unknown or the client is
/// not loaded. Blocks the calling Java thread for the duration of the lookup.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchRoomName(
    mut env: JNIEnv,
    _class: JClass,
    room_id: JString,
) -> jni::sys::jstring {
    let room_id_str: String = match env.get_string(&room_id) {
        Ok(s) => s.into(),
        Err(_) => return std::ptr::null_mut(),
    };
    let handle = match super::TOKIO_HANDLE.get() {
        Some(h) => h,
        None => return std::ptr::null_mut(),
    };
    let client = match crate::utils::matrix::CLIENT.get() {
        Some(c) => c.clone(),
        None => return std::ptr::null_mut(),
    };
    let name: Option<String> = handle.block_on(async move {
        use matrix_sdk::ruma::RoomId;
        let room_id = RoomId::parse(&room_id_str).ok()?;
        let room = client.get_room(&room_id)?;
        let dn = room.display_name().await.ok()?;
        Some(dn.to_string())
    });
    match name {
        Some(n) => env
            .new_string(n)
            .map(|s| s.into_raw())
            .unwrap_or(std::ptr::null_mut()),
        None => std::ptr::null_mut(),
    }
}

/// Fetch enriched notification payload (room name, sender, message body).
/// Returns a JSON string `{"roomName":..,"senderName":..,"body":..}` or null.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchNotificationPayload(
    mut env: JNIEnv,
    _class: JClass,
    room_id: JString,
    event_id: JString,
) -> jni::sys::jstring {
    let room_id_str: String = match env.get_string(&room_id) {
        Ok(s) => s.into(),
        Err(_) => return std::ptr::null_mut(),
    };
    let event_id_str: String = match env.get_string(&event_id) {
        Ok(s) => s.into(),
        Err(_) => return std::ptr::null_mut(),
    };
    let handle = match super::TOKIO_HANDLE.get() {
        Some(h) => h,
        None => return std::ptr::null_mut(),
    };
    let client = match crate::utils::matrix::CLIENT.get() {
        Some(c) => c.clone(),
        None => return std::ptr::null_mut(),
    };
    let payload = handle.block_on(async move {
        crate::utils::push::fetch_notification_payload(&client, &room_id_str, &event_id_str).await
    });
    match payload {
        Some(p) => {
            let json = format!(
                r#"{{"roomName":{},"senderId":{},"senderName":{},"body":{},"isImage":{}}}"#,
                serde_json::Value::String(p.room_name),
                serde_json::Value::String(p.sender_id),
                serde_json::Value::String(p.sender_display_name),
                serde_json::Value::String(p.body),
                p.is_image,
            );
            env.new_string(json)
                .map(|s| s.into_raw())
                .unwrap_or(std::ptr::null_mut())
        }
        None => std::ptr::null_mut(),
    }
}

/// Fetch the sender's avatar bytes for a notification (identified by room + user ID).
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchSenderAvatarBytes(
    mut env: JNIEnv,
    _class: JClass,
    room_id: JString,
    sender_id: JString,
) -> jni::sys::jbyteArray {
    let room_id_str: String = match env.get_string(&room_id) {
        Ok(s) => s.into(),
        Err(_) => return std::ptr::null_mut(),
    };
    let sender_id_str: String = match env.get_string(&sender_id) {
        Ok(s) => s.into(),
        Err(_) => return std::ptr::null_mut(),
    };
    let handle = match super::TOKIO_HANDLE.get() {
        Some(h) => h,
        None => return std::ptr::null_mut(),
    };
    let client = match crate::utils::matrix::CLIENT.get() {
        Some(c) => c.clone(),
        None => return std::ptr::null_mut(),
    };
    let bytes = handle.block_on(async move {
        crate::utils::push::fetch_sender_avatar(&client, &room_id_str, &sender_id_str).await
    });
    match bytes {
        Some(b) => env
            .byte_array_from_slice(&b)
            .map(|a| a.into_raw())
            .unwrap_or(std::ptr::null_mut()),
        None => std::ptr::null_mut(),
    }
}

/// Fetch the image bytes for an image message event (notification thumbnail).
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchEventImageBytes(
    mut env: JNIEnv,
    _class: JClass,
    room_id: JString,
    event_id: JString,
) -> jni::sys::jbyteArray {
    let room_id_str: String = match env.get_string(&room_id) {
        Ok(s) => s.into(),
        Err(_) => return std::ptr::null_mut(),
    };
    let event_id_str: String = match env.get_string(&event_id) {
        Ok(s) => s.into(),
        Err(_) => return std::ptr::null_mut(),
    };
    let handle = match super::TOKIO_HANDLE.get() {
        Some(h) => h,
        None => return std::ptr::null_mut(),
    };
    let client = match crate::utils::matrix::CLIENT.get() {
        Some(c) => c.clone(),
        None => return std::ptr::null_mut(),
    };
    let bytes = handle.block_on(async move {
        crate::utils::push::fetch_event_image(&client, &room_id_str, &event_id_str).await
    });
    match bytes {
        Some(b) => env
            .byte_array_from_slice(&b)
            .map(|a| a.into_raw())
            .unwrap_or(std::ptr::null_mut()),
        None => std::ptr::null_mut(),
    }
}

/// Fetch room avatar bytes for the notification large icon. Returns null if unavailable.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeFetchRoomAvatarBytes(
    mut env: JNIEnv,
    _class: JClass,
    room_id: JString,
) -> jni::sys::jbyteArray {
    let room_id_str: String = match env.get_string(&room_id) {
        Ok(s) => s.into(),
        Err(_) => return std::ptr::null_mut(),
    };
    let handle = match super::TOKIO_HANDLE.get() {
        Some(h) => h,
        None => return std::ptr::null_mut(),
    };
    let client = match crate::utils::matrix::CLIENT.get() {
        Some(c) => c.clone(),
        None => return std::ptr::null_mut(),
    };
    let bytes = handle.block_on(async move {
        crate::utils::push::fetch_room_avatar(&client, &room_id_str).await
    });
    match bytes {
        Some(b) => env
            .byte_array_from_slice(&b)
            .map(|a| a.into_raw())
            .unwrap_or(std::ptr::null_mut()),
        None => std::ptr::null_mut(),
    }
}

/// Returns a JSON array of room IDs whose notifications should be dismissed.
/// Input is a JSON array of {roomId, ts} objects (ts = notification display time in ms).
/// A room is considered read if the user's read receipt post-dates the notification timestamp.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeGetReadRooms(
    mut env: JNIEnv,
    _class: JClass,
    room_ids_json: JString,
) -> jni::sys::jstring {
    macro_rules! empty {
        () => {
            env.new_string("[]")
                .map(|s| s.into_raw())
                .unwrap_or(std::ptr::null_mut())
        };
    }
    let json_str: String = match env.get_string(&room_ids_json) {
        Ok(s) => s.into(),
        Err(_) => return empty!(),
    };
    let entries: Vec<(String, u64)> = {
        let arr: Vec<serde_json::Value> = serde_json::from_str(&json_str).unwrap_or_default();
        arr.into_iter()
            .filter_map(|v| {
                let room_id = v.get("roomId")?.as_str()?.to_string();
                let ts = v.get("ts")?.as_u64().unwrap_or(0);
                Some((room_id, ts))
            })
            .collect()
    };
    let handle = match super::TOKIO_HANDLE.get() {
        Some(h) => h,
        None => return empty!(),
    };
    let client = match crate::utils::matrix::CLIENT.get() {
        Some(c) => c.clone(),
        None => return empty!(),
    };
    let read_rooms =
        handle.block_on(async move { crate::utils::push::get_read_rooms(&client, entries).await });
    let result = serde_json::to_string(&read_rooms).unwrap_or_else(|_| "[]".to_string());
    env.new_string(result)
        .map(|s| s.into_raw())
        .unwrap_or(std::ptr::null_mut())
}

/// Called by Kotlin PushReceiver when the UP registration is revoked.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn Java_dev_piaf_app_PushReceiver_00024NativeBridge_nativeEndpointCleared(
    _env: JNIEnv,
    _class: JClass,
) {
    let handle = match super::TOKIO_HANDLE.get() {
        Some(h) => h,
        None => return,
    };

    if let Some(data_dir) = crate::utils::matrix::DATA_DIR.get() {
        let base_dir = data_dir.parent().unwrap_or(data_dir).to_path_buf();
        let client = crate::utils::matrix::CLIENT.get().cloned();
        handle.spawn(async move {
            if let Some(client) = client {
                crate::utils::push::unregister_pusher(&client, &base_dir).await;
            } else {
                crate::utils::push::clear_endpoint(&base_dir).await;
            }
        });
    }
}
