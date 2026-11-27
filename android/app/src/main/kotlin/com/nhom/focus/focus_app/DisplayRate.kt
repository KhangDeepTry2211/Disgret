package com.nhom.focus.focus_app

import android.app.Activity
import android.os.Build
import android.view.Display

/**
 * 5.1 Tần số quét: asks Android for the screen's fastest refresh rate at the current resolution
 * (90/120 Hz on phones that have it), so scrolling and the sea's animations are as smooth as the
 * screen allows. Many phones keep an app at 60 Hz unless it asks. Android may still lower it, for
 * example in battery saver; screens with a single mode keep it.
 */
object DisplayRate {

    fun preferHighest(activity: Activity) {
        val display: Display = (
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                activity.display
            } else {
                @Suppress("DEPRECATION")
                activity.windowManager.defaultDisplay
            }
            ) ?: return
        val current = display.mode
        val fastest = display.supportedModes
            .filter {
                it.physicalWidth == current.physicalWidth && it.physicalHeight == current.physicalHeight
            }
            .maxByOrNull { it.refreshRate } ?: return
        val attributes = activity.window.attributes
        if (attributes.preferredDisplayModeId == fastest.modeId) return
        attributes.preferredDisplayModeId = fastest.modeId
        activity.window.attributes = attributes
    }
}
