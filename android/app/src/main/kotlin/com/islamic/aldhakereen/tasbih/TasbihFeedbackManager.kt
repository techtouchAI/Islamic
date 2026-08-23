package com.islamic.aldhakereen.tasbih

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator

/** Owns the native completion feedback used by the tasbih feature. */
class TasbihFeedbackManager(private val context: Context) {
    @Suppress("DEPRECATION")
    fun vibrateStageCompletion() {
        val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
        if (!vibrator.hasVibrator()) return

        val timings = longArrayOf(0L, 170L, 80L, 260L)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val amplitudes = intArrayOf(0, 255, 0, 255)
            vibrator.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
        } else {
            vibrator.vibrate(timings, -1)
        }
    }
}
