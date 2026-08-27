import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BrowserTab {
  BrowserTab({
    required this.id,
    required this.url,
    this.title = 'New Tab',
    this.private = false,
    this.groupId,
    this.groupName,
  });

  final String id;
  String url;
  String title;
  bool private;
  String? groupId;
  String? groupName;
  bool loading = false;
  int progress = 0;
  bool canBack = false;
  bool canForward = false;
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Chromium-based InAppWebView controller (Android System WebView / WKWebView).
  InAppWebViewController? controller;

  void notify() => revision.value++;
}
