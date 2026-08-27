import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../browser/tab_manager.dart';
import '../core/config/app_config.dart';
import '../core/utils/url_utils.dart';
import '../core/utils/perf.dart';
import '../models/browser_tab.dart';
import '../models/history_entry.dart';
import '../models/search_engine.dart';
import '../security/permission_manager.dart';
import '../security/tracker_blocker.dart';
import '../services/storage_service.dart';
import '../services/search_service.dart';

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

    final tab = tabs.create(initialUrl: AppConfig.webBaseUrl);
    _attach(tab);
    if (!kIsWeb) {
      try {
        await tab.controller.loadRequest(Uri.parse(AppConfig.webBaseUrl));
      } catch (_) {}
    } else {
      tab.url = AppConfig.webBaseUrl;
      tab.loading = false;
      tab.progress = 100;
    }
    initialized = true;
    _notify();
  }

  Future<void> setSearchEngine(SearchEngine engine) async {
    await search.setEngine(engine);
    _notify();
  }

  void _attach(BrowserTab tab) {
    if (kIsWeb) return;

    final controller = tab.controller;
    // ignore: discarded_futures
    _applyUserAgent(controller);
    _configureAndroidWebView(controller);
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
          tab.loading = false;
          tab.url = url;
          // ignore: discarded_futures
          applyDesktopViewport(controller);
          try {
            tab.canBack = await controller.canGoBack();
            tab.canForward = await controller.canGoForward();
          } catch (_) {}

          try {
            final title = await controller.getTitle();
            if (title != null && title.trim().isNotEmpty) {
              tab.title = title.trim();
            }
          } catch (_) {}

          if (!tab.private && url.isNotEmpty && url != 'about:blank') {
            storage.addHistory(
              HistoryEntry(
                url: url,
                title: tab.title,
                visitedAt: DateTime.now(),
                private: false,
              ),
            );
          }

          tab.notify();
          _notify();
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri != null && blocker.shouldBlock(uri)) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }

  Future<void> open(String value, {bool private = false}) async {
    final url = UrlUtils.normalize(value);
    final tab = tabs.create(initialUrl: url, private: private);
    _attach(tab);
    if (kIsWeb) {
      tab.url = url;
      tab.loading = false;
      tab.progress = 100;
      tab.title = _titleFromUrl(url);
      tab.notify();
    } else {
      try {
        await tab.controller.loadRequest(Uri.parse(url));
      } catch (_) {}
    }
    if (!private && url != 'about:blank') {
      storage.addHistory(
        HistoryEntry(
          url: url,
          title: tab.title,
          visitedAt: DateTime.now(),
        ),
      );
    }
    _notify();
  }

  /// Explicit search using current (or given) engine.
  Future<void> searchQuery(String query, {SearchEngine? engine, bool newTab = false}) async {
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
      } catch (_) {}
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


  /// Chrome-like page translation via Google Website Translator injection.
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
        final s = result?.toString() ?? '';
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
        "if(sel){sel.value='" + lang + "';sel.dispatchEvent(new Event('change'));}"
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
    // client=webapp is more reliable than classic iframe error dog
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

  /// Returns true if WebView history went back.
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
    _notify();
  }

  void closeTab(int index) {
    tabs.close(index);
    _notify();
  }

  void newPrivateTab() {
    open('about:blank', private: true);
  }

  /// Open a fresh home / start page tab (about:blank landing).
  Future<void> newHomeTab() async {
    await open('about:blank', private: false);
  }

  /// Open a normal new tab.
  Future<void> newTab() async {
    await open('about:blank', private: false);
  }

  /// Assign active tab to a new named group.
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


  /// Native Android System WebView tuning (media, DOM storage, mixed content).
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
