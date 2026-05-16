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
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.app.ForegroundServiceStartNotAllowedException
import androidx.core.app.NotificationCompat
import com.islamic.aldhakereen.R

class AdhanForegroundService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private val channelId = "adhan_channel"

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prayerName = intent?.getStringExtra("prayerName") ?: "الصلاة"
        val fullScreen = intent?.getBooleanExtra("fullScreen", false) ?: false
        val volume = intent?.getDoubleExtra("volume", 1.0) ?: 1.0

        // Ensure notification channel is explicitly created before startForeground
        createNotificationChannel()
        val notification = createNotification(prayerName, fullScreen)
        try {
            startForeground(startId, notification)
        } catch (e: Exception) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && e is ForegroundServiceStartNotAllowedException) {
                e.printStackTrace()
            } else {
                e.printStackTrace()
            }
        }

        playAdhan(volume.toFloat())

        return START_NOT_STICKY
    }

    private fun playAdhan(volume: Float) {
        try {
            val afd = resources.openRawResourceFd(R.raw.azan5) ?: return
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                prepare()
                setVolume(volume, volume)
                start()
                setOnCompletionListener {
                    stopSelf()
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }

    private fun createNotification(prayerName: String, fullScreen: Boolean): Notification {
        val builder = NotificationCompat.Builder(this, channelId)
            .setContentTitle("حان موعد $prayerName")
            .setContentText("الصلاة خير من النوم")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
        if (fullScreen) {
            val fullScreenIntent = Intent(this, com.islamic.aldhakereen.MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            val fullScreenPendingIntent = PendingIntent.getActivity(
                this, 0, fullScreenIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.setFullScreenIntent(fullScreenPendingIntent, true)
        }
        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Adhan Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for Adhan"
                vibrationPattern = longArrayOf(0, 500, 1000)
                enableVibration(true)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        mediaPlayer?.release()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
