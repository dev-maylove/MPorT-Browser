package id.mport.browser

import android.graphics.Bitmap
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient

/**
 * Native WebViewClient that blocks subresource requests, navigations and
 * redirects at the WebView resource layer.
 */
class BlockingWebViewClient(
    private val tabId: String,
    private val allowHttp: Boolean,
    private val emit: (String, Map<String, Any?>) -> Unit,
) : WebViewClient() {

    override fun shouldInterceptRequest(
        view: WebView,
        request: WebResourceRequest,
    ): WebResourceResponse? {
        val url = request.url.toString()
        if (ResourceBlocker.shouldBlock(url, request.isForMainFrame)) {
            emit("resourceBlocked", mapOf("tabId" to tabId, "url" to url, "mainFrame" to request.isForMainFrame))
            return ResourceBlocker.emptyResponse()
        }
        return null
    }

    override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
        val url = request.url.toString()
        if (ResourceBlocker.shouldBlock(url, true)) {
            emit("navigationBlocked", mapOf("tabId" to tabId, "url" to url, "reason" to "tracker"))
            return true
        }
        if (!allowHttp && ResourceBlocker.isHttp(url)) {
            emit("navigationBlocked", mapOf("tabId" to tabId, "url" to url, "reason" to "http"))
            return true
        }
        return false
    }

    override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) {
        emit("pageStarted", mapOf("tabId" to tabId, "url" to url))
        super.onPageStarted(view, url, favicon)
    }

    override fun onPageFinished(view: WebView, url: String) {
        emit(
            "pageFinished",
            mapOf(
                "tabId" to tabId,
                "url" to url,
                "title" to view.title,
                "canGoBack" to view.canGoBack(),
                "canGoForward" to view.canGoForward(),
            ),
        )
        super.onPageFinished(view, url)
    }

    override fun onReceivedError(
        view: WebView,
        request: WebResourceRequest,
        error: android.webkit.WebResourceError,
    ) {
        if (request.isForMainFrame) {
            emit("pageError", mapOf("tabId" to tabId, "url" to request.url.toString(), "description" to error.description.toString()))
        }
        super.onReceivedError(view, request, error)
    }
}
