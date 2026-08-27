import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BrowserTab {
  BrowserTab({
    required this.id,
    required this.controller,
    required this.url,
    this.title = 'New Tab',
    this.private = false,
    this.groupId,
    this.groupName,
  });

  final String id;
  final WebViewController controller;
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

  void notify() => revision.value++;
}
