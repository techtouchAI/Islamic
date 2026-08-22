package com.islamic.aldhakereen.adhan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AdhanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val manager = AdhanNativeManager(context.applicationContext)
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_DATE_CHANGED ||
            action == AdhanNativeManager.ACTION_RESTORE_ALARMS
        ) {
            manager.restoreSavedAlarms(timezoneChanged = action == Intent.ACTION_TIMEZONE_CHANGED)
            return
        }

        if (action != AdhanNativeManager.ACTION_FIRE_ADHAN) return

        val serviceIntent = Intent(context, AdhanForegroundService::class.java).apply {
            putExtra("id", intent.getIntExtra("id", 0))
            putExtra("prayerId", intent.getIntExtra("prayerId", 0))
            putExtra("prayerName", intent.getStringExtra("prayerName"))
            putExtra("fullScreen", intent.getBooleanExtra("fullScreen", false))
            putExtra("volume", intent.getDoubleExtra("volume", 1.0))
            putExtra("isPreAlert", intent.getBooleanExtra("isPreAlert", false))
            putExtra("localTimeInMillis", intent.getLongExtra("localTimeInMillis", 0L))
            putExtra("timezoneOffsetMinutes", intent.getIntExtra("timezoneOffsetMinutes", 0))
            putExtra("preAlertMinutes", intent.getIntExtra("preAlertMinutes", 0))
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
