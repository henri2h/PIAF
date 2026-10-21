package dev.piaf.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * A room notification was swiped away: forget its messages, so the next
 * message starts a fresh notification instead of showing the dismissed ones again.
 */
class NotificationDismissedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val roomId = intent.getStringExtra(MainActivity.EXTRA_ROOM_ID) ?: return
        RoomNotifications.forget(context, roomId)
    }
}
