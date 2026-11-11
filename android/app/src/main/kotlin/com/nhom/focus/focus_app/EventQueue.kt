package com.nhom.focus.focus_app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * 8.2 Hàng đợi sự kiện của phần native. Kotlin không ghi được vào Hive nên lưu tạm trong
 * SharedPreferences dưới dạng JSON; Flutter lấy về bằng drainEvents mỗi khi app quay lại.
 */
object EventQueue {
    const val INTERVENTION_SHOWN = "intervention_shown"
    const val CHOSE_STUDY = "chose_study"
    const val CHOSE_REEL = "chose_reel"
    const val CHOSE_BREAK = "chose_break"

    private const val PREFERENCES = "focus_native_events"
    private const val KEY_EVENTS = "events"
    private const val EMPTY = "[]"

    /** Service và màn can thiệp chạy ở hai luồng khác nhau nên phải ghi lần lượt. */
    @Synchronized
    fun add(context: Context, type: String, meta: Map<String, Any> = emptyMap()) {
        val preferences = preferencesOf(context)
        val events = JSONArray(preferences.getString(KEY_EVENTS, EMPTY))
        events.put(
            JSONObject()
                .put("type", type)
                .put("time", System.currentTimeMillis())
                .put("meta", JSONObject(meta)),
        )
        preferences.edit().putString(KEY_EVENTS, events.toString()).apply()
    }

    /** Trả về toàn bộ hàng đợi dạng JSON rồi xoá. */
    @Synchronized
    fun drain(context: Context): String {
        val preferences = preferencesOf(context)
        val events = preferences.getString(KEY_EVENTS, EMPTY) ?: EMPTY
        preferences.edit().remove(KEY_EVENTS).apply()
        return events
    }

    private fun preferencesOf(context: Context) =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
}
