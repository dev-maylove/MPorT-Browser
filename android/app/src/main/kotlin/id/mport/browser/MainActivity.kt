package id.mport.browser

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Native Android host for MPorT Browser.
 * - VIEW intents (default-browser eligible)
 * - Open system default-app settings
 */
class MainActivity : FlutterActivity() {
    private val channelName = "id.mport.browser/native"
    private var methodChannel: MethodChannel? = null
    private var pendingUrl: String? = null

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
