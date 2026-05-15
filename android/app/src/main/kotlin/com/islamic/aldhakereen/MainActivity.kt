package com.islamic.aldhakereen

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
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
                    val prayerName = call.argument<String>("prayerName") ?: ""
                    adhanNativeManager.scheduleAdhan(id, timeInMillis, prayerName)
                    result.success(null)
                }
                "cancelAdhan" -> {
                    val id = call.argument<Int>("id") ?: 0
                    adhanNativeManager.cancelAdhan(id)
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
}
