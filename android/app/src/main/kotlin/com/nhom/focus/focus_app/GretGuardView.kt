package com.nhom.focus.focus_app

import android.animation.TimeAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.drawable.Drawable
import android.provider.Settings
import android.util.AttributeSet
import android.view.View
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

/**
 * 2.3 Màn can thiệp (spec 017): Gret swims in from the left, spreads its fins in front of the
 * blocked app, then breathes with the student inside the countdown ring (4 s in, 4 s out), its
 * tail wagging and a few bubbles rising. One TimeAnimator drives everything; with the system
 * "remove animations" setting Gret simply stands with its fins spread.
 * Gret's art comes from res/drawable/gret_tail.xml and gret_front.xml (converted from the app's
 * 3D mềm SVG layers, spec 018), so it matches the Flutter screens' default style.
 */
class GretGuardView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : View(context, attrs) {

    private val tail: Drawable = context.getDrawable(R.drawable.gret_tail)!!.mutate()
    private val front: Drawable = context.getDrawable(R.drawable.gret_front)!!.mutate()
    private val density = resources.displayMetrics.density

    private val ringTrack = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        color = context.getColor(R.color.intervention_ring_track)
    }
    private val ringFill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        color = context.getColor(R.color.disgret_sun)
    }
    private val finPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = context.getColor(R.color.gret_fin)
    }

    /** The fins' outline, a darker shade of the fin like the 3D mềm drawings (spec 018). */
    private val finOutline = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeJoin = Paint.Join.ROUND
        color = context.getColor(R.color.gret_fin_outline)
    }
    private val bubblePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 1.5f * density
        color = context.getColor(R.color.intervention_bubble)
    }
    private val finPath = Path()
    private val ringBox = RectF()

    private val animator = TimeAnimator()
    private var elapsed = 0L
    private var lastInhale: Boolean? = null

    /** False when the system "remove animations" setting is on. */
    val animationsOn: Boolean = Settings.Global.getFloat(
        context.contentResolver,
        Settings.Global.ANIMATOR_DURATION_SCALE,
        1f,
    ) > 0f

    /** Share of the wait still left, from 1 to 0, drawn as the sun-yellow ring. */
    var remaining = 1f
        set(value) {
            field = value.coerceIn(0f, 1f)
            invalidate()
        }

    /** Called with true at the start of each inhale and false at each exhale. */
    var onBreath: ((inhale: Boolean) -> Unit)? = null

    init {
        animator.setTimeListener { _, total, _ ->
            elapsed = total
            reportBreath()
            invalidate()
        }
    }

    /** Starts the entrance again, for a new block on the same screen. */
    fun restart() {
        elapsed = 0L
        lastInhale = null
        animator.cancel()
        if (animationsOn) animator.start() else invalidate()
    }

    override fun onDetachedFromWindow() {
        animator.cancel()
        super.onDetachedFromWindow()
    }

    private fun reportBreath() {
        if (elapsed < ENTRANCE_MILLIS) return
        val inhale = (elapsed - ENTRANCE_MILLIS) % BREATH_MILLIS < BREATH_MILLIS / 2
        if (inhale != lastInhale) {
            lastInhale = inhale
            onBreath?.invoke(inhale)
        }
    }

    override fun onDraw(canvas: Canvas) {
        val centreX = width / 2f
        val centreY = height / 2f
        val stroke = RING_WIDTH_DP * density
        val radius = min(width, height) / 2f - stroke
        ringTrack.strokeWidth = stroke
        ringFill.strokeWidth = stroke
        canvas.drawCircle(centreX, centreY, radius, ringTrack)
        ringBox.set(centreX - radius, centreY - radius, centreX + radius, centreY + radius)
        canvas.drawArc(ringBox, -90f, 360f * remaining, false, ringFill)

        if (animationsOn) drawBubbles(canvas, centreX, centreY, radius)

        val entrance = if (animationsOn) (elapsed / ENTRANCE_MILLIS.toFloat()).coerceIn(0f, 1f) else 1f
        val breath = if (animationsOn && elapsed > ENTRANCE_MILLIS) {
            val phase = ((elapsed - ENTRANCE_MILLIS) % BREATH_MILLIS) / BREATH_MILLIS.toFloat()
            SMALL + (LARGE - SMALL) * (0.5f - 0.5f * cos(phase * 2f * PI.toFloat()))
        } else {
            1f
        }
        val wag = if (animationsOn) sin(elapsed / TAIL_PERIOD) * TAIL_DEGREES else 0f

        val gretWidth = radius * GRET_SHARE
        val gretHeight = gretWidth * CANVAS_HEIGHT / CANVAS_WIDTH
        canvas.save()
        // Swims in from the left with a small overshoot, then holds its place.
        canvas.translate(centreX - width * (1f - easeOutBack(entrance)), centreY)
        canvas.scale(breath, breath)

        // Fins rise from the sides as Gret arrives, like arms spread to block the way.
        val finAngle = FIN_DEGREES * entrance
        drawFin(canvas, -gretWidth * 0.38f, gretHeight * 0.12f, -1f, finAngle, gretWidth)
        drawFin(canvas, gretWidth * 0.38f, gretHeight * 0.12f, 1f, finAngle, gretWidth)

        val left = (-gretWidth / 2f).toInt()
        val top = (-gretHeight / 2f).toInt()
        val right = left + gretWidth.toInt()
        val bottom = top + gretHeight.toInt()
        canvas.save()
        canvas.rotate(
            wag,
            left + gretWidth * TAIL_JOINT_X / CANVAS_WIDTH,
            top + gretHeight * TAIL_JOINT_Y / CANVAS_HEIGHT,
        )
        tail.setBounds(left, top, right, bottom)
        tail.draw(canvas)
        canvas.restore()
        front.setBounds(left, top, right, bottom)
        front.draw(canvas)
        canvas.restore()
    }

    /** A paddle-shaped fin pointing outwards from ([x], [y]); [side] is -1 left, 1 right. */
    private fun drawFin(canvas: Canvas, x: Float, y: Float, side: Float, angle: Float, size: Float) {
        val length = size * 0.34f
        finPath.reset()
        finPath.moveTo(0f, -length * 0.12f)
        finPath.quadTo(side * length * 0.6f, -length * 0.3f, side * length, -length * 0.05f)
        finPath.quadTo(side * length * 0.55f, length * 0.3f, 0f, length * 0.16f)
        finPath.close()
        canvas.save()
        canvas.translate(x, y)
        canvas.rotate(-side * angle)
        canvas.drawPath(finPath, finPaint)
        finOutline.strokeWidth = size / CANVAS_WIDTH * FIN_OUTLINE
        canvas.drawPath(finPath, finOutline)
        canvas.restore()
    }

    private fun drawBubbles(canvas: Canvas, centreX: Float, centreY: Float, radius: Float) {
        for (i in 0 until BUBBLES) {
            val progress = (elapsed / BUBBLE_MILLIS + i / BUBBLES.toFloat()) % 1f
            bubblePaint.alpha = ((1f - progress) * 200).toInt()
            canvas.drawCircle(
                centreX + radius * (-0.5f + 0.33f * i) + sin(progress * 8f + i) * 4f * density,
                centreY + radius * 0.75f - progress * radius * 1.4f,
                (3f + (i % 2) * 2f) * density,
                bubblePaint,
            )
        }
    }

    private fun easeOutBack(t: Float): Float {
        val overshoot = 1.4f
        val x = t - 1f
        return 1f + (overshoot + 1f) * x * x * x + overshoot * x * x
    }

    companion object {
        private const val ENTRANCE_MILLIS = 900L
        private const val BREATH_MILLIS = 8_000L
        private const val BUBBLE_MILLIS = 4_000f
        private const val BUBBLES = 4
        private const val SMALL = 0.92f
        private const val LARGE = 1.1f
        private const val TAIL_PERIOD = 180f
        private const val TAIL_DEGREES = 10f
        private const val FIN_DEGREES = 55f
        private const val RING_WIDTH_DP = 8f
        private const val GRET_SHARE = 1.25f

        /** Outline width of the fins on Gret's 240-wide canvas, as in assets/mascot/soft. */
        private const val FIN_OUTLINE = 3f

        /** Gret's shared canvas and where the tail meets the body (assets/mascot/gret). */
        private const val CANVAS_WIDTH = 240f
        private const val CANVAS_HEIGHT = 200f
        private const val TAIL_JOINT_X = 166f
        private const val TAIL_JOINT_Y = 112f
    }
}
