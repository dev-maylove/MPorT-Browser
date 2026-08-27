package id.mport.browser

import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import java.io.ByteArrayInputStream
import java.util.Locale

/** Resource-level filtering for Android WebView and ServiceWorker requests. */
object ResourceBlocker {
    private val blockedHosts = setOf(
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "google-analytics.com", "analytics.google.com", "googletagmanager.com",
        "connect.facebook.net", "ads-twitter.com", "ads.linkedin.com",
        "bat.bing.com", "scorecardresearch.com", "quantserve.com", "hotjar.com",
        "clarity.ms", "segment.io", "segment.com", "mixpanel.com", "amplitude.com",
        "criteo.com", "adnxs.com", "taboola.com", "outbrain.com", "zedo.com",
        "rubiconproject.com", "pubmatic.com", "casalemedia.com", "openx.net",
        "adsrvr.org", "33across.com", "smartadserver.com", "yieldmo.com",
        "teads.tv", "adform.net", "advertising.com", "moatads.com",
        "demdex.net", "omtrdc.net", "everesttech.net", "rlcdn.com",
        "bluekai.com", "krxd.net", "mathtag.com", "eyeota.net", "tapad.com"
    )

    private val blockedPathTokens = listOf(
        "/pagead/", "/ads/", "/adserver/", "/advertising/", "/analytics/",
        "/tracking/", "/track/", "/pixel", "/beacon", "/collect"
    )

    fun shouldBlock(url: String, mainFrame: Boolean = false): Boolean {
        val uri = try { android.net.Uri.parse(url) } catch (_: Exception) { return false }
        val scheme = uri.scheme?.lowercase(Locale.US) ?: return false
        if (scheme != "http" && scheme != "https") return false

        val host = uri.host?.lowercase(Locale.US) ?: return false
        val path = (uri.path ?: "").lowercase(Locale.US)
        val query = (uri.query ?: "").lowercase(Locale.US)

        if (blockedHosts.any { host == it || host.endsWith(".$it") }) return true
        if (!mainFrame && blockedPathTokens.any { path.contains(it) }) return true

        // Common tracking query parameters. Keep this conservative to reduce breakage.
        val trackingKeys = listOf("gclid", "dclid", "fbclid", "msclkid", "mc_cid", "mc_eid")
        return !mainFrame && trackingKeys.any { query.contains("$it=") } &&
            (path.contains("collect") || path.contains("track") || path.contains("click"))
    }

    fun emptyResponse(): WebResourceResponse = WebResourceResponse(
        "text/plain",
        "utf-8",
        204,
        "No Content",
        mapOf("Cache-Control" to "no-store"),
        ByteArrayInputStream(ByteArray(0))
    )

    fun isHttp(url: String): Boolean {
        return try { android.net.Uri.parse(url).scheme.equals("http", ignoreCase = true) } catch (_: Exception) { false }
    }
}
