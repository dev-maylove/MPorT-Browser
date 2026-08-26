// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

final Set<String> _registered = {};

void registerIframeFactory(String viewType, String url) {
  if (_registered.contains(viewType)) {
    final el = html.document.getElementById(viewType);
    if (el is html.IFrameElement && el.src != url) {
      el.src = url;
    }
    return;
  }
  _registered.add(viewType);
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..id = viewType
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow =
          'fullscreen; clipboard-read; clipboard-write; geolocation; microphone; camera'
      ..allowFullscreen = true;
    return iframe;
  });
}

Widget buildWebIframe({required String viewType, required String url}) {
  registerIframeFactory(viewType, url);
  // Stable key per tab — changing URL must NOT re-register the factory.
  return HtmlElementView(viewType: viewType, key: ValueKey(viewType));
}
