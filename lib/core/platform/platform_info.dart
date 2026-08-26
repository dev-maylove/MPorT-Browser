import 'package:flutter/foundation.dart';

/// Lightweight platform flags without dart:io (safe on web).
class PlatformInfo {
  static bool get isWeb => kIsWeb;
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// webview_flutter has limited / no full support on web — use iframe fallback.
  static bool get useNativeWebView => !kIsWeb;
}
