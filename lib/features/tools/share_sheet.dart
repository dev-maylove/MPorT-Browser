import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/browser_controller.dart';

class ShareSheet {
  static Future<void> shareCurrent(BuildContext context, BrowserController controller) async {
    final tab = controller.tabs.active;
    final text = '${tab.title}\n${tab.url}';
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }
}
