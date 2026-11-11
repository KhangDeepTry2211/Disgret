package com.nhom.focus.focus_app

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import java.io.ByteArrayOutputStream

/**
 * 2.1 Danh sách app: đọc các app có biểu tượng ngoài màn hình chính và tên hiển thị của chúng.
 * Cũng là nơi quy định những app không bao giờ được chặn.
 */
object InstalledApps {
    private const val ICON_SIZE_PX = 96
    private const val SYSTEM_UI_PACKAGE = "com.android.systemui"

    /** Trả về danh sách để gửi sang Flutter, mỗi app gồm packageName, name và icon (PNG). */
    fun load(context: Context): List<Map<String, Any>> {
        val packageManager = context.packageManager
        val neverBlocked = protectedPackages(context)

        return activitiesWithCategory(context, Intent.CATEGORY_LAUNCHER)
            .distinctBy { it.activityInfo.packageName } // App có nhiều biểu tượng chỉ hiện một lần.
            .filter { it.activityInfo.packageName !in neverBlocked }
            .map { app ->
                mapOf(
                    "packageName" to app.activityInfo.packageName,
                    "name" to app.loadLabel(packageManager).toString(),
                    "icon" to toPng(app.loadIcon(packageManager)),
                )
            }
    }

    /** Không bao giờ chặn chính DisGret, launcher và System UI. */
    fun protectedPackages(context: Context): Set<String> {
        val launchers = activitiesWithCategory(context, Intent.CATEGORY_HOME)
            .map { it.activityInfo.packageName }
        return launchers.toSet() + context.packageName + SYSTEM_UI_PACKAGE
    }

    /** Tên hiển thị của app; không đọc được thì dùng tạm packageName. */
    fun labelOf(context: Context, packageName: String): String {
        val packageManager = context.packageManager
        return try {
            @Suppress("DEPRECATION")
            val info = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (error: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    private fun activitiesWithCategory(context: Context, category: String): List<ResolveInfo> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(category)
        @Suppress("DEPRECATION")
        return context.packageManager.queryIntentActivities(intent, 0)
    }

    private fun toPng(icon: Drawable): ByteArray {
        val bitmap = Bitmap.createBitmap(ICON_SIZE_PX, ICON_SIZE_PX, Bitmap.Config.ARGB_8888)
        icon.setBounds(0, 0, ICON_SIZE_PX, ICON_SIZE_PX)
        icon.draw(Canvas(bitmap))

        val bytes = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, bytes)
        bitmap.recycle()
        return bytes.toByteArray()
    }
}
