package com.nhom.focus.focus_app

import android.Manifest
import android.app.Activity
import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings

/**
 * 7.1 Quyền truy cập: kiểm tra và mở nơi cấp 3 quyền của Reset break.
 * Quyền xem app đang dùng và quyền hiện đè lên app khác không xin bằng hộp thoại được,
 * người dùng phải tự bật trong Cài đặt của máy, nên ở đây chỉ mở đúng trang cài đặt đó.
 */
object AppPermissions {
    private const val NOTIFICATION_REQUEST_CODE = 7001
    private const val PREFERENCES = "focus_native"
    private const val KEY_ASKED_NOTIFICATION = "asked_notification"

    /** Service chỉ cần 2 quyền này; thiếu thông báo thì vẫn chặn được, chỉ không thấy thông báo. */
    fun canGuard(context: Context): Boolean =
        hasUsageAccess(context) && hasOverlayPermission(context)

    fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun openUsageAccessSettings(activity: Activity) {
        val packageUri = Uri.parse("package:${activity.packageName}")
        try {
            // Mở thẳng trang của DisGret; máy nào không hỗ trợ thì mở danh sách chung.
            activity.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS, packageUri))
        } catch (error: ActivityNotFoundException) {
            activity.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        }
    }

    fun hasOverlayPermission(context: Context): Boolean = Settings.canDrawOverlays(context)

    fun openOverlaySettings(activity: Activity) {
        val packageUri = Uri.parse("package:${activity.packageName}")
        activity.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, packageUri))
    }

    fun hasNotificationPermission(context: Context): Boolean {
        val notifications =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return notifications.areNotificationsEnabled()
    }

    fun requestNotificationPermission(activity: Activity) {
        // Android 12 trở xuống không có hộp thoại xin quyền thông báo.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            openNotificationSettings(activity)
            return
        }

        val permission = Manifest.permission.POST_NOTIFICATIONS
        val preferences = activity.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val alreadyGranted =
            activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        // Đã từ chối hẳn thì hệ thống không hiện hộp thoại nữa, phải bật trong Cài đặt.
        val refusedForGood = preferences.getBoolean(KEY_ASKED_NOTIFICATION, false) &&
            !activity.shouldShowRequestPermissionRationale(permission)

        if (alreadyGranted || refusedForGood) {
            openNotificationSettings(activity)
        } else {
            preferences.edit().putBoolean(KEY_ASKED_NOTIFICATION, true).apply()
            activity.requestPermissions(arrayOf(permission), NOTIFICATION_REQUEST_CODE)
        }
    }

    private fun openNotificationSettings(activity: Activity) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
        } else {
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:${activity.packageName}"),
            )
        }
        activity.startActivity(intent)
    }
}
