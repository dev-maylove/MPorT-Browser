import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/browser_tab.dart';

class TabManager {
  final _uuid = const Uuid();
  final List<BrowserTab> tabs = [];
  int activeIndex = 0;

  BrowserTab create({
    required String initialUrl,
    bool private = false,
  }) {
    final controller = WebViewController();
    if (!kIsWeb) {
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF06080F))
        ..enableZoom(true);
    }

    final tab = BrowserTab(
      id: _uuid.v4(),
      controller: controller,
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
      only.notify();
      if (!kIsWeb) {
        try {
          only.controller.loadRequest(Uri.parse('about:blank'));
        } catch (_) {}
      }
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
    if (tabs.isEmpty) {
      create(initialUrl: 'about:blank');
      return;
    }

    final oldActive = activeIndex;
    final activeCutoff = oldActive.clamp(0, tabs.length).toInt();
    final removedBeforeActive = tabs
        .take(activeCutoff)
        .where((tab) => tab.private)
        .length;

    tabs.removeWhere((tab) => tab.private);

    if (tabs.isEmpty) {
      activeIndex = 0;
      create(initialUrl: 'about:blank');
      return;
    }

    // Preserve the same logical active tab when private tabs before it are
    // removed; clamp when the old active tab itself was private.
    activeIndex = (oldActive - removedBeforeActive)
        .clamp(0, tabs.length - 1)
        .toInt();
  }
}
