package com.nhom.focus.focus_app

import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import kotlin.math.ceil

/**
 * 7.2 + 2.2 + 2.4 Foreground service chạy suốt phiên Focus, có hai chế độ:
 * - Chế độ chặn: mỗi giây đọc nhật ký của hệ thống xem app nào vừa lên màn hình, nếu thuộc
 *   danh sách chặn thì mở màn can thiệp (2.3).
 * - Chế độ nghỉ: không chặn app nào, thông báo đếm ngược giờ nghỉ. Hết giờ thì nhắc rồi
 *   quay về chế độ chặn.
 */
class FocusGuardService : Service() {

    /** Chạy ở luồng riêng để việc đọc nhật ký không làm giật giao diện của app. */
    private var checker: ScheduledExecutorService? = null
    private val mainThread = Handler(Looper.getMainLooper())
    private var startedAt = 0L

    @Volatile
    private var blockedPackages: Set<String> = emptySet()
    private var protectedPackages: Set<String> = emptySet()

    /** App đang ở trên màn hình theo lần đọc gần nhất. */
    private var foregroundApp: String? = null

    /** Số lần đã chặn trong phiên này, quyết định thời gian chờ của lần sau. */
    private var interventionCount = 0

    /** App bị chặn gần nhất và lúc đó, để nhận ra vẫn là cùng một lần mở app. */
    private var lastBlockedApp: String? = null
    private var lastBlockedAt = 0L

    /** Chế độ demo truyền xuống: giờ nghỉ chạy nhanh hơn đúng bằng đồng hồ của phiên. */
    @Volatile
    private var timeScale = 1

    /** Mốc hết giờ nghỉ; null nghĩa là đang ở chế độ chặn. */
    @Volatile
    private var breakEndsAt: Long? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        startedAt = SystemClock.elapsedRealtime()
        protectedPackages = InstalledApps.protectedPackages(this)
        createNotificationChannels()
        checker = Executors.newSingleThreadScheduledExecutor().also {
            it.scheduleWithFixedDelay(::checkSafely, 0, CHECK_INTERVAL_SECONDS, TimeUnit.SECONDS)
        }
    }

    /** Được gọi mỗi lần startGuard, kể cả khi service đang chạy và chỉ đổi danh sách chặn. */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        blockedPackages = intent?.getStringArrayListExtra(EXTRA_BLOCKED_PACKAGES)?.toSet().orEmpty()
        timeScale = intent?.getIntExtra(EXTRA_TIME_SCALE, 1) ?: 1
        enterForeground()
        // Hệ thống tắt service thì không tự bật lại, vì phiên học cũng đã mất theo.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        instance = null
        checker?.shutdownNow()
        cancelBreakEndedNotification(this) // Hết phiên thì không còn gì để quay lại.
        super.onDestroy()
    }

    private fun checkSafely() {
        // Lỗi không được bắt ở đây sẽ âm thầm dừng toàn bộ các lần kiểm tra sau.
        try {
            if (SystemClock.elapsedRealtime() - startedAt >= MAX_RUN_MILLIS) {
                stopSelf() // Đề phòng quên tắt.
            } else {
                check()
            }
        } catch (error: RuntimeException) {
            Log.w(TAG, "Không đọc được app đang mở", error)
        }
    }

    private fun check() {
        // Đang nghỉ vẫn phải theo dõi, để lúc hết giờ biết người dùng còn ở trong app bị chặn không.
        latestResumedApp()?.let { foregroundApp = it }
        val endsAt = breakEndsAt
        when {
            endsAt == null -> blockForegroundAppIfNeeded()
            SystemClock.elapsedRealtime() >= endsAt -> finishBreak()
            else -> refreshNotification()
        }
    }

    // ---------- 2.2 Phát hiện mở app ----------

    /**
     * Ở chế độ chặn, hễ app bị chặn đang ở trên cùng mà màn chặn không hiện thì phải mở.
     * Kiểm tra mỗi giây chứ không chỉ lúc đổi app, vì có app tự mở thêm màn của nó ngay sau khi
     * khởi động (ví dụ Chrome lần đầu chạy) và đè mất màn chặn vừa mở.
     */
    private fun blockForegroundAppIfNeeded() {
        val app = foregroundApp ?: return
        val shouldBlock = app in blockedPackages && app !in protectedPackages
        if (!shouldBlock || InterventionActivity.isShowing || !isUserLookingAtScreen()) return

        // Chống lặp: mở lại màn chặn vì lý do trên vẫn là cùng một lần mở app, nên không đếm thêm.
        val now = SystemClock.elapsedRealtime()
        val isNewOpening = app != lastBlockedApp || now - lastBlockedAt >= SAME_OPENING_MILLIS
        lastBlockedApp = app
        lastBlockedAt = now

        val appLabel = InstalledApps.labelOf(this, app)
        if (isNewOpening) recordIntervention(app, appLabel)
        InterventionActivity.open(this, appLabel, currentWaitSeconds())
    }

    private fun recordIntervention(packageName: String, appLabel: String) {
        interventionCount++
        EventQueue.add(
            this,
            EventQueue.INTERVENTION_SHOWN,
            mapOf(
                "packageName" to packageName,
                "appLabel" to appLabel,
                "waitSeconds" to currentWaitSeconds(),
            ),
        )
        NativeActions.send(NativeActions.INTERVENTION_SHOWN)
    }

    private fun currentWaitSeconds(): Int = minOf(
        FIRST_WAIT_SECONDS + (interventionCount - 1) * WAIT_STEP_SECONDS,
        MAX_WAIT_SECONDS,
    )

    /** Màn hình tắt hoặc đang khoá thì màn chặn vừa mở sẽ bị dừng ngay, mở nữa chỉ tốn pin. */
    private fun isUserLookingAtScreen(): Boolean {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return power.isInteractive && !keyguard.isKeyguardLocked
    }

    /** App lên màn hình gần nhất trong vài giây qua; không có gì mới thì trả về null. */
    private fun latestResumedApp(): String? {
        val usageStats = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val events = usageStats.queryEvents(now - LOOK_BACK_MILLIS, now) ?: return null

        var latestApp: String? = null
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                latestApp = event.packageName
            }
        }
        return latestApp
    }

    // ---------- 2.4 Nghỉ có chủ đích ----------

    private fun beginBreak(minutes: Int) {
        breakEndsAt = SystemClock.elapsedRealtime() + minutes * MILLIS_PER_MINUTE / timeScale
        cancelBreakEndedNotification(this) // Lời nhắc của lần nghỉ trước không còn đúng nữa.
        refreshNotification()
    }

    /** Người dùng tự quay lại học trước giờ: về chế độ chặn, không cần nhắc gì. */
    private fun cancelBreak() {
        breakEndsAt = null
        refreshNotification()
    }

    /**
     * Hết giờ nghỉ: nhắc người dùng, báo Flutter, rồi về chế độ chặn.
     * Người dùng còn ở trong app bị chặn thì lần kiểm tra kế tiếp sẽ chặn ngay.
     */
    private fun finishBreak() {
        breakEndsAt = null
        refreshNotification()
        showBreakEndedNotification()
        NativeActions.send(NativeActions.BREAK_ENDED)
    }

    /** Thời gian nghỉ còn lại dạng mm:ss, theo cùng thang thời gian với đồng hồ của phiên. */
    private fun breakTimeLeft(endsAt: Long): String {
        val millisLeft = (endsAt - SystemClock.elapsedRealtime()).coerceAtLeast(0) * timeScale
        val secondsLeft = ceil(millisLeft / 1000.0).toLong()
        return String.format(Locale.ROOT, "%02d:%02d", secondsLeft / 60, secondsLeft % 60)
    }

    // ---------- Thông báo ----------

    private fun enterForeground() {
        val notification = buildGuardNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                GUARD_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(GUARD_NOTIFICATION_ID, notification)
        }
    }

    /**
     * Đổi nội dung thông báo thường trực. Làm trên luồng chính, cùng luồng với onDestroy, để không
     * bao giờ đăng lại thông báo sau khi service đã dừng, khiến nó nằm mãi trên thanh thông báo.
     */
    private fun refreshNotification() {
        mainThread.post {
            if (instance === this) {
                notificationManager().notify(GUARD_NOTIFICATION_ID, buildGuardNotification())
            }
        }
    }

    /** Thông báo thường trực, bấm vào thì mở DisGret. */
    private fun buildGuardNotification(): Notification {
        val openApp = PendingIntent.getActivity(
            this,
            GUARD_NOTIFICATION_ID,
            MainActivity.openIntent(this),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val endsAt = breakEndsAt
        val title = if (endsAt == null) {
            getString(R.string.guard_notification_title)
        } else {
            getString(R.string.guard_break_title, breakTimeLeft(endsAt))
        }
        val builder = notificationBuilder(GUARD_CHANNEL_ID)
        // Mặc định Android 12+ giữ thông báo của service tới 10 giây rồi mới hiện.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }
        return builder
            .setSmallIcon(R.drawable.ic_stat_disgret)
            .setContentTitle(title)
            .setContentText(getString(R.string.guard_notification_text))
            .setContentIntent(openApp)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    /** Thông báo ưu tiên cao khi hết giờ nghỉ, bấm vào thì mở DisGret. */
    private fun showBreakEndedNotification() {
        val openApp = PendingIntent.getActivity(
            this,
            BREAK_ENDED_NOTIFICATION_ID,
            MainActivity.openIntent(this, NativeActions.BREAK_ENDED),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        @Suppress("DEPRECATION") // Android 7 chưa có kênh thông báo, mức ưu tiên đặt ở đây.
        val notification = notificationBuilder(BREAK_ENDED_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_disgret)
            .setContentTitle(getString(R.string.break_ended_title))
            .setContentText(getString(R.string.break_ended_text))
            .setContentIntent(openApp)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setPriority(Notification.PRIORITY_HIGH)
            .setDefaults(Notification.DEFAULT_ALL)
            .build()
        notificationManager().notify(BREAK_ENDED_NOTIFICATION_ID, notification)
    }

    private fun notificationBuilder(channelId: String): Notification.Builder =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val guardChannel = NotificationChannel(
            GUARD_CHANNEL_ID,
            getString(R.string.guard_channel_name),
            NotificationManager.IMPORTANCE_LOW, // Thông báo im lặng, không làm gián đoạn việc học.
        )
        guardChannel.setShowBadge(false)
        val breakEndedChannel = NotificationChannel(
            BREAK_ENDED_CHANNEL_ID,
            getString(R.string.break_ended_channel_name),
            NotificationManager.IMPORTANCE_HIGH, // Hiện nổi trên màn hình, có âm báo.
        )
        notificationManager().createNotificationChannels(listOf(guardChannel, breakEndedChannel))
    }

    private fun notificationManager(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    companion object {
        private const val TAG = "FocusGuardService"
        private const val GUARD_CHANNEL_ID = "focus_guard"
        private const val BREAK_ENDED_CHANNEL_ID = "focus_break_ended"
        private const val GUARD_NOTIFICATION_ID = 1
        private const val BREAK_ENDED_NOTIFICATION_ID = 2
        private const val EXTRA_BLOCKED_PACKAGES = "blocked_packages"
        private const val EXTRA_TIME_SCALE = "time_scale"
        private const val CHECK_INTERVAL_SECONDS = 1L
        private const val LOOK_BACK_MILLIS = 5_000L
        private const val MAX_RUN_MILLIS = 3 * 60 * 60 * 1_000L
        private const val MILLIS_PER_MINUTE = 60_000L
        private const val SAME_OPENING_MILLIS = 5_000L

        /** Thời gian chờ ở màn chặn: lần 1 chờ 10 giây, mỗi lần sau +5 giây, tối đa 30 giây. */
        const val FIRST_WAIT_SECONDS = 10
        private const val WAIT_STEP_SECONDS = 5
        private const val MAX_WAIT_SECONDS = 30

        /** Service đang chạy; màn can thiệp và Flutter ra lệnh nghỉ trực tiếp qua đây. */
        @Volatile
        private var instance: FocusGuardService? = null

        /** Bật service, hoặc cập nhật danh sách chặn nếu đang chạy. Trả về false nếu không bật được. */
        fun start(context: Context, blockedPackages: List<String>, timeScale: Int): Boolean {
            if (!AppPermissions.canGuard(context)) return false

            val intent = Intent(context, FocusGuardService::class.java)
                .putStringArrayListExtra(EXTRA_BLOCKED_PACKAGES, ArrayList(blockedPackages))
                .putExtra(EXTRA_TIME_SCALE, timeScale)
            return try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                true
            } catch (error: IllegalStateException) {
                // Android không cho bật service khi app đang ở nền.
                Log.w(TAG, "Không bật được service", error)
                false
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, FocusGuardService::class.java))
        }

        /** Chuyển sang chế độ nghỉ. Trả về false nếu service không chạy, ví dụ phiên vừa hết giờ. */
        fun startBreak(minutes: Int): Boolean {
            val service = instance ?: return false
            service.beginBreak(minutes)
            return true
        }

        fun endBreak() {
            instance?.cancelBreak()
        }

        fun cancelBreakEndedNotification(context: Context) {
            val notifications =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notifications.cancel(BREAK_ENDED_NOTIFICATION_ID)
        }
    }
}
