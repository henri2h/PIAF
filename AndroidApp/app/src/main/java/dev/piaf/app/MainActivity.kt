package dev.piaf.app

import android.Manifest
import android.app.NativeActivity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import org.unifiedpush.android.connector.UnifiedPush

class MainActivity : NativeActivity() {

    companion object {
        const val EXTRA_ROOM_ID = "room_id"
    }

    private fun findNativeSurfaceView(view: View): View? {
        if (view is SurfaceView) return view
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                val found = findNativeSurfaceView(view.getChildAt(i))
                if (found != null) return found
            }
        }
        return null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        createNotificationChannel()
        requestNotificationPermission()
        UnifiedPush.tryUseCurrentOrDefaultDistributor(this) { success ->
            if (success) UnifiedPush.register(this)
        }

        dismissNotificationForIntent(intent)

        window.decorView.post {
            findNativeSurfaceView(window.decorView)?.apply {
                isFocusable = true
                isFocusableInTouchMode = true
                requestFocus()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        dismissNotificationForIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        Thread { PushReceiver.cancelReadNotifications(this) }.start()
    }

    /** If the activity was launched by tapping a notification, cancel that notification immediately. */
    private fun dismissNotificationForIntent(intent: Intent) {
        val roomId = intent.getStringExtra(EXTRA_ROOM_ID) ?: return
        val nm = getSystemService(NotificationManager::class.java)
        nm.cancel(roomId.hashCode())
        PushReceiver.removeNotifiedRoom(this, roomId)
        MessageStore.clearMessages(this, roomId)
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Back navigation is handled in native code (Freya on_global_key_down → BrowserBack).
        // Suppressing the default Java behavior prevents the activity from finishing
        // before the native layer has a chance to process the key event.
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            PushReceiver.CHANNEL_ID,
            "Messages",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "New message notifications"
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    0
                )
            }
        }
    }
}
