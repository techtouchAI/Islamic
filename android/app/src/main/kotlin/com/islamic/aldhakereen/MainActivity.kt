package com.islamic.aldhakereen

import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.islamic.aldhakereen.qibla.QiblaSensorManager
import com.islamic.aldhakereen.hijri.HijriNativeManager
import com.islamic.aldhakereen.hijri.HijriEventsDatabase
import com.islamic.aldhakereen.adhan.AdhanNativeManager

class MainActivity : FlutterActivity() {
    private val ADHAN_CHANNEL = "com.techtouchai.islamic/adhan"
    private val HIJRI_CHANNEL = "com.techtouchai.islamic/hijri"
    private val QIBLA_CHANNEL = "com.techtouchai.islamic/qibla"
    private val TASBIH_FEEDBACK_CHANNEL = "com.techtouchai.islamic/tasbih_feedback"

    private lateinit var qiblaSensorManager: QiblaSensorManager
    private lateinit var hijriNativeManager: HijriNativeManager
    private lateinit var adhanNativeManager: AdhanNativeManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        qiblaSensorManager = QiblaSensorManager(this)
        hijriNativeManager = HijriNativeManager(this)
        adhanNativeManager = AdhanNativeManager(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Adhan MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ADHAN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAdhan" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val timeInMillis = call.argument<Long>("timeInMillis") ?: 0L
                    val localTimeInMillis = call.argument<Long>("localTimeInMillis") ?: timeInMillis
                    val timezoneOffsetMinutes = call.argument<Int>("timezoneOffsetMinutes") ?: 0
                    val timezoneUsesDevice = call.argument<Boolean>("timezoneUsesDevice") ?: false
                    val prayerName = call.argument<String>("prayerName") ?: ""
                    val fullScreen = call.argument<Boolean>("fullScreen") ?: false
                    val volume = call.argument<Double>("volume") ?: 1.0
                    val preAlertMinutes = call.argument<Int>("preAlertMinutes") ?: 0
                    adhanNativeManager.scheduleAdhan(
                        id,
                        timeInMillis,
                        localTimeInMillis,
                        timezoneOffsetMinutes,
                        prayerName,
                        timezoneUsesDevice,
                        fullScreen,
                        volume,
                        preAlertMinutes,
                    )
                    result.success(null)
                }
                "cancelAdhan" -> {
                    val id = call.argument<Int>("id") ?: 0
                    adhanNativeManager.cancelAdhan(id)
                    result.success(null)
                }
                "checkExactAlarmPermission" -> {
                    result.success(adhanNativeManager.checkExactAlarmPermission())
                }
                "openExactAlarmSettings" -> {
                    adhanNativeManager.openExactAlarmSettings()
                    result.success(null)
                }
                "checkFullScreenPermission" -> {
                    result.success(adhanNativeManager.checkFullScreenPermission())
                }
                "openNotificationSettings" -> {
                    val intent = Intent().apply {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                            putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                        } else {
                            action = "android.settings.APP_NOTIFICATION_SETTINGS"
                            putExtra("app_package", context.packageName)
                            putExtra("app_uid", context.applicationInfo.uid)
                        }
                    }
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Hijri MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HIJRI_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getHijriDate" -> {
                    val manualOffset = call.argument<Int>("manualOffset") ?: 0
                    result.success(hijriNativeManager.getHijriDate(manualOffset))
                }
                "getEvents" -> {
                    result.success(HijriEventsDatabase.majorEvents)
                }
                else -> result.notImplemented()
            }
        }

        // A dual-pulse waveform gives end-of-stage feedback without
        // vibrating during ordinary tasbih counting.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TASBIH_FEEDBACK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "vibrateStageCompletion" -> {
                    vibrateTasbihStageCompletion()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Qibla EventChannel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, QIBLA_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (events != null) {
                        qiblaSensorManager.start(events)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    qiblaSensorManager.stop()
                }
            }
        )
    }

    override fun onResume() {
        super.onResume()
        if (::adhanNativeManager.isInitialized) {
            adhanNativeManager.restoreSavedAlarms()
        }
    }

    @Suppress("DEPRECATION")
    private fun vibrateTasbihStageCompletion() {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
        if (!vibrator.hasVibrator()) return

        // 170ms + 260ms active pulses with an 80ms pause provide 430ms of
        // clearly perceptible feedback without an uncomfortably long buzz.
        val timings = longArrayOf(0L, 170L, 80L, 260L)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val amplitudes = intArrayOf(0, 255, 0, 255)
            vibrator.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
        } else {
            vibrator.vibrate(timings, -1)
        }
    }
}
