package dev.piaf.app

import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.FileProvider
import java.io.File
import java.lang.ref.WeakReference

/** The system share sheet for a file Rust hands over (e.g. the viewer's image). */
object ShareSheet {
    private const val TAG = "PiafShare"
    private var activity = WeakReference<Activity>(null)
    private val main = Handler(Looper.getMainLooper())

    fun attach(a: Activity) {
        activity = WeakReference(a)
    }

    /** Writes `bytes` to the cache as `name` and offers it to other apps. Returns nothing: Rust looks up `(..)V`. */
    @JvmStatic
    fun share(name: String, mime: String, bytes: ByteArray) {
        val a = activity.get() ?: return
        Thread {
            try {
                val dir = File(a.cacheDir, "share").apply { mkdirs() }
                // One shared file at a time: older ones are no longer needed.
                dir.listFiles()?.forEach { it.delete() }
                val file = File(dir, name.ifBlank { "image" })
                file.writeBytes(bytes)
                val uri = FileProvider.getUriForFile(a, "${a.packageName}.fileprovider", file)
                val send = Intent(Intent.ACTION_SEND)
                    .setType(mime)
                    .putExtra(Intent.EXTRA_STREAM, uri)
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                main.post {
                    a.startActivity(Intent.createChooser(send, null))
                }
            } catch (e: Exception) {
                Log.w(TAG, "could not share: $e")
            }
        }.start()
    }
}
