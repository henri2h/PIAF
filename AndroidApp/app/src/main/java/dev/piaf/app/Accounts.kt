package dev.piaf.app

import android.content.Context
import org.json.JSONException
import org.json.JSONObject
import org.unifiedpush.android.connector.INSTANCE_DEFAULT
import org.unifiedpush.android.connector.UnifiedPush
import java.io.File

/**
 * The signed-in accounts, read from the registry the Rust side keeps
 * (`utils/accounts.rs`). Each account has its own UnifiedPush instance (its
 * id), so pushes say which account they are for.
 */
object Accounts {
    private const val PREFS = "piaf_push_instances"
    private const val KEY_INSTANCES = "instances"

    private fun root(context: Context) = File(context.filesDir, "persist_session")

    private fun registry(context: Context): JSONObject? = try {
        JSONObject(File(root(context), "accounts.json").readText())
    } catch (_: Exception) { null }

    /** Accounts not signed out by the server. */
    fun ids(context: Context): List<String> {
        val accounts = registry(context)?.optJSONArray("accounts") ?: return emptyList()
        return try {
            (0 until accounts.length())
                .map { accounts.getJSONObject(it) }
                .filter { !it.optBoolean("expired") }
                .map { it.getString("id") }
        } catch (_: JSONException) { emptyList() }
    }

    fun active(context: Context): String? =
        registry(context)?.optString("active")?.takeIf { it.isNotBlank() }

    /** The account of a push instance: the instance shared before accounts existed is the active one's. */
    fun resolve(context: Context, instance: String): String? =
        if (instance in ids(context)) instance else active(context)

    /** The account's directory: session, push endpoint and gateway. */
    fun dir(context: Context, id: String) = File(root(context), "accounts/$id")

    /**
     * One UnifiedPush instance per account; the ones of signed-out accounts,
     * and the single one used before accounts, are unregistered.
     */
    fun registerPush(context: Context) {
        val ids = ids(context)
        if (ids.isEmpty()) return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val registered = prefs.getStringSet(KEY_INSTANCES, setOf(INSTANCE_DEFAULT))!!
        for (stale in registered - ids.toSet()) UnifiedPush.unregister(context, stale)
        for (id in ids) UnifiedPush.register(context, id)
        prefs.edit().putStringSet(KEY_INSTANCES, ids.toSet()).apply()
    }
}
