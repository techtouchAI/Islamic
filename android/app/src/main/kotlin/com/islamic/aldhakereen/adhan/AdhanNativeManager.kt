package com.islamic.aldhakereen.adhan

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Owns all native alarms. Each alarm is deterministic and can be rebuilt from
 * the persisted record after a reboot, app update, date change or timezone change.
 */
class AdhanNativeManager(private val context: Context) {
    private val tag = "AdhanNativeManager"
    private val alarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun scheduleAdhan(
        id: Int,
        timeInMillis: Long,
        localTimeInMillis: Long,
        timezoneOffsetMinutes: Int,
        prayerName: String,
        timezoneUsesDevice: Boolean = false,
        fullScreen: Boolean = false,
        volume: Double = 1.0,
        preAlertMinutes: Int = 0,
    ) {
        cancelAdhan(id)
        if (timeInMillis <= System.currentTimeMillis()) return

        val record = JSONObject().apply {
            put("id", id)
            put("timeInMillis", timeInMillis)
            put("localTimeInMillis", localTimeInMillis)
            put("timezoneOffsetMinutes", timezoneOffsetMinutes)
            put("timezoneUsesDevice", timezoneUsesDevice)
            put("prayerName", prayerName)
            put("fullScreen", fullScreen)
            put("volume", volume.coerceIn(0.0, 1.0))
            put("preAlertMinutes", preAlertMinutes.coerceAtLeast(0))
        }
        saveRecord(id, record)
        scheduleRecord(record)
    }

    fun cancelAdhan(id: Int) {
        cancelPendingIntent(id)
        cancelPendingIntent(preAlertId(id))
        removeRecord(id)
    }

    fun restoreSavedAlarms(timezoneChanged: Boolean = false) {
        val stored = prefs.getStringSet(RECORD_IDS_KEY, emptySet())?.toSet().orEmpty()
        val now = System.currentTimeMillis()
        val validIds = mutableSetOf<String>()
        for (idString in stored) {
            val id = idString.toIntOrNull() ?: continue
            val raw = prefs.getString(recordKey(id), null) ?: continue
            try {
                val record = JSONObject(raw)
                var effectiveTime = record.optLong("timeInMillis", 0L)
                if (timezoneChanged && record.optBoolean("timezoneUsesDevice", false)) {
                    val recalculatedOffset = java.util.TimeZone.getDefault()
                        .getOffset(System.currentTimeMillis()) / 60_000
                    record.put("timezoneOffsetMinutes", recalculatedOffset)
                    val localTime = record.optLong("localTimeInMillis", effectiveTime)
                    effectiveTime = localTime - recalculatedOffset * 60_000L
                    record.put("timeInMillis", effectiveTime)
                    prefs.edit().putString(recordKey(id), record.toString()).apply()
                }
                if (effectiveTime <= now) {
                    cancelPendingIntent(id)
                    cancelPendingIntent(preAlertId(id))
                    continue
                }
                validIds.add(id.toString())
                cancelPendingIntent(id)
                cancelPendingIntent(preAlertId(id))
                scheduleRecord(record)
            } catch (error: Exception) {
                Log.e(tag, "Invalid persisted alarm record for id=$id", error)
                cancelPendingIntent(id)
                cancelPendingIntent(preAlertId(id))
            }
        }
        prefs.edit().putStringSet(RECORD_IDS_KEY, validIds).apply()
    }

    fun checkExactAlarmPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    fun openExactAlarmSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = android.net.Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        }
    }

    fun checkFullScreenPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            context.getSystemService(android.app.NotificationManager::class.java)
                ?.canUseFullScreenIntent() == true
        } else {
            true
        }
    }

    private fun scheduleRecord(record: JSONObject) {
        val id = record.optInt("id", 0)
        val timeInMillis = record.optLong("timeInMillis", 0L)
        if (id <= 0 || timeInMillis <= System.currentTimeMillis()) return

        val prayerName = record.optString("prayerName", "الصلاة")
        val fullScreen = record.optBoolean("fullScreen", false)
        val volume = record.optDouble("volume", 1.0).coerceIn(0.0, 1.0)
        val preAlertMinutes = record.optInt("preAlertMinutes", 0).coerceAtLeast(0)
        val timezoneOffsetMinutes = record.optInt("timezoneOffsetMinutes", 0)
        val localTimeInMillis = record.optLong("localTimeInMillis", timeInMillis)

        if (preAlertMinutes > 0) {
            val preAlertTime = timeInMillis - preAlertMinutes * 60_000L
            if (preAlertTime > System.currentTimeMillis()) {
                scheduleNativeAlarm(
                    preAlertId(id),
                    preAlertTime,
                    prayerName,
                    fullScreen = false,
                    volume = 0.0,
                    isPreAlert = true,
                    localTimeInMillis = localTimeInMillis,
                    timezoneOffsetMinutes = timezoneOffsetMinutes,
                    preAlertMinutes = preAlertMinutes,
                )
            }
        }

        scheduleNativeAlarm(
            id,
            timeInMillis,
            prayerName,
            fullScreen,
            volume,
            isPreAlert = false,
            localTimeInMillis = localTimeInMillis,
            timezoneOffsetMinutes = timezoneOffsetMinutes,
            preAlertMinutes = 0,
        )
    }

    private fun scheduleNativeAlarm(
        requestCode: Int,
        triggerAtMillis: Long,
        prayerName: String,
        fullScreen: Boolean,
        volume: Double,
        isPreAlert: Boolean,
        localTimeInMillis: Long,
        timezoneOffsetMinutes: Int,
        preAlertMinutes: Int,
    ) {
        if (triggerAtMillis <= System.currentTimeMillis()) return
        val intent = Intent(context, AdhanReceiver::class.java).apply {
            action = ACTION_FIRE_ADHAN
            putExtra("id", requestCode)
            putExtra("prayerId", if (isPreAlert) requestCode / PRE_ALERT_ID_OFFSET else requestCode)
            putExtra("prayerName", prayerName)
            putExtra("fullScreen", fullScreen)
            putExtra("volume", volume)
            putExtra("isPreAlert", isPreAlert)
            putExtra("localTimeInMillis", localTimeInMillis)
            putExtra("timezoneOffsetMinutes", timezoneOffsetMinutes)
            putExtra("preAlertMinutes", preAlertMinutes)
        }
        val pendingIntent = pendingIntent(requestCode, intent)

        try {
            if (checkExactAlarmPermission()) {
                val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, pendingIntent)
                alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent,
                )
                Log.w(tag, "Exact alarm permission unavailable; scheduled inexact alarm for $prayerName")
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        } catch (securityError: SecurityException) {
            Log.e(tag, "Alarm permission denied for $prayerName; using safe fallback", securityError)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent,
                )
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        } catch (error: Exception) {
            Log.e(tag, "Failed to schedule alarm for $prayerName", error)
        }
    }

    private fun pendingIntent(requestCode: Int, intent: Intent): PendingIntent {
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun cancelPendingIntent(requestCode: Int) {
        val intent = Intent(context, AdhanReceiver::class.java).apply {
            action = ACTION_FIRE_ADHAN
        }
        val pending = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (pending != null) {
            alarmManager.cancel(pending)
            pending.cancel()
        }
    }

    private fun saveRecord(id: Int, record: JSONObject) {
        val ids = prefs.getStringSet(RECORD_IDS_KEY, emptySet())?.toMutableSet() ?: mutableSetOf()
        ids.add(id.toString())
        prefs.edit()
            .putString(recordKey(id), record.toString())
            .putStringSet(RECORD_IDS_KEY, ids)
            .apply()
    }

    private fun removeRecord(id: Int) {
        val ids = prefs.getStringSet(RECORD_IDS_KEY, emptySet())?.toMutableSet() ?: mutableSetOf()
        ids.remove(id.toString())
        prefs.edit().remove(recordKey(id)).putStringSet(RECORD_IDS_KEY, ids).apply()
    }

    private fun recordKey(id: Int) = "$RECORD_PREFIX$id"

    companion object {
        const val ACTION_FIRE_ADHAN = "com.islamic.aldhakereen.action.FIRE_ADHAN"
        const val ACTION_RESTORE_ALARMS = "com.islamic.aldhakereen.action.RESTORE_ALARMS"
        const val PRE_ALERT_ID_OFFSET = 100_000
        private const val PREFS_NAME = "adhan_alarm_records"
        private const val RECORD_IDS_KEY = "record_ids"
        private const val RECORD_PREFIX = "record_"

        fun preAlertId(id: Int): Int = PRE_ALERT_ID_OFFSET + id
    }
}
