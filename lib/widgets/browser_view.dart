import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/browser_tab.dart';
import '../core/theme/app_theme.dart';
import 'web_iframe_stub.dart'
    if (dart.library.html) 'web_iframe_web.dart' as iframe;

/// Renders page with Chromium-based engine:
/// - Android: System WebView (Chromium) via flutter_inappwebview
/// - iOS: WKWebView
/// - Web: iframe fallback
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
        return _ChromiumWebView(tab: tab);
      },
    );
  }
}

class _ChromiumWebView extends StatefulWidget {
  const _ChromiumWebView({required this.tab});
  final BrowserTab tab;

  @override
  State<_ChromiumWebView> createState() => _ChromiumWebViewState();
}

class _ChromiumWebViewState extends State<_ChromiumWebView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  BrowserTab get tab => widget.tab;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final initial = tab.url.isEmpty ? 'about:blank' : tab.url;

    return Stack(
      fit: StackFit.expand,
      children: [
        InAppWebView(
          key: ValueKey('wv-${tab.id}'),
          initialUrlRequest: URLRequest(url: WebUri(initial)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            databaseEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            useHybridComposition: true,
            supportZoom: true,
            builtInZoomControls: true,
            displayZoomControls: false,
            thirdPartyCookiesEnabled: !tab.private,
            cacheEnabled: !tab.private,
            clearCache: tab.private,
            userAgent:
                'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
            allowsBackForwardNavigationGestures: true,
            isInspectable: kDebugMode,
            mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
            safeBrowsingEnabled: true,
            incognito: tab.private,
          ),
          onWebViewCreated: (controller) {
            tab.controller = controller;
          },
          onLoadStart: (controller, url) {
            tab.loading = true;
            if (url != null) tab.url = url.toString();
            tab.notify();
          },
          onProgressChanged: (controller, progress) {
            tab.progress = progress;
            tab.notify();
          },
          onLoadStop: (controller, url) async {
            tab.loading = false;
            if (url != null) tab.url = url.toString();
            try {
              tab.canBack = await controller.canGoBack();
              tab.canForward = await controller.canGoForward();
              final title = await controller.getTitle();
              if (title != null && title.trim().isNotEmpty) {
                tab.title = title.trim();
              }
            } catch (_) {}
            tab.notify();
          },
          onTitleChanged: (controller, title) {
            if (title != null && title.trim().isNotEmpty) {
              tab.title = title.trim();
              tab.notify();
            }
          },
          onUpdateVisitedHistory: (controller, url, isReload) {
            if (url != null) {
              tab.url = url.toString();
              tab.notify();
            }
          },
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
