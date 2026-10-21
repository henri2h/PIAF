package dev.piaf.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.net.Uri
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.core.app.RemoteInput
import androidx.core.content.FileProvider
import androidx.core.content.LocusIdCompat
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.File
import kotlin.math.roundToInt

/** One notification per room: a conversation of the messages pushed since it was last read or dismissed. */
object RoomNotifications {
    private const val TAG = "PiafPush"
    const val KEY_REPLY = "reply"
    /** `StoredMessage.senderId` of the user's own replies. */
    private const val ME = "me"

    private fun notificationId(roomId: String) = roomId.hashCode()

    /** Shows (or extends) the room's notification with the pushed event. */
    fun show(context: Context, roomId: String, eventId: String) {
        // The same event can be pushed again (gateway retries, several
        // pushers): never show it twice, nor bring back one that was dismissed.
        if (!SeenEvents.markSeen(context, eventId)) {
            Log.d(TAG, "show: $eventId already handled")
            return
        }
        ensureChannel(context)
        val nm = context.getSystemService(NotificationManager::class.java)
        val id = notificationId(roomId)

        // Only the real content is posted: no "Loading…" placeholder first.
        val notification = when (val result = fetch(context, roomId, eventId)) {
            is Fetch.Show -> {
                val content = result.content
                val body = if (content.imageUri != null) "" else content.body
                MessageStore.addMessage(
                    context, roomId,
                    StoredMessage(content.senderId, content.senderName, body, System.currentTimeMillis())
                )
                conversation(context, roomId, eventId, content)
            }
            Fetch.Skip -> return
            // Keep the conversation already shown rather than replace it.
            Fetch.Unavailable ->
                if (nm.activeNotifications.any { it.id == id }) return
                else builder(context, roomId, eventId).setContentTitle("New message").build()
        }
        nm.notify(id, notification)
        NotifiedRooms.add(context, roomId, eventId)
        scheduleReadCheck(context)
    }

    /**
     * "Reply" action: sends `text`, then shows it at the end of the
     * conversation (a reply action must update its notification, or Android
     * keeps showing a spinner). Runs off the main thread.
     */
    fun reply(context: Context, roomId: String, text: String) {
        val bridge = PushReceiver.NativeBridge
        val sent = bridge.tryLoad() &&
            bridge.nativeInitForPush(context.filesDir.absolutePath) &&
            bridge.nativeSendReply(roomId, text)
        val body = if (sent) text else "⚠ Not sent: $text"
        if (sent) MessageStore.addMessage(context, roomId, StoredMessage(ME, "Me", text, System.currentTimeMillis()))

        val nm = context.getSystemService(NotificationManager::class.java)
        val active = nm.activeNotifications.firstOrNull { it.id == notificationId(roomId) }?.notification
        if (active == null) return
        val style = NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(active)
            ?: NotificationCompat.MessagingStyle(Person.Builder().setName("Me").build())
        style.addMessage(NotificationCompat.MessagingStyle.Message(body, System.currentTimeMillis(), null as Person?))
        val updated = builder(context, roomId, NotifiedRooms.lastEvent(context, roomId))
            .setStyle(style)
            .setLargeIcon(active.getLargeIcon()?.loadDrawable(context)?.let { drawableToBitmap(it) })
            .setShortcutId(roomId)
            .setLocusId(LocusIdCompat(roomId))
            .setSilent(true)
            .build()
        nm.notify(notificationId(roomId), updated)
    }

    /** "Mark as read" action: read receipt on the last notified event, then clear. Runs off the main thread. */
    fun markRead(context: Context, roomId: String) {
        val eventId = NotifiedRooms.lastEvent(context, roomId) ?: return cancel(context, roomId)
        val bridge = PushReceiver.NativeBridge
        val read = bridge.tryLoad() &&
            bridge.nativeInitForPush(context.filesDir.absolutePath) &&
            bridge.nativeMarkRead(roomId, eventId)
        if (read) cancel(context, roomId) else Log.w(TAG, "markRead failed for $roomId")
    }

    /** Removes the room's notification and forgets its messages (it was read). */
    fun cancel(context: Context, roomId: String) {
        context.getSystemService(NotificationManager::class.java).cancel(notificationId(roomId))
        forget(context, roomId)
    }

    /** Forgets the room's messages, so the next notification starts fresh. */
    fun forget(context: Context, roomId: String) {
        NotifiedRooms.remove(context, roomId)
        MessageStore.clearMessages(context, roomId)
    }

    fun ensureChannel(context: Context) {
        val nm = context.getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(PushReceiver.CHANNEL_ID) == null) {
            val channel = NotificationChannel(
                PushReceiver.CHANNEL_ID, "Messages", NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "New message notifications" }
            nm.createNotificationChannel(channel)
        }
    }

    // ── Content ──────────────────────────────────────────────────────────────

    private data class Content(
        val roomName: String,
        val isDm: Boolean,
        val roomColor: Int,
        val senderId: String,
        val senderName: String,
        val senderColor: Int,
        val body: String,
        val roomAvatar: Bitmap?,
        val senderAvatar: Bitmap?,
        val imageUri: Uri?,
    )

    private sealed class Fetch {
        data class Show(val content: Content) : Fetch()
        /** Nothing to show (reaction, edit, state event…). */
        object Skip : Fetch()
        /** Couldn't load the event: show a generic notification. */
        object Unavailable : Fetch()
    }

    private fun fetch(context: Context, roomId: String, eventId: String): Fetch {
        val viaRust = if (PushReceiver.NativeBridge.tryLoad()) fetchViaRust(context, roomId, eventId) else null
        if (viaRust != null) return viaRust
        return when (val http = HttpFallback.fetch(context, roomId, eventId)) {
            is HttpFallback.Result.Show -> Fetch.Show(
                Content(
                    roomName = "PIAF", isDm = false, roomColor = DEFAULT_COLOR,
                    senderId = "", senderName = http.sender, senderColor = DEFAULT_COLOR,
                    body = http.body, roomAvatar = null, senderAvatar = null, imageUri = null,
                )
            )
            HttpFallback.Result.Skip -> Fetch.Skip
            null -> Fetch.Unavailable
        }
    }

    /** `null` when the Rust side couldn't load the event (the HTTP fallback is tried next). */
    private fun fetchViaRust(context: Context, roomId: String, eventId: String): Fetch? {
        val bridge = PushReceiver.NativeBridge
        if (!bridge.nativeInitForPush(context.filesDir.absolutePath)) return null
        val payload = bridge.nativeFetchNotificationPayload(roomId, eventId)?.let {
            try { JSONObject(it) } catch (_: JSONException) { null }
        } ?: return null
        if (payload.optBoolean("skip")) return Fetch.Skip

        val isDm = payload.optBoolean("isDm")
        val senderId = payload.optString("senderId")
        val isImage = payload.optBoolean("isImage")
        val decode = { bytes: ByteArray? -> bytes?.let { BitmapFactory.decodeByteArray(it, 0, it.size) } }
        return Fetch.Show(
            Content(
                roomName = payload.optString("roomName").ifBlank { "PIAF" },
                isDm = isDm,
                roomColor = parseColor(payload.optString("roomColor")),
                senderId = senderId,
                senderName = payload.optString("senderName").ifBlank { "Someone" },
                senderColor = parseColor(payload.optString("senderColor")),
                body = payload.optString("body").ifBlank { "New message" },
                // A DM's room avatar is the other user: no need to fetch it twice.
                roomAvatar = if (isDm) null else decode(bridge.nativeFetchRoomAvatarBytes(roomId)),
                senderAvatar = if (senderId.isBlank()) null
                               else decode(bridge.nativeFetchSenderAvatarBytes(roomId, senderId)),
                imageUri = if (isImage) bridge.nativeFetchEventImageBytes(roomId, eventId)
                    ?.let { saveImage(context, it, roomId) } else null,
            )
        )
    }

    // ── Notifications ────────────────────────────────────────────────────────

    /** The room's conversation, from its stored messages. */
    private fun conversation(
        context: Context,
        roomId: String,
        eventId: String,
        content: Content,
    ): android.app.Notification {
        val senderIcon = content.senderAvatar ?: letterAvatar(context, content.senderName, content.senderColor)
        val sender = Person.Builder()
            .setName(content.senderName)
            .setKey(content.senderId.ifBlank { null })
            .setIcon(IconCompat.createWithBitmap(senderIcon))
            .build()
        val style = NotificationCompat.MessagingStyle(Person.Builder().setName("Me").build())
        style.isGroupConversation = !content.isDm
        if (!content.isDm) style.conversationTitle = content.roomName

        val history = MessageStore.getMessages(context, roomId)
        for (msg in history) {
            val isSender = if (msg.senderId.isNotBlank()) msg.senderId == content.senderId
                           else msg.sender == content.senderName
            val person = when {
                msg.senderId == ME -> null // the style's own user
                isSender -> sender
                else -> Person.Builder().setName(msg.sender).build()
            }
            val message = NotificationCompat.MessagingStyle.Message(msg.body, msg.timestamp, person)
            if (msg.body.isEmpty() && content.imageUri != null && msg === history.last()) {
                message.setData("image/jpeg", content.imageUri)
            }
            style.addMessage(message)
        }

        // The conversation's picture: the other user in a DM, else the room.
        val largeIcon = if (content.isDm) senderIcon
                        else content.roomAvatar ?: letterAvatar(context, content.roomName, content.roomColor)

        val title = if (content.isDm) content.senderName else content.roomName
        pushShortcut(context, roomId, title, largeIcon, if (content.isDm) sender else null)

        return builder(context, roomId, eventId)
            .setStyle(style)
            .setLargeIcon(largeIcon)
            // A long-lived shortcut makes it a conversation: Conversations
            // section, priority settings, bubbles.
            .setShortcutId(roomId)
            .setLocusId(LocusIdCompat(roomId))
            .build()
    }

    /** The room as a conversation shortcut (launcher long-press, share sheet, notification conversations). */
    private fun pushShortcut(context: Context, roomId: String, title: String, icon: Bitmap, person: Person?) {
        val open = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_VIEW)
            .putExtra(MainActivity.EXTRA_ROOM_ID, roomId)
        val shortcut = ShortcutInfoCompat.Builder(context, roomId)
            .setShortLabel(title)
            .setLongLived(true)
            .setIcon(IconCompat.createWithBitmap(icon))
            .setIntent(open)
            .setLocusId(LocusIdCompat(roomId))
            .setCategories(setOf(android.content.pm.ShortcutInfo.SHORTCUT_CATEGORY_CONVERSATION))
            .apply { if (person != null) setPerson(person) }
            .build()
        try {
            ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)
        } catch (e: Exception) {
            Log.w(TAG, "pushShortcut failed: $e")
        }
    }

    /** `eventId`: the last notified event, for "Mark as read" (no actions without it). */
    private fun builder(context: Context, roomId: String, eventId: String?): NotificationCompat.Builder {
        val id = notificationId(roomId)
        val open = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_ROOM_ID, roomId)
        }
        val dismissed = Intent(context, NotificationDismissedReceiver::class.java)
            .putExtra(MainActivity.EXTRA_ROOM_ID, roomId)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return NotificationCompat.Builder(context, PushReceiver.CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setContentIntent(PendingIntent.getActivity(context, id, open, flags))
            .setDeleteIntent(PendingIntent.getBroadcast(context, id, dismissed, flags))
            .setAutoCancel(true)
            .apply { if (eventId != null) addActions(context, this, roomId) }
    }

    private fun addActions(context: Context, builder: NotificationCompat.Builder, roomId: String) {
        val id = notificationId(roomId)
        val actionIntent = { action: String ->
            Intent(context, NotificationActionReceiver::class.java)
                .setAction(action)
                .putExtra(MainActivity.EXTRA_ROOM_ID, roomId)
        }
        // A RemoteInput fills in the intent: it must be mutable.
        val replyIntent = PendingIntent.getBroadcast(
            context, id, actionIntent(NotificationActionReceiver.ACTION_REPLY),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
        val readIntent = PendingIntent.getBroadcast(
            context, id, actionIntent(NotificationActionReceiver.ACTION_MARK_READ),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val reply = NotificationCompat.Action.Builder(android.R.drawable.ic_menu_send, "Reply", replyIntent)
            .addRemoteInput(RemoteInput.Builder(KEY_REPLY).setLabel("Reply").build())
            .setSemanticAction(NotificationCompat.Action.SEMANTIC_ACTION_REPLY)
            .setShowsUserInterface(false)
            .setAllowGeneratedReplies(true)
            .build()
        val markRead = NotificationCompat.Action.Builder(android.R.drawable.ic_menu_view, "Mark as read", readIntent)
            .setSemanticAction(NotificationCompat.Action.SEMANTIC_ACTION_MARK_AS_READ)
            .setShowsUserInterface(false)
            .build()
        builder.addAction(reply).addAction(markRead)
    }

    private fun drawableToBitmap(drawable: android.graphics.drawable.Drawable): Bitmap {
        if (drawable is android.graphics.drawable.BitmapDrawable && drawable.bitmap != null) return drawable.bitmap
        val bitmap = Bitmap.createBitmap(
            drawable.intrinsicWidth.coerceAtLeast(1), drawable.intrinsicHeight.coerceAtLeast(1),
            Bitmap.Config.ARGB_8888,
        )
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun scheduleReadCheck(context: Context) {
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            Thread { PushReceiver.cancelReadNotifications(context) }.start()
        }, 5_000)
    }

    // ── Pictures ─────────────────────────────────────────────────────────────

    // The app's primary blue.
    private const val DEFAULT_COLOR = 0xFF1D9BF0.toInt()

    private fun parseColor(hex: String): Int =
        try { Color.parseColor(hex) } catch (_: IllegalArgumentException) { DEFAULT_COLOR }

    /** Mixes `a` toward `b` by `t` (0..1). */
    private fun mix(a: Int, b: Int, t: Float): Int {
        val m = { x: Int, y: Int -> (x + (y - x) * t).roundToInt() }
        return Color.rgb(m(Color.red(a), Color.red(b)), m(Color.green(a), Color.green(b)), m(Color.blue(a), Color.blue(b)))
    }

    /**
     * The app's fallback avatar: the name's initial on its colour, tonal like
     * the app (soft tint + deep letter, reversed in dark mode).
     */
    private fun letterAvatar(context: Context, name: String, color: Int): Bitmap {
        val dark = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES
        val background = if (dark) mix(color, Color.BLACK, 0.6f) else mix(color, Color.WHITE, 0.8f)
        val foreground = if (dark) mix(color, Color.WHITE, 0.65f) else mix(color, Color.BLACK, 0.3f)
        val size = 128
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = background }
        canvas.drawCircle(size / 2f, size / 2f, size / 2f, paint)
        val initial = name.trim().trimStart('@', '#', '!').firstOrNull()?.uppercase() ?: "?"
        paint.apply {
            this.color = foreground
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
            textSize = size * 0.45f
            textAlign = Paint.Align.CENTER
        }
        val bounds = Rect()
        paint.getTextBounds(initial, 0, initial.length, bounds)
        canvas.drawText(initial, size / 2f, size / 2f + bounds.height() / 2f, paint)
        return bitmap
    }

    /** Saves an image to the cache, as a URI the notification can show. */
    private fun saveImage(context: Context, bytes: ByteArray, roomId: String): Uri? = try {
        val dir = File(context.cacheDir, "notification_images").apply { mkdirs() }
        val file = File(dir, "${roomId.hashCode()}.jpg").apply { writeBytes(bytes) }
        FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
    } catch (_: Exception) {
        null
    }
}

/** Events already notified (or skipped), so a re-push or a dismissed one never shows again. */
object SeenEvents {
    private const val PREFS = "piaf_seen_events"
    private const val KEY = "events"
    private const val MAX = 200

    /** Records `eventId`; false if it was already there. */
    @Synchronized
    fun markSeen(context: Context, eventId: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val seen = try {
            val arr = JSONArray(prefs.getString(KEY, "[]"))
            (0 until arr.length()).map { arr.getString(it) }
        } catch (_: JSONException) { emptyList() }
        if (eventId in seen) return false
        val updated = (seen + eventId).takeLast(MAX)
        prefs.edit().putString(KEY, JSONArray(updated).toString()).apply()
        return true
    }
}

/** Rooms with a notification shown, and when (for the read checks). */
object NotifiedRooms {
    private const val PREFS = "piaf_notified_rooms"
    private const val KEY_ROOMS = "rooms"

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun all(context: Context): Set<String> = prefs(context).getStringSet(KEY_ROOMS, emptySet())!!.toSet()

    /** `eventId`: the latest notified event (what "Mark as read" reads up to). */
    fun add(context: Context, roomId: String, eventId: String) {
        prefs(context).edit()
            .putStringSet(KEY_ROOMS, all(context) + roomId)
            .putLong("ts_$roomId", System.currentTimeMillis())
            .putString("event_$roomId", eventId)
            .apply()
    }

    fun remove(context: Context, roomId: String) {
        prefs(context).edit()
            .putStringSet(KEY_ROOMS, all(context) - roomId)
            .remove("ts_$roomId")
            .remove("event_$roomId")
            .apply()
    }

    fun lastEvent(context: Context, roomId: String): String? =
        prefs(context).getString("event_$roomId", null)

    /** `[{roomId, ts}]`, ts: when the notification was shown (ms). */
    fun toJson(context: Context): String {
        val prefs = prefs(context)
        return JSONArray(all(context).map { roomId ->
            JSONObject().put("roomId", roomId).put("ts", prefs.getLong("ts_$roomId", 0L))
        }).toString()
    }
}

// ── Per-room message history ──────────────────────────────────────────────────

data class StoredMessage(val senderId: String, val sender: String, val body: String, val timestamp: Long)

object MessageStore {
    private const val PREFS = "piaf_room_messages"
    private const val MAX_MESSAGES = 10

    fun addMessage(context: Context, roomId: String, msg: StoredMessage) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val messages = (load(prefs, roomId) + msg).takeLast(MAX_MESSAGES)
        prefs.edit().putString(roomId, encode(messages)).apply()
    }

    fun getMessages(context: Context, roomId: String): List<StoredMessage> =
        load(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE), roomId)

    fun clearMessages(context: Context, roomId: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(roomId).apply()
    }

    private fun load(prefs: android.content.SharedPreferences, roomId: String): List<StoredMessage> {
        val json = prefs.getString(roomId, null) ?: return emptyList()
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).mapNotNull { i ->
                val o = arr.optJSONObject(i) ?: return@mapNotNull null
                StoredMessage(o.optString("i", ""), o.optString("s", ""), o.optString("b", ""), o.optLong("t", 0L))
            }
        } catch (_: JSONException) { emptyList() }
    }

    private fun encode(messages: List<StoredMessage>) = JSONArray(messages.map { m ->
        JSONObject().put("i", m.senderId).put("s", m.sender).put("b", m.body).put("t", m.timestamp)
    }).toString()
}
