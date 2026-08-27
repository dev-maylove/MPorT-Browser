import 'package:uuid/uuid.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/browser_tab.dart';

class TabManager {
  final _uuid = const Uuid();
  final List<BrowserTab> tabs = [];
  int activeIndex = 0;

  BrowserTab create({
    required String initialUrl,
    bool private = false,
  }) {
    final tab = BrowserTab(
      id: _uuid.v4(),
      url: initialUrl,
      private: private,
    );
    tabs.add(tab);
    activeIndex = tabs.length - 1;
    return tab;
  }

  BrowserTab get active {
    if (tabs.isEmpty) {
      return create(initialUrl: 'about:blank');
    }
    if (activeIndex < 0 || activeIndex >= tabs.length) {
      activeIndex = tabs.length - 1;
    }
    return tabs[activeIndex];
  }

  void select(int index) {
    if (index >= 0 && index < tabs.length) {
      activeIndex = index;
    }
  }

  void close(int index) {
    if (index < 0 || index >= tabs.length) return;
    if (tabs.length == 1) {
      final only = tabs.first;
      only.url = 'about:blank';
      only.title = 'New Tab';
      only.loading = false;
      only.progress = 0;
      only.canBack = false;
      only.canForward = false;
      only.private = false;
      only.groupId = null;
      only.groupName = null;
      only.controller?.loadUrl(
        urlRequest: URLRequest(url: WebUri('about:blank')),
      );
      only.notify();
      return;
    }
    tabs.removeAt(index);
    if (activeIndex >= tabs.length) {
      activeIndex = tabs.length - 1;
    } else if (index < activeIndex) {
      activeIndex--;
    }
  }

  void closeOthers(int index) {
    if (index < 0 || index >= tabs.length) return;
    final keep = tabs[index];
    tabs
      ..clear()
      ..add(keep);
    activeIndex = 0;
  }

  void closePrivate() {
    tabs.removeWhere((x) => x.private);
    if (tabs.isEmpty) {
      create(initialUrl: 'about:blank');
    }
    if (activeIndex >= tabs.length) {
      activeIndex = tabs.length - 1;
    }
  }
}
