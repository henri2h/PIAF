package dev.piaf.app

import android.content.Context
import android.util.Log
import org.json.JSONObject
import java.io.File

/**
 * Notification content straight from the homeserver's client API, for when
 * the Rust SDK can't start (no session yet, init failure). Encrypted events
 * can't be read this way and show a generic text.
 */
object HttpFallback {
    private const val TAG = "PiafPush"

    sealed class Result {
        data class Show(val sender: String, val body: String) : Result()
        /** Not a message: nothing to show. */
        object Skip : Result()
    }

    /** `null` when the event couldn't be fetched. */
    fun fetch(context: Context, roomId: String, eventId: String): Result? {
        val session = readSession(context) ?: return null
        val event = getJson(
            "${session.homeserver}/_matrix/client/v3/rooms/${enc(roomId)}/event/${enc(eventId)}",
            session.accessToken,
        ) ?: run {
            Log.d(TAG, "HttpFallback: failed to fetch event $eventId")
            return null
        }

        val senderId = event.optString("sender", "")
        val sender = if (senderId.isBlank()) "Someone" else getJson(
            "${session.homeserver}/_matrix/client/v3/profile/${enc(senderId)}/displayname",
            session.accessToken,
        )?.optString("displayname")?.takeIf { it.isNotBlank() }
            ?: senderId.trimStart('@').substringBefore(':')

        return when (event.optString("type")) {
            "m.room.encrypted" -> Result.Show(sender, "New message")
            "m.room.message" -> {
                val content = event.optJSONObject("content") ?: return Result.Skip
                val body = when (content.optString("msgtype")) {
                    "m.text", "m.notice" -> content.optString("body", "New message")
                    "m.emote" -> "* $sender ${content.optString("body")}"
                    "m.image" -> "📷 Image"
                    "m.file" -> "📎 File"
                    "m.audio" -> "🎵 Audio"
                    "m.video" -> "🎬 Video"
                    else -> return Result.Skip
                }
                Result.Show(sender, body)
            }
            else -> Result.Skip
        }
    }

    private data class Session(val homeserver: String, val accessToken: String)

    private fun readSession(context: Context): Session? = try {
        val file = File(context.filesDir, "persist_session/session")
        if (!file.exists()) null else {
            val json = JSONObject(file.readText())
            Session(
                json.getJSONObject("client_session").getString("homeserver").trimEnd('/'),
                // MatrixSession flattens its fields: access_token is directly in user_session.
                json.getJSONObject("user_session").getString("access_token"),
            )
        }
    } catch (_: Exception) { null }

    private fun getJson(url: String, token: String): JSONObject? = try {
        val conn = java.net.URL(url).openConnection() as java.net.HttpURLConnection
        conn.connectTimeout = 10_000
        conn.readTimeout = 10_000
        conn.setRequestProperty("Authorization", "Bearer $token")
        if (conn.responseCode == 200) JSONObject(conn.inputStream.bufferedReader().readText()) else null
    } catch (_: Exception) { null }

    private fun enc(s: String) = java.net.URLEncoder.encode(s, "UTF-8")
}
