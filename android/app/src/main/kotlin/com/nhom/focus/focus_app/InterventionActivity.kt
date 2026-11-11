package com.nhom.focus.focus_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.view.View
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import android.window.OnBackInvokedDispatcher
import kotlin.math.ceil

/**
 * 2.3 Màn can thiệp: hiện đè lên app vừa mở, bắt người dùng dừng lại vài giây rồi cho chọn
 * quay lại học, xem 1 reel động lực, hoặc nghỉ có chủ đích.
 * Giao diện nằm trong res/layout/activity_intervention.xml.
 */
class InterventionActivity : Activity() {

    private var countdown: CountDownTimer? = null

    /** Mở từ nút "Thử màn can thiệp": không ghi sự kiện, không ảnh hưởng tới phiên học. */
    private val isTrial: Boolean
        get() = intent.getBooleanExtra(EXTRA_IS_TRIAL, false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        isShowing = true
        setContentView(R.layout.activity_intervention)
        setUpChoices()
        setUpBreakOptions()
        showForCurrentIntent()

        // Từ Android 13, nút Back của hệ thống đi qua callback này thay vì onBackPressed.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT,
            ) { returnToStudy() }
        }
    }

    /** Màn này chỉ có một bản: nếu bản cũ còn nằm dưới app khác thì được dùng lại với app mới. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        showForCurrentIntent()
    }

    @Deprecated("Chỉ còn dùng cho Android 12 trở xuống")
    override fun onBackPressed() {
        returnToStudy()
    }

    /** Hiện tên app và đếm ngược từ đầu; các lựa chọn chờ đếm xong mới hiện. */
    private fun showForCurrentIntent() {
        val appName = intent.getStringExtra(EXTRA_APP_NAME).orEmpty()
        findViewById<TextView>(R.id.intervention_app_name).text = appName
        findViewById<TextView>(R.id.intervention_question).text =
            getString(R.string.intervention_question, appName)

        findViewById<View>(R.id.intervention_countdown_panel).visibility = View.VISIBLE
        findViewById<View>(R.id.intervention_choices).visibility = View.GONE
        findViewById<View>(R.id.intervention_break_options).visibility = View.GONE
        startCountdown(intent.getIntExtra(EXTRA_WAIT_SECONDS, FocusGuardService.FIRST_WAIT_SECONDS))
    }

    private fun setUpChoices() {
        findViewById<Button>(R.id.intervention_back_button).setOnClickListener { returnToStudy() }
        findViewById<Button>(R.id.intervention_reel_button).setOnClickListener { watchReel() }
        findViewById<Button>(R.id.intervention_break_button).setOnClickListener { showBreakOptions() }
    }

    private fun setUpBreakOptions() {
        val options = mapOf(
            R.id.intervention_break_5 to 5,
            R.id.intervention_break_10 to 10,
            R.id.intervention_break_15 to 15,
        )
        options.forEach { (buttonId, minutes) ->
            val button = findViewById<Button>(buttonId)
            button.text = getString(R.string.intervention_break_minutes, minutes)
            button.setOnClickListener { takeBreak(minutes) }
        }
        findViewById<Button>(R.id.intervention_break_cancel).setOnClickListener { showChoices() }
    }

    private fun startCountdown(waitSeconds: Int) {
        val countdownText = findViewById<TextView>(R.id.intervention_countdown)
        countdownText.text = waitSeconds.toString()
        countdown?.cancel()
        countdown = object : CountDownTimer(waitSeconds * MILLIS_PER_SECOND, COUNTDOWN_STEP_MILLIS) {
            override fun onTick(millisLeft: Long) {
                countdownText.text = ceil(millisLeft / 1000.0).toInt().toString()
            }

            override fun onFinish() {
                findViewById<View>(R.id.intervention_countdown_panel).visibility = View.GONE
                showChoices()
            }
        }.start()
    }

    private fun showChoices() {
        findViewById<View>(R.id.intervention_choices).visibility = View.VISIBLE
        findViewById<View>(R.id.intervention_break_options).visibility = View.GONE
    }

    private fun showBreakOptions() {
        findViewById<View>(R.id.intervention_choices).visibility = View.GONE
        findViewById<View>(R.id.intervention_break_options).visibility = View.VISIBLE
    }

    /** Đưa DisGret lên trước rồi đóng màn chặn. */
    private fun returnToStudy() {
        logChoice(EventQueue.CHOSE_STUDY)
        startActivity(MainActivity.openIntent(this, NativeActions.RESUME_FOCUS))
        finish()
    }

    /** Mở DisGret và chuyển thẳng tới Reels. */
    private fun watchReel() {
        logChoice(EventQueue.CHOSE_REEL)
        startActivity(MainActivity.openIntent(this, NativeActions.OPEN_REELS_DISTRACTED))
        finish()
    }

    /**
     * Người dùng đã chọn nghỉ thì đóng màn chặn để họ vào đúng app vừa mở, không kéo về DisGret.
     * Vì DisGret không mở lên nên hành động đi thẳng qua kênh thay vì qua Intent.
     */
    private fun takeBreak(minutes: Int) {
        if (isTrial) {
            Toast.makeText(this, R.string.intervention_trial_break, Toast.LENGTH_LONG).show()
            startActivity(MainActivity.openIntent(this))
        } else if (FocusGuardService.startBreak(minutes)) {
            EventQueue.add(this, EventQueue.CHOSE_BREAK, mapOf("minutes" to minutes))
            NativeActions.send(NativeActions.BREAK_STARTED, minutes)
        } else {
            // Phiên vừa hết giờ trong lúc đang ở màn này: không còn gì để nghỉ, về xem tổng kết.
            startActivity(MainActivity.openIntent(this))
        }
        finish()
    }

    private fun logChoice(type: String) {
        if (!isTrial) EventQueue.add(this, type)
    }

    override fun onStop() {
        super.onStop()
        // Người dùng bấm Home hoặc tắt màn hình: màn này xong việc. Lần mở app sau sẽ có màn mới
        // với đếm ngược từ đầu, không để một màn cũ nằm chờ ở phía sau.
        finish()
    }

    override fun onDestroy() {
        countdown?.cancel()
        isShowing = false
        super.onDestroy()
    }

    companion object {
        private const val EXTRA_APP_NAME = "app_name"
        private const val EXTRA_WAIT_SECONDS = "wait_seconds"
        private const val EXTRA_IS_TRIAL = "is_trial"
        private const val MILLIS_PER_SECOND = 1_000L
        private const val COUNTDOWN_STEP_MILLIS = 200L

        /** FocusGuardService đọc cờ này để không mở chồng màn chặn lên nhau. */
        @Volatile
        var isShowing = false
            private set

        fun open(context: Context, appName: String, waitSeconds: Int) {
            context.startActivity(intentFor(context, appName, waitSeconds))
        }

        /** Nút "Thử màn can thiệp" trong Cài đặt. */
        fun openTrial(context: Context, appName: String) {
            val intent = intentFor(context, appName, FocusGuardService.FIRST_WAIT_SECONDS)
                .putExtra(EXTRA_IS_TRIAL, true)
            context.startActivity(intent)
        }

        private fun intentFor(context: Context, appName: String, waitSeconds: Int): Intent =
            Intent(context, InterventionActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                .putExtra(EXTRA_APP_NAME, appName)
                .putExtra(EXTRA_WAIT_SECONDS, waitSeconds)
    }
}
