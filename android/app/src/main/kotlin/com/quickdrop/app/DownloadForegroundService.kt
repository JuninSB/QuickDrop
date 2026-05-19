package com.quickdrop.app

import android.app.Service
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.IBinder
import android.provider.MediaStore
import androidx.core.app.NotificationManagerCompat
import java.io.File
import java.util.UUID
import kotlin.concurrent.thread

class DownloadForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val url = intent?.getStringExtra(EXTRA_URL).orEmpty()
        val quality = intent?.getStringExtra(EXTRA_QUALITY) ?: "best"
        if (url.isBlank()) {
            stopSelf(startId)
            return START_NOT_STICKY
        }
        NotificationHelper.ensureChannels(this)
        startForeground(100, NotificationHelper.progress(this, "QuickDrop", "Starting download", 0))
        thread(name = "quickdrop-download") {
            runDownload(url, quality)
            stopSelf(startId)
        }
        return START_REDELIVER_INTENT
    }

    private fun runDownload(url: String, quality: String) {
        val id = UUID.randomUUID().toString()
        val workDir = File(cacheDir, "downloads").apply { mkdirs() }
        val outputTemplate = File(workDir, "%(title).180B-%(id)s.%(ext)s").absolutePath
        val ytdlp = prepareYtDlp()
        if (ytdlp == null) {
            emit(id, url, "failed", 0, error = "Missing assets/bin/yt-dlp Android executable")
            return
        }
        val format = when (quality) {
            "720p" -> "bestvideo[height<=720]+bestaudio/best[height<=720]/best"
            "480p" -> "bestvideo[height<=480]+bestaudio/best[height<=480]/best"
            "audio" -> "bestaudio/best"
            else -> "bv*+ba/best"
        }

        var lastError = ""
        repeat(3) { attempt ->
            emit(id, url, if (attempt == 0) "running" else "retrying", 0)
            val args = listOf(
                ytdlp.absolutePath,
                "--newline",
                "--no-playlist",
                "--restrict-filenames",
                "--merge-output-format", "mp4",
                "-f", format,
                "-o", outputTemplate,
                url
            )
            val process = ProcessBuilder(args)
                .redirectErrorStream(true)
                .directory(workDir)
                .start()
            process.inputStream.bufferedReader().useLines { lines ->
                lines.forEach { line ->
                    parseProgress(line)?.let { progress ->
                        notifyProgress(id, url, progress, "Downloading $progress%")
                    }
                    if (line.contains("ERROR", ignoreCase = true)) lastError = line
                }
            }
            val exit = process.waitFor()
            if (exit == 0) {
                val file = workDir.listFiles()?.filter { it.isFile }?.maxByOrNull { it.lastModified() }
                if (file != null) {
                    val saved = saveToMediaStore(file)
                    emit(id, url, "completed", 100, saved.toString())
                    try {
                        NotificationManagerCompat.from(this).notify(
                            101,
                            NotificationHelper.basic(this, NotificationHelper.DOWNLOAD_CHANNEL, "Download complete", file.name)
                        )
                    } catch (_: SecurityException) {
                        // Android 13 notification permission can be denied; the download still completes.
                    }
                    return
                }
                lastError = "Download finished but output file was not found"
            } else if (lastError.isBlank()) {
                lastError = "yt-dlp exited with code $exit"
            }
        }
        emit(id, url, "failed", 0, error = lastError.ifBlank { "Download failed" })
    }

    private fun notifyProgress(id: String, url: String, progress: Int, text: String) {
        try {
            NotificationManagerCompat.from(this).notify(100, NotificationHelper.progress(this, "QuickDrop", text, progress))
        } catch (_: SecurityException) {
            // Keep broadcasting progress to Flutter even if notifications are blocked.
        }
        emit(id, url, "running", progress)
    }

    private fun parseProgress(line: String): Int? {
        val match = Regex("""\s(\d{1,3}(?:\.\d+)?)%""").find(line) ?: return null
        return match.groupValues[1].toDoubleOrNull()?.toInt()?.coerceIn(0, 100)
    }

    private fun prepareYtDlp(): File? {
        val target = File(filesDir, "bin/yt-dlp")
        if (target.exists() && target.length() > 0) return target
        target.parentFile?.mkdirs()
        return try {
            assets.open("bin/yt-dlp").use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            }
            target.setExecutable(true, true)
            target
        } catch (_: Exception) {
            null
        }
    }

    private fun saveToMediaStore(source: File): Uri? {
        val resolver = contentResolver
        val mime = if (source.extension.equals("mp3", true) || source.extension.equals("m4a", true)) "audio/mpeg" else "video/mp4"
        val collection = if (mime.startsWith("audio")) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            }
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            }
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, source.name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/QuickDrop")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }
        val uri = resolver.insert(collection, values) ?: return null
        resolver.openOutputStream(uri)?.use { out -> source.inputStream().use { it.copyTo(out) } }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        }
        source.delete()
        return uri
    }

    private fun emit(id: String, url: String, status: String, progress: Int, file: String? = null, error: String? = null) {
        sendBroadcast(
            Intent(ACTION_EVENT)
                .setPackage(packageName)
                .putExtra("id", id)
                .putExtra("url", url)
                .putExtra("status", status)
                .putExtra("progress", progress)
                .putExtra("file", file)
                .putExtra("error", error)
        )
    }

    companion object {
        const val ACTION_EVENT = "com.quickdrop.app.DOWNLOAD_EVENT"
        private const val EXTRA_URL = "url"
        private const val EXTRA_QUALITY = "quality"

        fun start(context: Context, url: String, quality: String) {
            androidx.core.content.ContextCompat.startForegroundService(
                context,
                Intent(context, DownloadForegroundService::class.java)
                    .putExtra(EXTRA_URL, url)
                    .putExtra(EXTRA_QUALITY, quality)
            )
        }
    }
}
