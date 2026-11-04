package dev.piaf.app

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import org.unifiedpush.android.connector.FailedReason
import org.unifiedpush.android.connector.INSTANCE_DEFAULT
import org.unifiedpush.android.connector.PushService
import org.unifiedpush.android.connector.data.PushEndpoint
import org.unifiedpush.android.connector.data.PushMessage
import java.io.File

/**
 * UnifiedPush entry point: endpoint changes and incoming pushes. Each account
 * has its own instance (its id, see `Accounts`).
 */
class PushReceiver : PushService() {

    override fun onNewEndpoint(endpoint: PushEndpoint, instance: String) {
        // The instance shared before accounts: replaced by the accounts' own.
        if (instance !in Accounts.ids(this)) return
        val url = endpoint.url
        // Network (gateway check, pusher registration): off the main thread.
        pushes.execute {
            val dir = Accounts.dir(this, instance).apply { mkdirs() }
            File(dir, ENDPOINT_FILE).writeText(url)
            File(dir, GATEWAY_FILE).writeText(resolveGateway(url))
            if (initNative(this)) NativeBridge.nativeEndpointChanged(instance, url)
        }
    }

    override fun onUnregistered(instance: String) {
        if (instance == INSTANCE_DEFAULT) {
            // Before accounts, the endpoint was app-wide.
            File(filesDir, ENDPOINT_FILE).delete()
            File(filesDir, GATEWAY_FILE).delete()
            return
        }
        pushes.execute {
            if (initNative(this)) NativeBridge.nativeEndpointCleared(instance)
            val dir = Accounts.dir(this, instance)
            File(dir, ENDPOINT_FILE).delete()
            File(dir, GATEWAY_FILE).delete()
        }
    }

    override fun onMessage(message: PushMessage, instance: String) {
        val account = Accounts.resolve(this, instance) ?: run {
            Log.d(TAG, "onMessage: no account for this push, ignoring")
            return
        }
        val push = parsePush(message.content) ?: run {
            Log.d(TAG, "onMessage: no room_id, ignoring")
            return
        }
        Log.d(TAG, "onMessage: roomId=${push.roomId} eventId=${push.eventId} isClear=${push.isClear}")
        // Called on the main thread, which the app needs to start (a tapped
        // notification): the fetches (network) run in order on their own thread.
        pushes.execute {
            when {
                push.isClear -> RoomNotifications.cancel(this, account, push.roomId)
                push.eventId != null -> RoomNotifications.show(this, account, push.roomId, push.eventId)
            }
        }
    }

    override fun onRegistrationFailed(reason: FailedReason, instance: String) {
        // Retried on the next app launch.
    }

    /**
     * Resolve the Matrix push gateway for a UP endpoint URL.
     *
     * Self-hosted ntfy and similar distributors expose a Matrix push gateway at
     * scheme://host/_matrix/push/v1/notify on the same origin. A real gateway
     * answers that URL with 200 or 405; anything else (e.g. Mozilla's push
     * service returns 404) falls back to the default gateway.
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
            PushInfo(roomId, eventId, eventId == null && unread == 0)
        } catch (_: JSONException) {
            null
        }
    }

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

        /**
         * Spin up the Rust SDK in the push context (app killed). No-op if already
         * running. False when no account is signed in. `account` arguments below
         * are account ids (see `Accounts`); all but `nativeOpenRoom` need this first.
         */
        external fun nativeInitForPush(context: Context, dataDir: String): Boolean
        external fun nativeEndpointChanged(account: String, endpoint: String)
        external fun nativeEndpointCleared(account: String)
        external fun nativeFetchNotificationPayload(account: String, roomId: String, eventId: String): String?
        external fun nativeFetchRoomAvatarBytes(account: String, roomId: String): ByteArray?
        external fun nativeFetchSenderAvatarBytes(account: String, roomId: String, senderId: String): ByteArray?
        external fun nativeFetchEventImageBytes(account: String, roomId: String, eventId: String): ByteArray?
        /** `[{account, roomId, ts}]` → the rooms read since, `[{account, roomId}]`. */
        external fun nativeGetReadRooms(roomIdsJson: String): String
        /** A notification was tapped: open its room (switching to its account). */
        external fun nativeOpenRoom(account: String, roomId: String)
        /** Notification "Reply". */
        external fun nativeSendReply(account: String, roomId: String, body: String): Boolean
        /** Notification "Mark as read". */
        external fun nativeMarkRead(account: String, roomId: String, eventId: String): Boolean
        /** System bar and keyboard insets, in dp (`MainActivity`). */
        external fun nativeSetInsets(top: Float, bottom: Float, ime: Float)
    }

    companion object {
        const val CHANNEL_ID = "piaf_messages"
        private const val TAG = "PiafPush"
        private val pushes = java.util.concurrent.Executors.newSingleThreadExecutor()
        private const val ENDPOINT_FILE = "push_endpoint"
        private const val GATEWAY_FILE = "push_gateway"
        private const val DEFAULT_GATEWAY =
            "https://matrix.gateway.unifiedpush.org/_matrix/push/v1/notify"

        /** Loads the library and the Rust SDK; false if there is no account to use. */
        fun initNative(context: Context): Boolean =
            NativeBridge.tryLoad() &&
                NativeBridge.nativeInitForPush(context.applicationContext, context.filesDir.absolutePath)

        /** `[{account, roomId, ts}]` of the rooms with a notification shown. Called from Rust. */
        @JvmStatic
        fun getNotifiedRoomsJson(context: Context): String =
            NotifiedRooms.toJson(context)

        /** Cancel the notifications of a JSON array of room IDs of `account`. Called from Rust after each sync. */
        @JvmStatic
        fun cancelNotificationsForRooms(context: Context, account: String, roomIdsJson: String) {
            val rooms = try {
                val arr = JSONArray(roomIdsJson)
                (0 until arr.length()).map { arr.getString(it) }
            } catch (_: JSONException) { return }
            rooms.forEach { RoomNotifications.cancel(context, account, it) }
        }

        /** Registers the accounts' push instances. Called from Rust once syncing (a new account). */
        @JvmStatic
        fun registerAccounts(context: Context) = Accounts.registerPush(context)

        /** Cancel the notifications of rooms read since they were shown (on any device). */
        fun cancelReadNotifications(context: Context) {
            if (!NativeBridge.tryLoad()) return
            if (NotifiedRooms.all(context).isEmpty()) return
            val read = try {
                JSONArray(NativeBridge.nativeGetReadRooms(NotifiedRooms.toJson(context)))
            } catch (_: JSONException) { return }
            for (i in 0 until read.length()) {
                val room = read.optJSONObject(i) ?: continue
                RoomNotifications.cancel(context, room.optString("account"), room.optString("roomId"))
            }
        }
    }
}
