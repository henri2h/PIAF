package dev.piaf.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.text.InputType
import android.util.Log
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.BaseInputConnection
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import android.view.inputmethod.InputMethodManager
import java.lang.ref.WeakReference

/**
 * Invisible editor the soft keyboard talks to. NativeActivity has no
 * InputConnection: without one the keyboard sends raw key events only (no
 * suggestions, no swipe typing, and characters without a key, like é, are
 * lost). Freya draws the text; everything typed is forwarded to Rust.
 */
class ImeInputView(context: Context) : View(context) {
    /** Text and cursor (UTF-16) the keyboard sees, mirrored from the composer. */
    private var text = ""
    private var cursor = 0
    private var connection: Connection? = null
    /** Bumped when the composer re-syncs: callbacks of older connections are dropped. */
    var generation = 0

    init {
        isFocusable = true
        isFocusableInTouchMode = true
    }

    override fun onCheckIsTextEditor() = true

    override fun onCreateInputConnection(outAttrs: EditorInfo): InputConnection {
        outAttrs.inputType = InputType.TYPE_CLASS_TEXT or
            InputType.TYPE_TEXT_FLAG_MULTI_LINE or
            InputType.TYPE_TEXT_FLAG_CAP_SENTENCES or
            InputType.TYPE_TEXT_FLAG_AUTO_CORRECT
        outAttrs.imeOptions = EditorInfo.IME_FLAG_NO_FULLSCREEN or EditorInfo.IME_FLAG_NO_ENTER_ACTION
        outAttrs.initialSelStart = cursor
        outAttrs.initialSelEnd = cursor
        return Connection(this, this).also {
            it.editable?.let { e ->
                e.replace(0, e.length, text)
                android.text.Selection.setSelection(e, cursor.coerceIn(0, text.length))
            }
            connection = it
        }
    }

    /** The composer's text changed outside the keyboard (send, draft, cursor tap). */
    fun setState(text: String, cursor: Int) {
        this.text = text
        this.cursor = cursor
    }

    /**
     * After each keyboard edit: what a new connection starts from (Android
     * recreates it on its own), or the keyboard would edit stale text.
     */
    private fun remember(e: android.text.Editable?) {
        e ?: return
        text = e.toString()
        cursor = android.text.Selection.getSelectionEnd(e).coerceAtLeast(0)
    }

    private class Connection(view: View, private val owner: ImeInputView) : BaseInputConnection(view, true) {
        private val generation = owner.generation
        /** Still the connection the composer knows (a re-sync replaced the others). */
        private fun current() = generation == owner.generation

        /**
         * After the mirror changed: tells Rust, and remembers the text for the
         * next connection. A replaced connection does neither: it would
         * overwrite the state the composer just synced.
         */
        private fun forward(send: () -> Unit) {
            if (!current()) return
            owner.remember(editable)
            send()
        }

        override fun commitText(text: CharSequence, newCursorPosition: Int): Boolean {
            super.commitText(text, newCursorPosition)
            forward { ImeBridge.nativeImeCommit(text.toString()) }
            return true
        }

        override fun setComposingText(text: CharSequence, newCursorPosition: Int): Boolean {
            super.setComposingText(text, newCursorPosition)
            forward { ImeBridge.nativeImePreedit(text.toString()) }
            return true
        }

        /** Re-edits a word already typed (cursor moved into it): it becomes the composition. */
        override fun setComposingRegion(start: Int, end: Int): Boolean {
            super.setComposingRegion(start, end)
            forward { ImeBridge.nativeImeComposingRegion(start, end) }
            return true
        }

        /** The keyboard moved the cursor (space bar swipe, suggestion picked). */
        override fun setSelection(start: Int, end: Int): Boolean {
            super.setSelection(start, end)
            forward { ImeBridge.nativeImeSelect(start, end) }
            return true
        }

        override fun finishComposingText(): Boolean {
            val composing = editable?.let { e ->
                val start = BaseInputConnection.getComposingSpanStart(e)
                val end = BaseInputConnection.getComposingSpanEnd(e)
                if (start in 0..end) e.subSequence(start, end).toString() else ""
            } ?: ""
            super.finishComposingText()
            // The composition is kept as typed.
            forward { if (composing.isNotEmpty()) ImeBridge.nativeImeCommit(composing) }
            return true
        }

        override fun deleteSurroundingText(beforeLength: Int, afterLength: Int): Boolean {
            super.deleteSurroundingText(beforeLength, afterLength)
            forward { ImeBridge.nativeImeDelete(beforeLength, afterLength) }
            return true
        }

        /**
         * Keys the keyboard sends as events (backspace on an empty word, enter):
         * applied to the mirror too, or its positions drift from the composer's.
         */
        override fun sendKeyEvent(event: KeyEvent): Boolean {
            if (event.action != KeyEvent.ACTION_DOWN) return true
            when (event.keyCode) {
                KeyEvent.KEYCODE_DEL -> {
                    super.deleteSurroundingText(1, 0)
                    forward { ImeBridge.nativeImeDelete(1, 0) }
                }
                KeyEvent.KEYCODE_FORWARD_DEL -> {
                    super.deleteSurroundingText(0, 1)
                    forward { ImeBridge.nativeImeDelete(0, 1) }
                }
                KeyEvent.KEYCODE_ENTER, KeyEvent.KEYCODE_NUMPAD_ENTER -> {
                    super.commitText("\n", 1)
                    forward { ImeBridge.nativeImeCommit("\n") }
                }
                else -> {
                    val char = event.unicodeChar
                    if (char != 0) {
                        val text = String(Character.toChars(char))
                        super.commitText(text, 1)
                        forward { ImeBridge.nativeImeCommit(text) }
                    }
                }
            }
            return true
        }
    }
}

/** Rust ↔ keyboard: Rust shows / hides it for the composer, the keyboard sends text to Rust. */
object ImeBridge {
    private const val TAG = "PiafIme"
    private var view = WeakReference<ImeInputView>(null)
    private val main = Handler(Looper.getMainLooper())

    fun attach(v: ImeInputView) {
        view = WeakReference(v)
    }

    private fun post(action: (ImeInputView, InputMethodManager) -> Unit) {
        main.post {
            val v = view.get() ?: run {
                Log.d(TAG, "no input view")
                return@post
            }
            action(v, v.context.getSystemService(InputMethodManager::class.java))
        }
    }

    /** The composer got focus: show the keyboard on its text. */
    @JvmStatic
    fun show(text: String, cursor: Int) = post { v, imm ->
        v.generation++
        v.setState(text, cursor)
        v.requestFocus()
        imm.restartInput(v)
        imm.showSoftInput(v, 0)
    }

    @JvmStatic
    fun hide() = post { v, imm ->
        imm.hideSoftInputFromWindow(v.windowToken, 0)
        v.clearFocus()
    }

    /** The composer's text or cursor changed outside the keyboard. */
    @JvmStatic
    fun sync(text: String, cursor: Int) = post { v, imm ->
        v.generation++
        v.setState(text, cursor)
        if (v.hasFocus()) imm.restartInput(v)
    }

    @JvmStatic external fun nativeImeCommit(text: String)
    @JvmStatic external fun nativeImePreedit(text: String)
    @JvmStatic external fun nativeImeDelete(before: Int, after: Int)
    @JvmStatic external fun nativeImeComposingRegion(start: Int, end: Int)
    @JvmStatic external fun nativeImeSelect(start: Int, end: Int)
}
