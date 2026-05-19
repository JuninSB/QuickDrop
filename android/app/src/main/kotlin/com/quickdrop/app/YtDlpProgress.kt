package com.quickdrop.app

interface YtDlpProgress {
    fun onProgress(progress: Int, text: String)
}
