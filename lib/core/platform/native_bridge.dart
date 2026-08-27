import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge ke native Android (bukan sekadar WebView shell).
class NativeBridge {
  NativeBridge._();
  static const _channel = MethodChannel('id.mport.browser/native');

  static VoidCallback? onOpenUrlHandler;

  static void init() {
    if (kIsWeb) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onOpenUrl') {
        final url = call.arguments as String?;
        if (url != null && url.isNotEmpty) {
          onOpenUrlHandler?.call();
          // Handler with url is set by app via setOpenUrlListener
          _pendingUrl = url;
          _urlListener?.call(url);
        }
      }
    });
  }

  static String? _pendingUrl;
  static void Function(String url)? _urlListener;

  static void setOpenUrlListener(void Function(String url)? listener) {
    _urlListener = listener;
    if (_pendingUrl != null && listener != null) {
      final u = _pendingUrl!;
      _pendingUrl = null;
      listener(u);
    }
  }

  /// Buka pengaturan default apps (pilih browser default).
  static Future<bool> openDefaultBrowserSettings() async {
    if (kIsWeb) return false;
    try {
      final r = await _channel.invokeMethod<bool>('openDefaultBrowserSettings');
      return r ?? true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openAppDetailsSettings() async {
    if (kIsWeb) return false;
    try {
      final r = await _channel.invokeMethod<bool>('openAppDetailsSettings');
      return r ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Buka URL lewat Chrome Custom Tabs (native Android UI).
  static Future<bool> openCustomTab(String url) async {
    if (kIsWeb) return false;
    try {
      final r = await _channel.invokeMethod<bool>('openCustomTab', {'url': url});
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  /// URL dari intent VIEW saat cold start (link dibuka dengan MPorT).
  static Future<String?> getInitialUrl() async {
    if (kIsWeb) return null;
    try {
      return await _channel.invokeMethod<String>('getInitialUrl');
    } catch (_) {
      return null;
    }
  }
}
