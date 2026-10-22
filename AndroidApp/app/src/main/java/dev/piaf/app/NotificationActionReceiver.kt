package dev.piaf.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.RemoteInput

/** The "Reply" and "Mark as read" buttons of a room notification. */
class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val roomId = intent.getStringExtra(MainActivity.EXTRA_ROOM_ID) ?: return
        val reply = RemoteInput.getResultsFromIntent(intent)
            ?.getCharSequence(RoomNotifications.KEY_REPLY)?.toString()?.trim()
        // Network work: keep the receiver alive past onReceive, off the main thread.
        val pending = goAsync()
        Thread {
            try {
                when (intent.action) {
                    ACTION_REPLY -> if (!reply.isNullOrEmpty()) RoomNotifications.reply(context, roomId, reply)
                    ACTION_MARK_READ -> RoomNotifications.markRead(context, roomId)
                }
            } finally {
                pending.finish()
            }
        }.start()
    }

    companion object {
        const val ACTION_REPLY = "dev.piaf.app.action.REPLY"
        const val ACTION_MARK_READ = "dev.piaf.app.action.MARK_READ"
    }
}
