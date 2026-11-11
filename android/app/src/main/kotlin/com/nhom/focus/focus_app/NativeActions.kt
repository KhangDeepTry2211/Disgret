package com.nhom.focus.focus_app

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/**
 * 2.3, 2.4 Truyền hành động từ Kotlin sang Flutter qua sự kiện onNativeAction của kênh "focus/native".
 * Flutter báo sẵn sàng bằng hàm nativeReady; trước lúc đó mọi hành động được giữ lại rồi gửi sau,
 * ví dụ khi bấm thông báo làm app mở lại từ đầu.
 */
object NativeActions {
    const val INTERVENTION_SHOWN = "intervention_shown"
    const val RESUME_FOCUS = "resume_focus"
    const val OPEN_REELS_DISTRACTED = "open_reels_distracted"
    const val BREAK_STARTED = "break_started"
    const val BREAK_ENDED = "break_ended"

    private const val METHOD = "onNativeAction"

    private val mainThread = Handler(Looper.getMainLooper())

    // Hai biến dưới chỉ được đụng tới trên luồng chính nên không cần khoá.
    private var readyChannel: MethodChannel? = null
    private val pending = mutableListOf<Map<String, Any>>()

    fun send(action: String, minutes: Int? = null) {
        val message = buildMap {
            put("action", action)
            if (minutes != null) put("minutes", minutes)
        }
        runOnMainThread {
            val channel = readyChannel
            if (channel != null) channel.invokeMethod(METHOD, message) else pending.add(message)
        }
    }

    /** Flutter đã nghe được: gửi nốt những gì đang giữ. */
    fun flutterReady(channel: MethodChannel) {
        readyChannel = channel
        pending.forEach { channel.invokeMethod(METHOD, it) }
        pending.clear()
    }

    /** Flutter của Activity này đã mất, từ giờ phải giữ lại chờ bản mới. */
    fun flutterGone(channel: MethodChannel?) {
        if (readyChannel === channel) readyChannel = null
    }

    /**
     * Đang ở luồng chính thì gửi ngay chứ không xếp hàng: hành động đọc từ Intent nhờ vậy tới
     * Flutter trước khi Activity báo đã hiện lại, tránh chớp màn cũ rồi mới chuyển sang Reels.
     */
    private fun runOnMainThread(task: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) task() else mainThread.post(task)
    }
}
