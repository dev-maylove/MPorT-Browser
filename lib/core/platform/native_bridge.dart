import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge ke native Android (default browser settings + deep links).
class NativeBridge {
  NativeBridge._();
  static const _channel = MethodChannel('id.mport.browser/native');

  static String? _pendingUrl;
  static void Function(String url)? _urlListener;
  static void Function(String event, Map<String, dynamic> data)? _webEventListener;

  static void init() {
    if (kIsWeb) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'webEvent') {
        final args = Map<Object?, Object?>.from(call.arguments as Map);
        final event = args['event']?.toString();
        final raw = args['data'];
        if (event != null && raw is Map) {
          _webEventListener?.call(event, Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v))));
        }
        return;
      }
      if (call.method == 'onOpenUrl') {
        final url = call.arguments as String?;
        if (url != null && url.isNotEmpty) {
          _pendingUrl = url;
          _urlListener?.call(url);
        }
      }
    });
  }

  static void setWebEventListener(void Function(String event, Map<String, dynamic> data)? listener) {
    _webEventListener = listener;
  }

  static Future<bool> installResourceBlocker({required int identifier, required String tabId, required bool allowHttp}) async {
    if (kIsWeb) return false;
    try {
      final r = await _channel.invokeMethod<bool>('installResourceBlocker', {
        'identifier': identifier, 'tabId': tabId, 'allowHttp': allowHttp,
      });
      return r ?? false;
    } catch (_) {
      return false;
    }
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

  static Future<bool> configurePrivateWebView(int identifier) async {
    if (kIsWeb) return false;
    try {
      final r = await _channel.invokeMethod<bool>('configurePrivateWebView', {'identifier': identifier});
      return r ?? false;
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
