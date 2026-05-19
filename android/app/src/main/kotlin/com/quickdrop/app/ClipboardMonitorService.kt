package com.quickdrop.app

import android.app.Service
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.IBinder

class ClipboardMonitorService : Service() {
    private lateinit var clipboard: ClipboardManager
    private var lastUrl: String? = null
    private val listener = ClipboardManager.OnPrimaryClipChangedListener { checkClipboard() }

    override fun onCreate() {
        super.onCreate()
        NotificationHelper.ensureChannels(this)
        clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.addPrimaryClipChangedListener(listener)
        startForeground(
            200,
            NotificationHelper.basic(this, NotificationHelper.CLIPBOARD_CHANNEL, "QuickDrop ready", "Watching supported links")
        )
        checkClipboard()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        checkClipboard()
        return START_STICKY
    }

    override fun onDestroy() {
        clipboard.removePrimaryClipChangedListener(listener)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun checkClipboard() {
        val text = clipboard.primaryClip?.getItemAt(0)?.coerceToText(this)?.toString()
        val url = UrlSupport.extract(text) ?: return
        if (url == lastUrl) return
        lastUrl = url
        QuickDropOverlayService.show(this, url)
    }

    companion object {
        fun start(context: Context) {
            androidx.core.content.ContextCompat.startForegroundService(
                context,
                Intent(context, ClipboardMonitorService::class.java)
            )
        }
    }
}
