package dev.piaf.app

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.core.content.FileProvider
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import org.unifiedpush.android.connector.PushService
import org.unifiedpush.android.connector.data.PushEndpoint
import org.unifiedpush.android.connector.data.PushMessage
import org.unifiedpush.android.connector.FailedReason
import java.io.File

class PushReceiver : PushService() {

    override fun onNewEndpoint(endpoint: PushEndpoint, instance: String) {
        val url = endpoint.url
        File(filesDir, ENDPOINT_FILE).writeText(url)

        // Resolve the push gateway from the endpoint URL.
        // For self-hosted distributors (ntfy, etc.) the gateway lives at
        // scheme://host/_matrix/push/v1/notify on the same server.
        val gateway = resolveGateway(url)
        File(filesDir, GATEWAY_FILE).writeText(gateway)

        if (NativeBridge.tryLoad()) {
            NativeBridge.nativeEndpointChanged(url)
        }
    }

    override fun onUnregistered(instance: String) {
        File(filesDir, ENDPOINT_FILE).delete()
        File(filesDir, GATEWAY_FILE).delete()

        if (NativeBridge.tryLoad()) {
            NativeBridge.nativeEndpointCleared()
        }
    }

    override fun onMessage(message: PushMessage, instance: String) {
        val rawJson = message.content.toString(Charsets.UTF_8)
        Log.d(TAG, "onMessage raw JSON: $rawJson")

        ensureNotificationChannel()
        val push = parsePush(message.content) ?: run {
            Log.d(TAG, "onMessage: parsePush returned null, ignoring")
            return
        }
        Log.d(TAG, "onMessage: roomId=${push.roomId} eventId=${push.eventId} isClear=${push.isClear}")

        if (push.isClear) {
            Log.d(TAG, "onMessage: clear push — dismissing notification for ${push.roomId}")
            cancelNotificationsForRooms(this, JSONArray(listOf(push.roomId)).toString())
            return
        }

        if (push.eventId != null) {
            showEnrichedNotification(push.roomId, push.eventId)
        }
    }

    override fun onRegistrationFailed(reason: FailedReason, instance: String) {
        // Nothing to do — registration will be retried on next app launch
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    /**
     * Resolve the Matrix push gateway for a UP endpoint URL.
     *
     * Self-hosted ntfy and similar distributors expose a Matrix push gateway at
     * scheme://host/_matrix/push/v1/notify on the same origin. We probe that URL
     * with a GET request: a real Matrix gateway returns 200 or 405; anything else
     * (e.g. Mozilla's push service returns 404) means we fall back to the
     * well-known default gateway.
     */
    private fun resolveGateway(endpointUrl: String): String {
        val derived = try {
            val uri = java.net.URI(endpointUrl)
            val port = if (uri.port != -1) ":${uri.port}" else ""
            "${uri.scheme}://${uri.host}${port}/_matrix/push/v1/notify"
        } catch (_: Exception) {
            return DEFAULT_GATEWAY
        }
        return try {
            val conn = java.net.URL(derived).openConnection() as java.net.HttpURLConnection
            conn.connectTimeout = 5_000
            conn.readTimeout = 5_000
            conn.requestMethod = "GET"
            val code = conn.responseCode
            conn.disconnect()
            if (code in 200..299 || code == 405) derived else DEFAULT_GATEWAY
        } catch (_: Exception) {
            DEFAULT_GATEWAY
        }
    }

    private fun ensureNotificationChannel() {
        val nm = getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CHANNEL_ID) == null) {
            val ch = android.app.NotificationChannel(
                CHANNEL_ID, "Messages", NotificationManager.IMPORTANCE_HIGH
            )
            nm.createNotificationChannel(ch)
        }
    }

    private data class PushInfo(val roomId: String, val eventId: String?, val isClear: Boolean)

    /** Parse a UP push payload. Returns null if room_id is missing. */
    private fun parsePush(content: ByteArray): PushInfo? {
        return try {
            val n = JSONObject(String(content)).getJSONObject("notification")
            val roomId = n.optString("room_id", "")
            if (roomId.isBlank()) return null
            val eventId = n.optString("event_id", "").takeIf { it.isNotBlank() }
            val unread = n.optJSONObject("counts")?.optInt("unread", -1) ?: -1
            // A clear push has no event_id and unread count == 0.
            val isClear = eventId == null && unread == 0
            PushInfo(roomId, eventId, isClear)
        } catch (_: JSONException) {
            null
        }
    }

    private data class NotifContent(
        val roomName: String,
        val senderName: String,
        val body: String,
        val isImage: Boolean,
        val largeIconBytes: ByteArray?,
        val imageUri: Uri?,
    )

    private fun showEnrichedNotification(roomId: String, eventId: String) {
        val notifId = roomId.hashCode()
        val nm = getSystemService(NotificationManager::class.java)

        showPlaceholderNotification(notifId, roomId, nm)

        val content = if (NativeBridge.tryLoad()) {
            // JNI path: initialises SDK if needed, then decrypts and enriches.
            // Falls back to HTTP only if SDK init itself fails (e.g. no session yet).
            fetchContentViaJni(roomId, eventId) ?: fetchContentViaHttp(roomId, eventId)
        } else {
            fetchContentViaHttp(roomId, eventId)
        } ?: return

        val storedBody = if (content.isImage) "" else content.body
        MessageStore.addMessage(this, roomId, StoredMessage(content.senderName, storedBody, System.currentTimeMillis()))
        val history = MessageStore.getMessages(this, roomId)

        val largeIconBitmap = content.largeIconBytes?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }

        val mePerson = Person.Builder().setName("Me").setImportant(false).build()
        val style = NotificationCompat.MessagingStyle(mePerson)
            .setGroupConversation(true)
            .setConversationTitle(content.roomName)

        val senderIcon = largeIconBitmap?.let {
            androidx.core.graphics.drawable.IconCompat.createWithBitmap(it)
        }
        val senderPerson = Person.Builder()
            .setName(content.senderName)
            .apply { if (senderIcon != null) setIcon(senderIcon) }
            .build()

        for (msg in history) {
            val person = if (msg.sender == content.senderName) senderPerson
                         else Person.Builder().setName(msg.sender).build()
            if (msg.body.isEmpty() && content.imageUri != null && msg === history.last()) {
                style.addMessage(
                    NotificationCompat.MessagingStyle.Message("", msg.timestamp, person)
                        .setData("image/jpeg", content.imageUri)
                )
            } else {
                style.addMessage(msg.body, msg.timestamp, person)
            }
        }

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_ROOM_ID, roomId)
        }
        val pendingIntent = PendingIntent.getActivity(
            this, notifId, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setStyle(style)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        if (largeIconBitmap != null) builder.setLargeIcon(largeIconBitmap)

        nm.notify(notifId, builder.build())
        addNotifiedRoom(this, roomId)
        scheduleReadCheck(this)
    }

    private fun fetchContentViaJni(roomId: String, eventId: String): NotifContent? {
        // Ensure the Rust SDK is initialised even when the app was killed.
        // No-op when android_main has already set up CLIENT + TOKIO_HANDLE.
        if (!NativeBridge.nativeInitForPush(filesDir.absolutePath)) {
            Log.d(TAG, "fetchContentViaJni: push init failed, will try HTTP fallback")
            return null
        }
        val payloadJson = NativeBridge.nativeFetchNotificationPayload(roomId, eventId)
        val payload = payloadJson?.let {
            try { JSONObject(it) } catch (_: JSONException) { null }
        } ?: return null

        val roomName = payload.optString("roomName").takeIf { it.isNotBlank() } ?: "PIAF"
        val senderId = payload.optString("senderId").takeIf { it.isNotBlank() } ?: ""
        val senderName = payload.optString("senderName").takeIf { it.isNotBlank() } ?: "Someone"
        val body = payload.optString("body").takeIf { it.isNotBlank() } ?: "New message"
        val isImage = payload.optBoolean("isImage")

        val largeIconBytes = if (senderId.isNotBlank()) {
            NativeBridge.nativeFetchSenderAvatarBytes(roomId, senderId)
        } else {
            NativeBridge.nativeFetchRoomAvatarBytes(roomId)
        }

        val imageUri: Uri? = if (isImage) {
            NativeBridge.nativeFetchEventImageBytes(roomId, eventId)?.let { saveImageToCache(it, roomId) }
        } else null

        return NotifContent(roomName, senderName, body, isImage, largeIconBytes, imageUri)
    }

    // ── HTTP fallback (app killed — no Rust SDK available) ────────────────────

    private data class StoredSession(val homeserver: String, val accessToken: String)

    /** Read homeserver URL and access token from the persisted session file. */
    private fun readStoredSession(): StoredSession? {
        return try {
            val file = File(filesDir, "persist_session/session")
            if (!file.exists()) return null
            val json = JSONObject(file.readText())
            val homeserver = json.getJSONObject("client_session").getString("homeserver")
                .trimEnd('/')
            // MatrixSession flattens its fields: access_token is directly in user_session
            val accessToken = json.getJSONObject("user_session").getString("access_token")
            StoredSession(homeserver, accessToken)
        } catch (_: Exception) { null }
    }

    private fun httpGetJson(url: String, token: String): JSONObject? {
        return try {
            val conn = java.net.URL(url).openConnection() as java.net.HttpURLConnection
            conn.connectTimeout = 10_000
            conn.readTimeout = 10_000
            conn.setRequestProperty("Authorization", "Bearer $token")
            if (conn.responseCode == 200) {
                JSONObject(conn.inputStream.bufferedReader().readText())
            } else null
        } catch (_: Exception) { null }
    }

    private fun enc(s: String) = java.net.URLEncoder.encode(s, "UTF-8")

    /**
     * Fetch notification content by calling the homeserver CS API directly.
     * Works when the app is killed and the Rust SDK is unavailable.
     * Returns null for encrypted events (can't decrypt without the Rust layer).
     */
    private fun fetchContentViaHttp(roomId: String, eventId: String): NotifContent? {
        val session = readStoredSession() ?: run {
            Log.d(TAG, "fetchContentViaHttp: no stored session")
            return null
        }

        val eventUrl = "${session.homeserver}/_matrix/client/v3/rooms/${enc(roomId)}/event/${enc(eventId)}"
        val event = httpGetJson(eventUrl, session.accessToken) ?: run {
            Log.d(TAG, "fetchContentViaHttp: failed to fetch event $eventId")
            return null
        }

        val type = event.optString("type")
        val senderId = event.optString("sender", "")

        // Resolve display name via profile API (lightweight call).
        val senderName: String = if (senderId.isNotBlank()) {
            val profileUrl = "${session.homeserver}/_matrix/client/v3/profile/${enc(senderId)}/displayname"
            httpGetJson(profileUrl, session.accessToken)
                ?.optString("displayname")
                ?.takeIf { it.isNotBlank() }
                ?: senderId.trimStart('@').split(':').first()
        } else "Someone"

        if (type == "m.room.encrypted") {
            // Content is encrypted — can only show generic text without the Rust SDK.
            Log.d(TAG, "fetchContentViaHttp: encrypted event, showing generic notification")
            return NotifContent("PIAF", senderName, "New message", false, null, null)
        }

        if (type != "m.room.message") {
            Log.d(TAG, "fetchContentViaHttp: unhandled event type $type")
            return null
        }

        val content = event.optJSONObject("content") ?: return null
        val msgtype = content.optString("msgtype", "")
        val (body, isImage) = when {
            msgtype == "m.text" -> content.optString("body", "New message") to false
            msgtype == "m.image" -> "📷 Image" to false  // no decryption possible
            msgtype == "m.file" -> "📎 File" to false
            msgtype == "m.audio" -> "🎵 Audio" to false
            msgtype == "m.video" -> "🎬 Video" to false
            else -> return null
        }

        Log.d(TAG, "fetchContentViaHttp: sender=$senderName body=$body")
        return NotifContent("PIAF", senderName, body, isImage, null, null)
    }

    /** Save image bytes to the app cache and return a FileProvider URI for use in notifications. */
    private fun saveImageToCache(imageBytes: ByteArray, roomId: String): Uri? {
        return try {
            val dir = File(cacheDir, "notification_images")
            dir.mkdirs()
            val file = File(dir, "${roomId.hashCode()}.jpg")
            file.writeBytes(imageBytes)
            FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        } catch (_: Exception) {
            null
        }
    }

    private fun showPlaceholderNotification(notifId: Int, roomId: String, nm: NotificationManager) {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_ROOM_ID, roomId)
        }
        val pendingIntent = PendingIntent.getActivity(
            this, notifId, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val placeholder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("New message")
            .setContentText("Loading…")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        nm.notify(notifId, placeholder)
    }

    // ── JNI bridge ───────────────────────────────────────────────────────────

    object NativeBridge {
        private var loaded = false

        fun tryLoad(): Boolean {
            if (!loaded) {
                try {
                    System.loadLibrary("piaf")
                    loaded = true
                } catch (_: UnsatisfiedLinkError) { }
            }
            return loaded
        }

        /** Spin up the Rust SDK in the push context (app killed). No-op if already running. */
        external fun nativeInitForPush(dataDir: String): Boolean
        external fun nativeEndpointChanged(endpoint: String)
        external fun nativeEndpointCleared()
        external fun nativeFetchRoomName(roomId: String): String?
        external fun nativeFetchNotificationPayload(roomId: String, eventId: String): String?
        external fun nativeFetchRoomAvatarBytes(roomId: String): ByteArray?
        external fun nativeFetchSenderAvatarBytes(roomId: String, senderId: String): ByteArray?
        external fun nativeFetchEventImageBytes(roomId: String, eventId: String): ByteArray?
        external fun nativeGetReadRooms(roomIdsJson: String): String
    }

    companion object {
        const val CHANNEL_ID = "piaf_messages"
        private const val TAG = "PiafPush"
        private const val ENDPOINT_FILE = "push_endpoint"
        private const val GATEWAY_FILE = "push_gateway"
        private const val DEFAULT_GATEWAY =
            "https://matrix.gateway.unifiedpush.org/_matrix/push/v1/notify"
        private const val PREFS_NOTIFIED = "piaf_notified_rooms"
        private const val KEY_ROOMS = "rooms"

        fun addNotifiedRoom(context: Context, roomId: String) {
            val prefs = context.getSharedPreferences(PREFS_NOTIFIED, Context.MODE_PRIVATE)
            val existing = prefs.getStringSet(KEY_ROOMS, emptySet())!!.toMutableSet()
            existing.add(roomId)
            prefs.edit()
                .putStringSet(KEY_ROOMS, existing)
                .putLong("ts_$roomId", System.currentTimeMillis())
                .apply()
        }

        fun removeNotifiedRoom(context: Context, roomId: String) {
            val prefs = context.getSharedPreferences(PREFS_NOTIFIED, Context.MODE_PRIVATE)
            val existing = prefs.getStringSet(KEY_ROOMS, emptySet())!!.toMutableSet()
            existing.remove(roomId)
            prefs.edit()
                .putStringSet(KEY_ROOMS, existing)
                .remove("ts_$roomId")
                .apply()
        }

        fun getNotifiedRooms(context: Context): Set<String> =
            context.getSharedPreferences(PREFS_NOTIFIED, Context.MODE_PRIVATE)
                .getStringSet(KEY_ROOMS, emptySet())!!.toSet()

        /**
         * Returns a JSON array of {roomId, ts} objects for currently-notified rooms.
         * `ts` is the millisecond timestamp when the notification was shown.
         * Called from Rust.
         */
        @JvmStatic
        fun getNotifiedRoomsJson(context: Context): String {
            val prefs = context.getSharedPreferences(PREFS_NOTIFIED, Context.MODE_PRIVATE)
            val rooms = prefs.getStringSet(KEY_ROOMS, emptySet())!!.toSet()
            val arr = JSONArray()
            for (roomId in rooms) {
                val ts = prefs.getLong("ts_$roomId", 0L)
                arr.put(JSONObject().apply {
                    put("roomId", roomId)
                    put("ts", ts)
                })
            }
            return arr.toString()
        }

        /**
         * Cancel notifications for the given rooms (JSON array of room_id strings) and
         * remove them from the notified-rooms registry. Called from Rust after each sync.
         */
        @JvmStatic
        fun cancelNotificationsForRooms(context: Context, roomIdsJson: String) {
            val rooms = try {
                val arr = JSONArray(roomIdsJson)
                (0 until arr.length()).map { arr.getString(it) }
            } catch (_: JSONException) { return }
            if (rooms.isEmpty()) return
            val nm = context.getSystemService(NotificationManager::class.java)
            for (roomId in rooms) {
                nm.cancel(roomId.hashCode())
                removeNotifiedRoom(context, roomId)
                MessageStore.clearMessages(context, roomId)
            }
        }

        fun cancelReadNotifications(context: Context) {
            if (!NativeBridge.tryLoad()) return
            val prefs = context.getSharedPreferences(PREFS_NOTIFIED, Context.MODE_PRIVATE)
            val rooms = prefs.getStringSet(KEY_ROOMS, emptySet())!!.toSet()
            if (rooms.isEmpty()) return

            // Build [{roomId, ts}] for Rust to compare against read receipts.
            val roomsJson = JSONArray(rooms.map { roomId ->
                JSONObject().apply {
                    put("roomId", roomId)
                    put("ts", prefs.getLong("ts_$roomId", 0L))
                }
            }).toString()
            val readJson = NativeBridge.nativeGetReadRooms(roomsJson)
            val readRooms: List<String> = try {
                val arr = JSONArray(readJson)
                (0 until arr.length()).map { arr.getString(it) }
            } catch (_: JSONException) { emptyList() }

            if (readRooms.isEmpty()) return
            val nm = context.getSystemService(NotificationManager::class.java)
            for (roomId in readRooms) {
                nm.cancel(roomId.hashCode())
                removeNotifiedRoom(context, roomId)
                MessageStore.clearMessages(context, roomId)
            }
        }

        private fun scheduleReadCheck(context: Context) {
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                Thread { cancelReadNotifications(context) }.start()
            }, 5_000)
        }
    }
}

// ── Per-room message history ──────────────────────────────────────────────────

data class StoredMessage(val sender: String, val body: String, val timestamp: Long)

object MessageStore {
    private const val PREFS = "piaf_room_messages"
    private const val MAX_MESSAGES = 10

    fun addMessage(context: Context, roomId: String, msg: StoredMessage) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val existing = loadRaw(prefs, roomId).toMutableList()
        existing.add(msg)
        // Keep only the most recent MAX_MESSAGES entries.
        val trimmed = if (existing.size > MAX_MESSAGES) existing.takeLast(MAX_MESSAGES) else existing
        prefs.edit().putString(roomId, encode(trimmed)).apply()
    }

    fun getMessages(context: Context, roomId: String): List<StoredMessage> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return loadRaw(prefs, roomId)
    }

    fun clearMessages(context: Context, roomId: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().remove(roomId).apply()
    }

    private fun loadRaw(
        prefs: android.content.SharedPreferences,
        roomId: String
    ): List<StoredMessage> {
        val json = prefs.getString(roomId, null) ?: return emptyList()
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).mapNotNull { i ->
                val o = arr.optJSONObject(i) ?: return@mapNotNull null
                StoredMessage(
                    sender = o.optString("s", ""),
                    body = o.optString("b", ""),
                    timestamp = o.optLong("t", 0L)
                )
            }
        } catch (_: JSONException) { emptyList() }
    }

    private fun encode(messages: List<StoredMessage>): String {
        val arr = JSONArray()
        for (m in messages) {
            arr.put(JSONObject().apply {
                put("s", m.sender)
                put("b", m.body)
                put("t", m.timestamp)
            })
        }
        return arr.toString()
    }
}
