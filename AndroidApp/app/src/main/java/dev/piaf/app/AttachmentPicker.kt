package dev.piaf.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Log
import androidx.core.content.FileProvider
import java.io.File
import java.lang.ref.WeakReference

/**
 * Picks a file to send for the composer: the photo picker (gallery), the
 * camera, or any document. Rust asks with [pick]; the bytes come back through
 * [nativePicked], or [nativeCancelled] when nothing was picked.
 */
object AttachmentPicker {
    private const val TAG = "PiafAttach"
    private const val REQUEST = 4710
    /** Matrix servers rarely take more; reading it all into memory must stay sane. */
    private const val MAX_BYTES = 100L * 1024 * 1024

    private const val GALLERY = 0
    private const val CAMERA = 1

    private var activity = WeakReference<Activity>(null)
    private val main = Handler(Looper.getMainLooper())
    /** Where the camera writes the photo being taken. */
    private var photo: File? = null

    fun attach(a: Activity) {
        activity = WeakReference(a)
    }

    /** `kind`: 0 gallery, 1 camera, 2 file. Returns nothing: Rust looks up `(I)V`. */
    @JvmStatic
    fun pick(kind: Int) {
        main.post { start(kind) }
    }

    private fun start(kind: Int) {
        val a = activity.get() ?: return nativeCancelled()
        val intent = when (kind) {
            GALLERY -> galleryIntent()
            CAMERA -> cameraIntent(a)
            else -> Intent(Intent.ACTION_OPEN_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE)
                .setType("*/*")
        }
        try {
            @Suppress("DEPRECATION")
            a.startActivityForResult(intent, REQUEST)
        } catch (e: Exception) {
            Log.w(TAG, "no app to pick with: $e")
            nativeCancelled()
        }
    }

    private fun galleryIntent(): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // The system photo picker: images and videos, no permission needed.
            Intent(MediaStore.ACTION_PICK_IMAGES)
        } else {
            Intent(Intent.ACTION_GET_CONTENT)
                .addCategory(Intent.CATEGORY_OPENABLE)
                .setType("image/*")
                .putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/*", "video/*"))
        }

    private fun cameraIntent(a: Activity): Intent {
        val dir = File(a.cacheDir, "camera").apply { mkdirs() }
        val file = File(dir, "photo-${System.currentTimeMillis()}.jpg")
        photo = file
        val uri = FileProvider.getUriForFile(a, "${a.packageName}.fileprovider", file)
        return Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            .putExtra(MediaStore.EXTRA_OUTPUT, uri)
            .addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
    }

    /** From `MainActivity.onActivityResult`; `true` when it was ours. */
    fun onResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST) return false
        val a = activity.get()
        val taken = photo
        photo = null
        if (resultCode != Activity.RESULT_OK || a == null) {
            taken?.delete()
            nativeCancelled()
            return true
        }
        // Reading may take a while (videos): off the main thread.
        Thread {
            try {
                if (taken != null) {
                    send(taken.name, "image/jpeg", taken.readBytes())
                    taken.delete()
                } else {
                    val uri = data?.data ?: return@Thread nativeCancelled()
                    read(a, uri)
                }
            } catch (e: Exception) {
                Log.w(TAG, "could not read the picked file: $e")
                nativeCancelled()
            }
        }.start()
        return true
    }

    private fun read(a: Activity, uri: Uri) {
        val resolver = a.contentResolver
        var name = "attachment"
        var size = -1L
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(0)?.let { name = it }
                    if (!cursor.isNull(1)) size = cursor.getLong(1)
                }
            }
        if (size > MAX_BYTES) {
            Log.w(TAG, "picked file too large: $size bytes")
            return nativeCancelled()
        }
        val mime = resolver.getType(uri) ?: "application/octet-stream"
        val bytes = resolver.openInputStream(uri)?.use { it.readBytes() }
            ?: return nativeCancelled()
        send(name, mime, bytes)
    }

    private fun send(name: String, mime: String, bytes: ByteArray) {
        if (bytes.size > MAX_BYTES) return nativeCancelled()
        nativePicked(name, mime, bytes)
    }

    @JvmStatic external fun nativePicked(name: String, mime: String, bytes: ByteArray)
    @JvmStatic external fun nativeCancelled()
}
