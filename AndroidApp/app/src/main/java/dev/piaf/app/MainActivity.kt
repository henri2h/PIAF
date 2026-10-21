package dev.piaf.app

import android.Manifest
import android.annotation.SuppressLint
import android.app.NativeActivity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
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

        // Draw edge to edge on every version and report the insets to the
        // app, which pads itself: NativeActivity never resizes for the keyboard.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        ViewCompat.setOnApplyWindowInsetsListener(window.decorView) { view, insets ->
            reportInsets(insets)
            ViewCompat.onApplyWindowInsets(view, insets)
        }
        // The soft keyboard's editor (see ImeInputView): 1px, never drawn over.
        val ime = ImeInputView(this)
        addContentView(ime, ViewGroup.LayoutParams(1, 1))
        ImeBridge.attach(ime)
        AttachmentPicker.attach(this)
        ShareSheet.attach(this)

        RoomNotifications.ensureChannel(this)
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

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!AttachmentPicker.onResult(requestCode, resultCode, data)) {
            @Suppress("DEPRECATION")
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onResume() {
        super.onResume()
        Thread { PushReceiver.cancelReadNotifications(this) }.start()
    }

    private fun reportInsets(insets: WindowInsetsCompat) {
        if (!PushReceiver.NativeBridge.tryLoad()) return
        val density = resources.displayMetrics.density
        val bars = insets.getInsets(
            WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
        )
        val ime = insets.getInsets(WindowInsetsCompat.Type.ime())
        PushReceiver.NativeBridge.nativeSetInsets(
            bars.top / density, bars.bottom / density, ime.bottom / density
        )
    }

    /** Launched by tapping a notification: open its room and clear the notification. */
    private fun dismissNotificationForIntent(intent: Intent) {
        val roomId = intent.getStringExtra(EXTRA_ROOM_ID) ?: return
        // Handle a tap once: the activity can be recreated with the same intent.
        intent.removeExtra(EXTRA_ROOM_ID)
        RoomNotifications.cancel(this, roomId)
        if (PushReceiver.NativeBridge.tryLoad()) PushReceiver.NativeBridge.nativeOpenRoom(roomId)
    }

    // Still called: the manifest opts out of predictive back
    // (enableOnBackInvokedCallback="false"), which this lint ignores.
    @SuppressLint("GestureBackNavigation")
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Back navigation is handled in native code (Freya on_global_key_down → BrowserBack).
        // Suppressing the default Java behavior prevents the activity from finishing
        // before the native layer has a chance to process the key event.
    }

    override fun onDestroy() {
        super.onDestroy()
        // winit allows one event loop per process: the next launch must be a
        // fresh process, or it fails to start (RecreationAttempt).
        if (isFinishing) android.os.Process.killProcess(android.os.Process.myPid())
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
