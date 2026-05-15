package com.islamic.aldhakereen.adhan

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

class AdhanNativeManager(private val context: Context) {

    fun scheduleAdhan(id: Int, timeInMillis: Long, prayerName: String, fullScreen: Boolean = false, volume: Double = 1.0, preAlertMinutes: Int = 0) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AdhanReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("prayerName", prayerName)
            putExtra("fullScreen", fullScreen)
            putExtra("volume", volume)
        }

        val triggerTime = timeInMillis - (preAlertMinutes * 60 * 1000L)

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Exact native logic bypasses Doze using AlarmClockInfo
        val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerTime, pendingIntent)
        alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
    }

    fun cancelAdhan(id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AdhanReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }
}
