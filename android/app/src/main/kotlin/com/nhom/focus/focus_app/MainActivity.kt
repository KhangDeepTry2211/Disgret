package com.nhom.focus.focus_app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 5.1 Activity chính, nơi chạy toàn bộ giao diện Flutter. Ở đây chỉ làm ba việc: mở MethodChannel
 * "focus/native", đọc hành động kèm trong Intent, và dừng service khi Activity mất đi.
 */
class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeChannel.NAME)
        methodChannel.setMethodCallHandler(NativeChannel(this, methodChannel))
        channel = methodChannel
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        forwardAction(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        forwardAction(intent)
    }

    override fun onResume() {
        super.onResume()
        // Người dùng đã quay lại rồi, không cần nhắc hết giờ nghỉ nữa.
        FocusGuardService.cancelBreakEndedNotification(this)
    }

    override fun onDestroy() {
        // Phiên học nằm trong bộ nhớ của Flutter và mất cùng Activity này. Không còn phiên thì
        // cũng không còn ai gọi stopGuard, nên phải dừng service ở đây để khỏi chặn app oan.
        FocusGuardService.stop(this)
        NativeActions.flutterGone(channel)
        super.onDestroy()
    }

    /** Chuyển hành động trong Intent sang Flutter. Xoá sau khi đọc để không bị xử lý hai lần. */
    private fun forwardAction(intent: Intent) {
        val action = intent.getStringExtra(EXTRA_ACTION) ?: return
        intent.removeExtra(EXTRA_ACTION)
        // MainActivity mở được từ app khác nên chỉ nhận đúng các hành động của DisGret.
        if (action in ACTIONS_FROM_INTENT) NativeActions.send(action)
    }

    companion object {
        private const val EXTRA_ACTION = "native_action"
        private val ACTIONS_FROM_INTENT = setOf(
            NativeActions.RESUME_FOCUS,
            NativeActions.OPEN_REELS_DISTRACTED,
            NativeActions.BREAK_ENDED,
        )

        /**
         * Intent đưa DisGret lên trước, có thể kèm hành động cho Flutter.
         * App đang chạy thì dùng lại màn cũ, không tạo thêm.
         */
        fun openIntent(context: Context, action: String? = null): Intent {
            val intent = Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            if (action != null) intent.putExtra(EXTRA_ACTION, action)
            return intent
        }
    }
}
