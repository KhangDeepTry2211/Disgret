package com.nhom.focus.focus_app

import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

/**
 * 7.1, 7.2, 2.1, 2.3, 2.4, 8.2 Bảng chỉ đường của MethodChannel "focus/native": nhận tên hàm từ Flutter rồi chuyển đến
 * đúng file Kotlin xử lý. Bản thân file này không chứa logic gì.
 */
class NativeChannel(
    private val activity: Activity,
    private val channel: MethodChannel,
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Flutter đã sẵn sàng nghe sự kiện onNativeAction
            "nativeReady" -> {
                NativeActions.flutterReady(channel)
                result.success(null)
            }

            // 7.1 Quyền truy cập
            "hasUsageAccess" -> result.success(AppPermissions.hasUsageAccess(activity))
            "openUsageAccessSettings" -> {
                AppPermissions.openUsageAccessSettings(activity)
                result.success(null)
            }
            "hasOverlayPermission" -> result.success(AppPermissions.hasOverlayPermission(activity))
            "openOverlaySettings" -> {
                AppPermissions.openOverlaySettings(activity)
                result.success(null)
            }
            "hasNotificationPermission" ->
                result.success(AppPermissions.hasNotificationPermission(activity))
            "requestNotificationPermission" -> {
                AppPermissions.requestNotificationPermission(activity)
                result.success(null)
            }

            // 2.1 Danh sách app. Đọc icon khá lâu nên làm ở luồng riêng để giao diện không bị đứng.
            "getLaunchableApps" -> thread {
                val apps = try {
                    InstalledApps.load(activity)
                } catch (error: RuntimeException) {
                    // Lỗi trên luồng riêng mà không bắt sẽ làm sập cả app.
                    Log.w(TAG, "Không đọc được danh sách app", error)
                    emptyList()
                }
                activity.runOnUiThread { result.success(apps) }
            }

            // 7.2 Theo dõi app đang mở
            "startGuard" -> {
                val blocked = call.argument<List<String>>("blockedPackages").orEmpty()
                val timeScale = call.argument<Int>("timeScale") ?: 1
                result.success(FocusGuardService.start(activity, blocked, timeScale))
            }
            "stopGuard" -> {
                FocusGuardService.stop(activity)
                result.success(null)
            }

            // 2.4 Nghỉ có chủ đích
            "startBreak" -> {
                val minutes = call.argument<Int>("minutes") ?: 0
                result.success(FocusGuardService.startBreak(minutes))
            }
            "endBreak" -> {
                FocusGuardService.endBreak()
                result.success(null)
            }

            // 2.3 Nút "Thử màn can thiệp" trong Cài đặt
            "showIntervention" -> {
                val appName = call.argument<String>("appName").orEmpty()
                InterventionActivity.openTrial(activity, appName)
                result.success(null)
            }

            // 8.2 Hàng đợi sự kiện
            "drainEvents" -> result.success(EventQueue.drain(activity))

            else -> result.notImplemented()
        }
    }

    companion object {
        const val NAME = "focus/native"
        private const val TAG = "NativeChannel"
    }
}
