import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge ke native Android (default browser settings + deep links).
class NativeBridge {
  NativeBridge._();
  static const _channel = MethodChannel('id.mport.browser/native');

  static String? _pendingUrl;
  static void Function(String url)? _urlListener;

  static void init() {
    if (kIsWeb) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onOpenUrl') {
        final url = call.arguments as String?;
        if (url != null && url.isNotEmpty) {
          _pendingUrl = url;
          _urlListener?.call(url);
        }
      }
    });
  }

  static void setOpenUrlListener(void Function(String url)? listener) {
    _urlListener = listener;
    if (_pendingUrl != null && listener != null) {
      final u = _pendingUrl!;
      _pendingUrl = null;
      listener(u);
    }
  }

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

  static Future<String?> getInitialUrl() async {
    if (kIsWeb) return null;
    try {
      return await _channel.invokeMethod<String>('getInitialUrl');
    } catch (_) {
      return null;
    }
  }
}
