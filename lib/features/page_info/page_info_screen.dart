import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/browser_controller.dart';
import '../../core/theme/app_theme.dart';

class PageInfoScreen extends StatelessWidget {
  const PageInfoScreen({super.key, required this.controller});

  final BrowserController controller;

  @override
  Widget build(BuildContext context) {
    final tab = controller.tabs.active;
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('Page Info')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('Title', tab.title.isEmpty ? '—' : tab.title),
          _row('URL', tab.url),
          _row('Private', tab.private ? 'Yes' : 'No'),
          _row('Loading', tab.loading ? 'In progress (${tab.progress}%)' : 'Complete'),
          _row('Can go back', tab.canBack ? 'Yes' : 'No'),
          _row('Can go forward', tab.canForward ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Card(
      color: AppTheme.bgCard,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(k, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        subtitle: Text(v, style: GoogleFonts.inter(color: AppTheme.textPrimary)),
      ),
    );
  }
}
