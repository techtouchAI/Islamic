package com.islamic.aldhakereen.adhan

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.islamic.aldhakereen.MainActivity
import com.islamic.aldhakereen.R

class AdhanForegroundService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private val channelId = "adhan_channel"
    private val handler = Handler(Looper.getMainLooper())
    private var currentNotificationId = 0

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prayerName = intent?.getStringExtra("prayerName") ?: "الصلاة"
        val requestedFullScreen = intent?.getBooleanExtra("fullScreen", false) ?: false
        val fullScreen = requestedFullScreen && canUseFullScreenIntent()
        val volume = intent?.getDoubleExtra("volume", 1.0)?.toFloat()?.coerceIn(0f, 1f) ?: 1f
        val id = intent?.getIntExtra("id", 0) ?: 0
        val isPreAlert = intent?.getBooleanExtra("isPreAlert", false) ?: false
        currentNotificationId = id + NOTIFICATION_ID_OFFSET

        val notification = createNotification(prayerName, fullScreen, isPreAlert)
        try {
            startForeground(currentNotificationId, notification)
        } catch (error: Exception) {
            android.util.Log.e(TAG, "Unable to start foreground service", error)
            stopServiceGracefully()
            return START_NOT_STICKY
        }

        if (!isPreAlert && volume > 0f) {
            playAdhan(volume)
        } else if (isPreAlert) {
            handler.postDelayed({ stopServiceGracefully() }, PRE_ALERT_NOTIFICATION_DURATION_MS)
        }

        handler.postDelayed({ stopServiceGracefully() }, SERVICE_TIMEOUT_MS)
        return START_NOT_STICKY
    }

    private fun playAdhan(volume: Float) {
        releasePlayer()
        try {
            val afd = resources.openRawResourceFd(R.raw.adhan)
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build(),
                )
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                setVolume(volume, volume)
                setOnCompletionListener {
                    releasePlayer()
                    handler.postDelayed({ stopServiceGracefully() }, COMPLETION_GRACE_PERIOD_MS)
                }
                setOnErrorListener { player, _, _ ->
                    player.reset()
                    releasePlayer()
                    stopServiceGracefully()
                    true
                }
                prepare()
                start()
            }
        } catch (error: Exception) {
            android.util.Log.e(TAG, "Unable to play adhan", error)
            releasePlayer()
            stopServiceGracefully()
        }
    }

    private fun createNotification(
        prayerName: String,
        fullScreen: Boolean,
        isPreAlert: Boolean,
    ): Notification {
        val title = if (isPreAlert) {
            "اقترب وقت صلاة $prayerName"
        } else {
            "حان موعد صلاة $prayerName"
        }
        val text = if (isPreAlert) {
            "استعد للصلاة"
        } else {
            "الصلاة خير من النوم"
        }
        val builder = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(!isPreAlert)
            .setAutoCancel(true)

        val contentIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            this,
            currentNotificationId,
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        builder.setContentIntent(contentPendingIntent)

        if (fullScreen && canUseFullScreenIntent()) {
            val fullScreenPendingIntent = PendingIntent.getActivity(
                this,
                currentNotificationId + FULL_SCREEN_REQUEST_OFFSET,
                contentIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            builder.setFullScreenIntent(fullScreenPendingIntent, true)
        }
        return builder.build()
    }

    private fun canUseFullScreenIntent(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            getSystemService(NotificationManager::class.java)?.canUseFullScreenIntent() == true
        } else {
            true
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "تنبيهات الأذان",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "إشعارات مواقيت الصلاة والأذان"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 1000, 500, 1000)
                setSound(null, null)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun releasePlayer() {
        mediaPlayer?.let { player ->
            try {
                if (player.isPlaying) player.stop()
            } catch (_: IllegalStateException) {
                // The player can already be in an error/completed state.
            }
            player.release()
        }
        mediaPlayer = null
    }

    private fun stopServiceGracefully() {
        releasePlayer()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            stopForeground(false)
        }
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        releasePlayer()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val TAG = "AdhanForegroundService"
        private const val NOTIFICATION_ID_OFFSET = 1_000
        private const val FULL_SCREEN_REQUEST_OFFSET = 10_000
        private const val SERVICE_TIMEOUT_MS = 5 * 60 * 1_000L
        private const val PRE_ALERT_NOTIFICATION_DURATION_MS = 60_000L
        private const val COMPLETION_GRACE_PERIOD_MS = 30_000L
    }
}
