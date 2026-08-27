package id.mport.browser

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.ServiceWorkerClient
import android.webkit.ServiceWorkerController
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import io.flutter.plugins.webviewflutter.WebViewFlutterAndroidExternalApi

/**
 * Native Android host for MPorT Browser.
 * - VIEW intents (default-browser eligible)
 * - Open system default-app settings
 */
class MainActivity : FlutterActivity() {
    private val channelName = "id.mport.browser/native"
    private var methodChannel: MethodChannel? = null
    private var pendingUrl: String? = null
    private val installedBlockers = mutableSetOf<Long>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        captureIntentUrl(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureIntentUrl(intent)
        pendingUrl?.let { url ->
            methodChannel?.invokeMethod("onOpenUrl", url)
            pendingUrl = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        )
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "openDefaultBrowserSettings" -> {
                    openDefaultBrowserSettings()
                    result.success(true)
                }
                "openAppDetailsSettings" -> {
                    openAppDetails()
                    result.success(true)
                }
                "installResourceBlocker" -> {
                    val id = (call.argument<Number>("identifier"))?.toLong()
                    val tabId = call.argument<String>("tabId")
                    val allowHttp = call.argument<Boolean>("allowHttp") ?: false
                    result.success(id != null && !tabId.isNullOrBlank() && installResourceBlocker(id, tabId, allowHttp))
                }
                "configurePrivateWebView" -> {
                    val id = (call.argument<Number>("identifier"))?.toLong()
                    result.success(id != null && configurePrivateWebView(id))
                }
                "getInitialUrl" -> {
                    val url = pendingUrl
                    pendingUrl = null
                    result.success(url)
                }
                else -> result.notImplemented()
            }
        }

        pendingUrl?.let { url ->
            methodChannel?.invokeMethod("onOpenUrl", url)
            pendingUrl = null
        }
    }

    private fun captureIntentUrl(intent: Intent?) {
        if (intent == null) return
        if (Intent.ACTION_VIEW == intent.action) {
            val data = intent.dataString
            if (!data.isNullOrBlank()) {
                pendingUrl = data
            }
        }
    }

    private fun openDefaultBrowserSettings() {
        val tries = listOf(
            Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS),
            Intent(Settings.ACTION_HOME_SETTINGS),
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            }
        )
        for (i in tries) {
            try {
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(i)
                return
            } catch (_: Exception) {
            }
        }
    }


    private fun emitWebEvent(event: String, payload: Map<String, Any?>) {
        runOnUiThread {
            methodChannel?.invokeMethod("webEvent", mapOf("event" to event, "data" to payload))
        }
    }

    private fun installResourceBlocker(identifier: Long, tabId: String, allowHttp: Boolean): Boolean {
        val engine = flutterEngine ?: return false
        @Suppress("DEPRECATION")
        val webView = WebViewFlutterAndroidExternalApi.getWebView(engine, identifier) ?: return false

        // ServiceWorkerController is process-wide. Install once before/while WebViews are active.
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            try {
                ServiceWorkerController.getInstance().setServiceWorkerClient(object : ServiceWorkerClient() {
                    override fun shouldInterceptRequest(request: WebResourceRequest): WebResourceResponse? {
                        val url = request.url.toString()
                        return if (ResourceBlocker.shouldBlock(url)) {
                            ResourceBlocker.emptyResponse()
                        } else {
                            null
                        }
                    }
                })
            } catch (_: Exception) {
                // Some WebView implementations may not expose ServiceWorkerController.
            }
        }

        if (installedBlockers.add(identifier)) {
            webView.webViewClient = BlockingWebViewClient(tabId, allowHttp) { event, data ->
                emitWebEvent(event, data)
            }
        }
        return true
    }

    private fun configurePrivateWebView(identifier: Long): Boolean {
        val engine = flutterEngine ?: return false
        @Suppress("DEPRECATION")
        val webView = WebViewFlutterAndroidExternalApi.getWebView(engine, identifier) ?: return false
        webView.settings.apply {
            domStorageEnabled = false
            databaseEnabled = false
            cacheMode = WebSettings.LOAD_NO_CACHE
            saveFormData = false
            setAllowFileAccess(false)
            setAllowContentAccess(false)
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
        }
        android.webkit.CookieManager.getInstance().setAcceptThirdPartyCookies(webView, false)
        webView.clearHistory()
        return true
    }

    private fun openAppDetails() {
        try {
            val i = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(i)
        } catch (_: Exception) {
        }
    }
}
