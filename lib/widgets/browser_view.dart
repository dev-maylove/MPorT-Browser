import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/browser_tab.dart';
import '../core/theme/app_theme.dart';
import 'web_iframe_stub.dart'
    if (dart.library.html) 'web_iframe_web.dart' as iframe;

class BrowserView extends StatelessWidget {
  const BrowserView({super.key, required this.tab});

  final BrowserTab tab;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: tab.revision,
      builder: (_, __, ___) {
        if (kIsWeb) {
          return _WebIframeView(tab: tab);
        }
        return _NativeWebView(tab: tab);
      },
    );
  }
}

class _NativeWebView extends StatelessWidget {
  const _NativeWebView({required this.tab});
  final BrowserTab tab;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: tab.controller),
        if (tab.loading || (tab.progress > 0 && tab.progress < 100))
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: tab.progress > 0 ? tab.progress / 100.0 : null,
              backgroundColor: AppTheme.bgCard,
              color: AppTheme.cyanNeon,
              minHeight: 2,
            ),
          ),
      ],
    );
  }
}

class _WebIframeView extends StatelessWidget {
  const _WebIframeView({required this.tab});
  final BrowserTab tab;

  @override
  Widget build(BuildContext context) {
    final url = tab.url.isEmpty ? 'about:blank' : tab.url;
    final viewType = 'mport-iframe-${tab.id}';

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: iframe.buildWebIframe(viewType: viewType, url: url),
        ),
        if (tab.loading || (tab.progress > 0 && tab.progress < 100))
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: tab.progress > 0 ? tab.progress / 100.0 : null,
              backgroundColor: AppTheme.bgCard,
              color: AppTheme.cyanNeon,
              minHeight: 2,
            ),
          ),
      ],
    );
  }
}
