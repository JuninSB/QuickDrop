package com.quickdrop.app

object UrlSupport {
    private val supportedHosts = listOf(
        "instagram.com",
        "tiktok.com",
        "youtube.com",
        "youtu.be",
        "twitter.com",
        "x.com",
        "facebook.com",
        "fb.watch"
    )

    fun extract(text: String?): String? {
        if (text.isNullOrBlank()) return null
        val match = Regex("""https?://[^\s<>"']+""").find(text)?.value ?: return null
        val lower = match.lowercase()
        return supportedHosts.firstOrNull { lower.contains(it) }?.let { match.trimEnd('.', ',', ')', ']') }
    }
}
