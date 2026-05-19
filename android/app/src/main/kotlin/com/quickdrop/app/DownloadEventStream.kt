package com.quickdrop.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.plugin.common.EventChannel

class DownloadEventStream(private val context: Context) : EventChannel.StreamHandler {
    private var receiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                val data = mapOf(
                    "id" to intent?.getStringExtra("id"),
                    "url" to intent?.getStringExtra("url"),
                    "status" to intent?.getStringExtra("status"),
                    "progress" to intent?.getIntExtra("progress", 0),
                    "file" to intent?.getStringExtra("file"),
                    "error" to intent?.getStringExtra("error")
                )
                events.success(data)
            }
        }
        androidx.core.content.ContextCompat.registerReceiver(
            context,
            receiver,
            IntentFilter(DownloadForegroundService.ACTION_EVENT),
            androidx.core.content.ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    override fun onCancel(arguments: Any?) {
        receiver?.let { context.unregisterReceiver(it) }
        receiver = null
    }
}
