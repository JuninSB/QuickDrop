package com.quickdrop.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

object NotificationHelper {
    const val DOWNLOAD_CHANNEL = "quickdrop_downloads"
    const val CLIPBOARD_CHANNEL = "quickdrop_clipboard"

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(DOWNLOAD_CHANNEL, "Downloads", NotificationManager.IMPORTANCE_LOW)
        )
        manager.createNotificationChannel(
            NotificationChannel(CLIPBOARD_CHANNEL, "Clipboard monitor", NotificationManager.IMPORTANCE_MIN)
        )
    }

    fun basic(context: Context, channel: String, title: String, text: String): Notification {
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            1,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_stat_quickdrop)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(channel == DOWNLOAD_CHANNEL)
            .setContentIntent(pendingIntent)
            .setOnlyAlertOnce(true)
            .build()
    }

    fun progress(context: Context, title: String, text: String, progress: Int): Notification {
        return NotificationCompat.Builder(context, DOWNLOAD_CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_quickdrop)
            .setContentTitle(title)
            .setContentText(text)
            .setProgress(100, progress.coerceIn(0, 100), progress < 0)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }
}
