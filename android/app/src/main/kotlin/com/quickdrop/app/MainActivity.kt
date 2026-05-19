package com.quickdrop.app

import android.Manifest
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methods = "quickdrop/native"
    private val events = "quickdrop/download_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NotificationHelper.ensureChannels(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methods).setMethodCallHandler { call, result ->
            when (call.method) {
                "clipboardUrl" -> result.success(currentClipboardUrl())
                "isOverlayGranted" -> result.success(Settings.canDrawOverlays(this))
                "requestOverlayPermission" -> {
                    startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                    result.success(null)
                }
                "requestNotifications" -> {
                    if (Build.VERSION.SDK_INT >= 33) {
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 12)
                    }
                    result.success(null)
                }
                "showOverlay" -> {
                    val url = call.argument<String>("url").orEmpty()
                    QuickDropOverlayService.show(this, url)
                    result.success(null)
                }
                "hideOverlay" -> {
                    stopService(Intent(this, QuickDropOverlayService::class.java))
                    result.success(null)
                }
                "startClipboardMonitor" -> {
                    ClipboardMonitorService.start(this)
                    result.success(null)
                }
                "stopClipboardMonitor" -> {
                    stopService(Intent(this, ClipboardMonitorService::class.java))
                    result.success(null)
                }
                "download" -> {
                    val url = call.argument<String>("url").orEmpty()
                    val quality = call.argument<String>("quality") ?: "best"
                    DownloadForegroundService.start(this, url, quality)
                    result.success(null)
                }
                "diagnostics" -> result.success(diagnostics())
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, events).setStreamHandler(DownloadEventStream(this))
    }

    private fun currentClipboardUrl(): String? {
        val manager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val text = manager.primaryClip?.getItemAt(0)?.coerceToText(this)?.toString()
        return UrlSupport.extract(text)
    }

    private fun diagnostics(): Map<String, Any?> {
        val extracted = java.io.File(filesDir, "bin/yt-dlp")
        val assetExists = try {
            assets.open("bin/yt-dlp").close()
            true
        } catch (_: Exception) {
            false
        }
        return mapOf(
            "packageName" to packageName,
            "assetYtDlpExists" to assetExists,
            "extractedYtDlpExists" to extracted.exists(),
            "extractedYtDlpPath" to extracted.absolutePath,
            "extractedYtDlpSize" to if (extracted.exists()) extracted.length() else 0L,
            "androidSdk" to Build.VERSION.SDK_INT,
            "overlayGranted" to Settings.canDrawOverlays(this)
        )
    }
}
