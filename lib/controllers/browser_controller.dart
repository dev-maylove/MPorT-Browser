import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../browser/tab_manager.dart';
import '../core/config/app_config.dart';
import '../core/utils/url_utils.dart';
import '../core/utils/perf.dart';
import '../models/browser_tab.dart';
import '../models/history_entry.dart';
import '../models/permission_rule.dart';
import '../models/search_engine.dart';
import '../security/permission_manager.dart';
import '../security/tracker_blocker.dart';
import '../services/storage_service.dart';
import '../services/search_service.dart';
import '../core/platform/native_bridge.dart';

class BrowserController extends ChangeNotifier {
  final tabs = TabManager();
  final storage = StorageService();
  final permissions = PermissionManager();
  final blocker = TrackerBlocker();
  late final SearchService search;

  final _throttle = NotifyThrottle(
    minInterval: kIsWeb
        ? const Duration(milliseconds: 48)
        : const Duration(milliseconds: 24),
  );
  final _frame = FrameCoalescer();

  bool initialized = false;

  /// When true, WebView uses a desktop Chrome user-agent.
  bool desktopSite = false;

  static const _desktopUa =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';
  static const _mobileUa =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

  BrowserController() {
    search = SearchService(storage: storage);
    UrlUtils.searchService = search;
  }

  SearchEngine get searchEngine => search.current;

  void _notify() {
    _frame.schedule(() {
      _throttle(() {
        if (hasListeners) notifyListeners();
      });
    });
  }

  Future<void> initialize() async {
    if (initialized) return;
    await search.load();
    UrlUtils.searchService = search;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      NativeBridge.setWebEventListener(_handleNativeWebEvent);
    }

    await storage.migrateSensitiveData();
    await permissions.load();
    final savedTabs = await storage.sessionTabs();
    if (savedTabs.isEmpty) {
      final tab = tabs.create(initialUrl: AppConfig.webBaseUrl);
      await _attach(tab);
      if (!kIsWeb) {
        try {
          await tab.controller.loadRequest(Uri.parse(AppConfig.webBaseUrl));
        } catch (_) {
          tab.loading = false;
          tab.progress = 0;
          tab.title = 'Unable to load page';
          tab.notify();
        }
      } else {
        tab.url = AppConfig.webBaseUrl;
        tab.loading = false;
        tab.progress = 100;
      }
    } else {
      for (final saved in savedTabs.take(12)) {
        final url = '${saved['url']}';
        final tab = tabs.create(initialUrl: url, private: false);
        tab.title = '${saved['title'] ?? 'New Tab'}';
        await _attach(tab);
        if (!kIsWeb) {
          try { await tab.controller.loadRequest(Uri.parse(url)); } catch (_) {}
        }
      }
      final savedIndex = await storage.sessionActiveIndex();
      tabs.select(savedIndex);
    }
    initialized = true;
    _notify();
  }

  Future<void> setSearchEngine(SearchEngine engine) async {
    await search.setEngine(engine);
    _notify();
  }

  Future<void> _attach(BrowserTab tab) async {
    if (kIsWeb) return;

    final controller = tab.controller;
    // ignore: discarded_futures
    _applyUserAgent(controller);
    _configureAndroidWebView(controller);

    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      android.setOnPlatformPermissionRequest((request) async {
        final host = Uri.tryParse(tab.url)?.host.toLowerCase() ?? '';
        var allow = true;
        final resources = request.types;
        if (resources.contains(WebViewPermissionResourceType.camera)) {
          final state = permissions.state(host, PermissionType.camera);
          if (state == PermissionState.deny) allow = false;
          if (state != PermissionState.deny && !(await permissions.requestNative(PermissionType.camera))) allow = false;
        }
        if (resources.contains(WebViewPermissionResourceType.microphone)) {
          final state = permissions.state(host, PermissionType.microphone);
          if (state == PermissionState.deny) allow = false;
          if (state != PermissionState.deny && !(await permissions.requestNative(PermissionType.microphone))) allow = false;
        }
        if (allow) { await request.grant(); } else { await request.deny(); }
      });
      await android.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          final host = Uri.tryParse(request.origin)?.host.toLowerCase() ?? '';
          final state = permissions.state(host, PermissionType.location);
          if (state == PermissionState.deny) return const GeolocationPermissionsResponse(allow: false, retain: false);
          final granted = await permissions.requestNative(PermissionType.location);
          return GeolocationPermissionsResponse(allow: granted, retain: granted);
        },
      );
      try { await android.setMixedContentMode(MixedContentMode.neverAllow); } catch (_) {}
      try { await android.setWebAuthenticationSupport(WebAuthenticationSupport.forBrowser); } catch (_) {}

      final id = android.webViewIdentifier;
      if (tab.private) {
        await NativeBridge.configurePrivateWebView(id);
      }
      await NativeBridge.installResourceBlocker(
        identifier: id,
        tabId: tab.id,
        allowHttp: AppConfig.enableHttp,
      );
      // The native WebViewClient now owns Android page/resource events so that
      // shouldInterceptRequest can run without replacing it from Dart.
      return;
    }

    // iOS / other native platforms retain the plugin navigation delegate.
    controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (value) {
          tab.progress = value;
          tab.notify();
          _notify();
        },
        onPageStarted: (url) {
          tab.loading = true;
          tab.url = url;
          tab.notify();
          _notify();
        },
        onPageFinished: (url) async {
          await _handlePageFinished(tab, url);
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri != null && blocker.shouldBlock(uri)) return NavigationDecision.prevent;
          if (uri != null && uri.scheme.toLowerCase() == 'http' && !AppConfig.enableHttp) return NavigationDecision.prevent;
          return NavigationDecision.navigate;
        },
      ),
    );
  }

  Future<void> _handlePageFinished(BrowserTab tab, String url, {String? nativeTitle, bool? nativeCanBack, bool? nativeCanForward}) async {
    tab.loading = false;
    tab.progress = 100;
    tab.url = url;
    applyDesktopViewport(tab.controller);
    try {
      tab.canBack = nativeCanBack ?? await tab.controller.canGoBack();
      tab.canForward = nativeCanForward ?? await tab.controller.canGoForward();
    } catch (_) {}

    try {
      final title = nativeTitle ?? await tab.controller.getTitle();
      if (title != null && title.trim().isNotEmpty) tab.title = title.trim();
    } catch (_) {}

    if (!tab.private && url.isNotEmpty && url != 'about:blank') {
      await storage.addHistory(HistoryEntry(url: url, title: tab.title, visitedAt: DateTime.now(), private: tab.private));
    }
    tab.notify();
    await _saveSession();
    _notify();
  }

  void _handleNativeWebEvent(String event, Map<String, dynamic> data) {
    final id = data['tabId']?.toString();
    if (id == null || id.isEmpty) return;
    BrowserTab? tab;
    for (final candidate in tabs.tabs) {
      if (candidate.id == id) { tab = candidate; break; }
    }
    if (tab == null) return;

    switch (event) {
      case 'pageStarted':
        tab.loading = true;
        tab.progress = 0;
        tab.url = data['url']?.toString() ?? tab.url;
        tab.notify();
        _notify();
        break;
      case 'pageFinished':
        // ignore: discarded_futures
        _handlePageFinished(
          tab,
          data['url']?.toString() ?? tab.url,
          nativeTitle: data['title']?.toString(),
          nativeCanBack: data['canGoBack'] == true,
          nativeCanForward: data['canGoForward'] == true,
        );
        break;
      case 'pageError':
        tab.loading = false;
        tab.progress = 0;
        tab.notify();
        _notify();
        break;
      case 'navigationBlocked':
        // Keep the current document intact; the native layer cancelled the navigation.
        break;
      case 'resourceBlocked':
        // Resource-level filtering is intentionally silent to the user.
        break;
    }
  }

  Future<void> _saveSession() async {
    await storage.saveSession(
      tabs.tabs.map((t) => <String, dynamic>{'url': t.url, 'title': t.title, 'private': t.private}).toList(),
      tabs.activeIndex,
    );
  }

  Future<void> open(String value, {bool private = false}) async {
    final url = UrlUtils.normalize(value);
    final tab = tabs.create(initialUrl: url, private: private);
    await _attach(tab);
    if (kIsWeb) {
      tab.url = url;
      tab.loading = false;
      tab.progress = 100;
      tab.title = _titleFromUrl(url);
      tab.notify();
    } else {
      try {
        await tab.controller.loadRequest(Uri.parse(url));
      } catch (_) {
        tab.loading = false;
        tab.progress = 0;
        tab.title = 'Unable to load page';
        tab.notify();
      }
    }
    // History is recorded once from NavigationDelegate.onPageFinished, after
    // the final URL/title are known.
    await _saveSession();
    _notify();
  }

  Future<void> searchQuery(
    String query, {
    SearchEngine? engine,
    bool newTab = false,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final eng = engine ?? search.current;
    final url = eng.buildSearchUrl(q);
    if (newTab) {
      await open(url);
    } else {
      await load(url);
    }
  }

  Future<void> openInNewTab(String url, {bool private = false}) async {
    await open(url, private: private);
  }

  Future<void> load(String value) async {
    if (tabs.tabs.isEmpty) {
      await open(value);
      return;
    }
    final url = UrlUtils.normalize(value);
    final tab = tabs.active;
    tab.url = url;
    tab.loading = !kIsWeb;
    tab.progress = kIsWeb ? 100 : 0;
    tab.notify();
    if (!kIsWeb) {
      try {
        await tab.controller.loadRequest(Uri.parse(url));
      } catch (_) {
        tab.loading = false;
        tab.progress = 0;
        tab.title = 'Unable to load page';
        tab.notify();
      }
    } else {
      tab.loading = false;
      tab.progress = 100;
      tab.title = _titleFromUrl(url);
      tab.notify();
    }
    _notify();
  }

  Future<void> setDesktopSite(bool enabled) async {
    desktopSite = enabled;
    await _applyUserAgentToAllTabs();
    if (tabs.tabs.isNotEmpty) {
      final tab = tabs.active;
      final url = tab.url;
      if (!kIsWeb && url.isNotEmpty && url != 'about:blank') {
        try {
          await tab.controller.loadRequest(Uri.parse(url));
        } catch (_) {
          await load(url);
        }
      } else if (url.isNotEmpty && url != 'about:blank') {
        await load(url);
      }
    }
    _notify();
  }

  Future<void> applyDesktopViewport(WebViewController controller) async {
    if (kIsWeb) return;
    try {
      if (desktopSite) {
        await controller.runJavaScript(
          "(function(){var w=Math.max(1280,window.screen.width||1280);"
          "var m=document.querySelector('meta[name=viewport]');"
          "if(!m){m=document.createElement('meta');m.name='viewport';"
          "document.head.appendChild(m);}"
          "m.setAttribute('content','width='+w+', initial-scale=1');"
          "if(document.body)document.body.style.minWidth=w+'px';})();",
        );
      } else {
        await controller.runJavaScript(
          "(function(){var m=document.querySelector('meta[name=viewport]');"
          "if(m)m.setAttribute('content','width=device-width, initial-scale=1');"
          "if(document.body)document.body.style.minWidth='';})();",
        );
      }
    } catch (_) {}
  }

  Future<void> _applyUserAgentToAllTabs() async {
    if (kIsWeb) return;
    final ua = desktopSite ? _desktopUa : _mobileUa;
    for (final tab in tabs.tabs) {
      try {
        await tab.controller.setUserAgent(ua);
      } catch (_) {}
    }
  }

  Future<void> _applyUserAgent(WebViewController controller) async {
    if (kIsWeb) return;
    try {
      await controller.setUserAgent(desktopSite ? _desktopUa : _mobileUa);
    } catch (_) {}
  }

  void _configureAndroidWebView(WebViewController controller) {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final platform = controller.platform;
      if (platform is AndroidWebViewController) {
        platform.setMediaPlaybackRequiresUserGesture(false);
        AndroidWebViewController.enableDebugging(false);
      }
    } catch (_) {}
  }

  Future<void> translatePageWithGoogle({String targetLang = 'id'}) async {
    if (tabs.tabs.isEmpty) return;
    final tab = tabs.active;
    final url = tab.url;
    if (url.isEmpty ||
        url == 'about:blank' ||
        url.startsWith('chrome:') ||
        url.startsWith('file:') ||
        url.startsWith('data:')) {
      return;
    }

    if (!kIsWeb) {
      try {
        final js = _googleTranslateInjectJs(targetLang);
        final result = await tab.controller.runJavaScriptReturningResult(js);
        final s = result.toString();
        if (s.startsWith('err')) {
          await _openGoogleTranslateProxy(url, targetLang);
        }
        return;
      } catch (_) {
        await _openGoogleTranslateProxy(url, targetLang);
        return;
      }
    }
    await _openGoogleTranslateProxy(url, targetLang);
  }

  String _googleTranslateInjectJs(String targetLang) {
    final lang = targetLang.replaceAll("'", '');
    return '(function(){'
        'try {'
        "var old=document.getElementById('mport-gt-root');if(old)old.remove();"
        "var root=document.createElement('div');root.id='mport-gt-root';"
        "root.style.cssText='position:fixed;top:0;left:0;right:0;z-index:2147483647;background:#0b1220;padding:6px 8px';"
        "var box=document.createElement('div');box.id='google_translate_element';root.appendChild(box);"
        'document.body.prepend(root);'
        'window.googleTranslateElementInit=function(){'
        'new google.translate.TranslateElement({'
        "pageLanguage:'auto',"
        "includedLanguages:'id,en,ja,ko,zh-CN,zh-TW,ar,es,fr,de,pt,ru,th,vi,hi,ms',"
        'layout:google.translate.TranslateElement.InlineLayout.SIMPLE,'
        'autoDisplay:false'
        "},'google_translate_element');"
        'setTimeout(function(){'
        "var sel=document.querySelector('.goog-te-combo');"
        "if(sel){sel.value='$lang';sel.dispatchEvent(new Event('change'));}"
        '},900);'
        '};'
        "if(!document.getElementById('mport-gt-script')){"
        "var s=document.createElement('script');s.id='mport-gt-script';"
        "s.src='https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit';"
        'document.head.appendChild(s);'
        '}else if(window.googleTranslateElementInit){window.googleTranslateElementInit();}'
        "return 'ok';"
        "}catch(e){return 'err:'+e;}"
        '})();';
  }

  Future<void> _openGoogleTranslateProxy(String url, String targetLang) async {
    final encoded = Uri.encodeComponent(url);
    await load(
      'https://translate.google.com/translate?sl=auto&tl=$targetLang&hl=$targetLang&u=$encoded&client=webapp',
    );
  }

  Future<void> showOriginalPage() async {
    if (tabs.tabs.isEmpty || kIsWeb) return;
    try {
      await tabs.active.controller.runJavaScript(
        "(function(){var el=document.getElementById('mport-gt-root');if(el)el.remove();"
        "var b=document.querySelector('.goog-te-banner-frame');if(b&&b.parentNode)b.parentNode.removeChild(b);"
        "document.body.style.top='0';})();",
      );
    } catch (_) {}
  }

  Future<bool> back() async {
    if (tabs.tabs.isEmpty || kIsWeb) return false;
    try {
      if (await tabs.active.controller.canGoBack()) {
        await tabs.active.controller.goBack();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> forward() async {
    if (tabs.tabs.isEmpty || kIsWeb) return;
    if (await tabs.active.controller.canGoForward()) {
      await tabs.active.controller.goForward();
    }
  }

  Future<void> refresh() async {
    if (tabs.tabs.isEmpty) return;
    if (kIsWeb) {
      final tab = tabs.active;
      final u = tab.url;
      tab.url = 'about:blank';
      tab.notify();
      _notify();
      await Future<void>.delayed(const Duration(milliseconds: 16));
      tab.url = u;
      tab.notify();
      _notify();
      return;
    }
    await tabs.active.controller.reload();
  }

  void selectTab(int index) {
    tabs.select(index);
    _saveSession();
    _notify();
  }

  void closeTab(int index) {
    tabs.close(index);
    _saveSession();
    _notify();
  }

  void newPrivateTab() {
    open('about:blank', private: true);
  }

  Future<void> newHomeTab() async {
    await open('about:blank', private: false);
  }

  Future<void> newTab() async {
    await open('about:blank', private: false);
  }

  void addActiveTabToNewGroup({String name = 'Group'}) {
    if (tabs.tabs.isEmpty) return;
    final tab = tabs.active;
    final gid = 'g_${DateTime.now().millisecondsSinceEpoch}';
    tab.groupId = gid;
    tab.groupName = name;
    tab.notify();
    _notify();
  }

  void closePrivateTabs() {
    tabs.closePrivate();
    _notify();
  }

  String _titleFromUrl(String url) {
    if (url.isEmpty || url == 'about:blank') return 'New Tab';
    try {
      final host = Uri.parse(url).host;
      if (host.isNotEmpty) return host;
    } catch (_) {}
    return url;
  }

  @override
  void dispose() {
    _throttle.dispose();
    super.dispose();
  }
}
