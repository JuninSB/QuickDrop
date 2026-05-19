package com.quickdrop.app

import android.app.Service
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.graphics.ColorUtils

class QuickDropOverlayService : Service() {
    private lateinit var windowManager: WindowManager
    private var bubble: View? = null
    private var popup: View? = null
    private var currentUrl: String = ""

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        currentUrl = intent?.getStringExtra(EXTRA_URL).orEmpty()
        if (!Settings.canDrawOverlays(this) || currentUrl.isBlank()) stopSelf() else showBubble()
        return START_NOT_STICKY
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onDestroy() {
        removeViews()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun showBubble() {
        if (bubble != null) return
        val view = TextView(this).apply {
            text = "QD"
            textSize = 13f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setBackgroundResource(android.R.drawable.presence_online)
            elevation = 16f
            setOnClickListener { showPopup() }
        }
        val params = overlayParams(58, 58).apply {
            gravity = Gravity.TOP or Gravity.START
            x = resources.displayMetrics.widthPixels - 88
            y = resources.displayMetrics.heightPixels / 3
        }
        attachDrag(view, params)
        bubble = view
        windowManager.addView(view, params)
    }

    private fun showPopup() {
        popup?.let {
            windowManager.removeView(it)
            popup = null
            return
        }
        val panel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(28, 24, 28, 24)
            background = rounded(ColorUtils.setAlphaComponent(Color.rgb(18, 20, 24), 235), 28f)
            elevation = 24f
        }
        val title = TextView(this).apply {
            text = "QuickDrop"
            textSize = 18f
            setTextColor(Color.WHITE)
        }
        val url = TextView(this).apply {
            text = currentUrl
            textSize = 13f
            setTextColor(Color.rgb(205, 210, 220))
            maxLines = 3
            setPadding(0, 16, 0, 18)
        }
        val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        val paste = action("Paste") {
            val cm = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
            currentUrl = UrlSupport.extract(cm.primaryClip?.getItemAt(0)?.coerceToText(this)?.toString()).orEmpty()
            url.text = currentUrl
        }
        val download = action("Download") {
            if (currentUrl.isNotBlank()) DownloadForegroundService.start(this, currentUrl, "best")
            removeViews()
            stopSelf()
        }
        val close = action("Close") {
            removeViews()
            stopSelf()
        }
        row.addView(paste)
        row.addView(download)
        row.addView(close)
        panel.addView(title)
        panel.addView(url)
        panel.addView(row)
        val params = overlayParams(
            (resources.displayMetrics.widthPixels * 0.86f).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = 120
        }
        popup = panel
        windowManager.addView(panel, params)
    }

    private fun action(label: String, onClick: () -> Unit): Button {
        return Button(this).apply {
            text = label
            isAllCaps = false
            setTextColor(Color.WHITE)
            setOnClickListener { onClick() }
        }
    }

    private fun attachDrag(view: View, params: WindowManager.LayoutParams) {
        var downX = 0
        var downY = 0
        var touchX = 0f
        var touchY = 0f
        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = params.x
                    downY = params.y
                    touchX = event.rawX
                    touchY = event.rawY
                    false
                }
                MotionEvent.ACTION_MOVE -> {
                    params.x = downX + (event.rawX - touchX).toInt()
                    params.y = downY + (event.rawY - touchY).toInt()
                    windowManager.updateViewLayout(view, params)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    params.x = if (params.x < resources.displayMetrics.widthPixels / 2) 8 else resources.displayMetrics.widthPixels - view.width - 8
                    windowManager.updateViewLayout(view, params)
                    false
                }
                else -> false
            }
        }
    }

    private fun overlayParams(width: Int, height: Int): WindowManager.LayoutParams {
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }
        return WindowManager.LayoutParams(
            width,
            height,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )
    }

    private fun rounded(color: Int, radius: Float): android.graphics.drawable.Drawable {
        return android.graphics.drawable.GradientDrawable().apply {
            setColor(color)
            cornerRadius = radius
        }
    }

    private fun removeViews() {
        popup?.let { windowManager.removeView(it) }
        bubble?.let { windowManager.removeView(it) }
        popup = null
        bubble = null
    }

    companion object {
        private const val EXTRA_URL = "url"
        fun show(context: Context, url: String) {
            context.startService(Intent(context, QuickDropOverlayService::class.java).putExtra(EXTRA_URL, url))
        }
    }
}
