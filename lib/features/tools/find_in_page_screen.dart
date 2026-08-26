import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/browser_controller.dart';
import '../../core/theme/app_theme.dart';

class FindInPageScreen extends StatefulWidget {
  const FindInPageScreen({super.key, required this.controller});

  final BrowserController controller;

  @override
  State<FindInPageScreen> createState() => _FindInPageScreenState();
}

class _FindInPageScreenState extends State<FindInPageScreen> {
  final _q = TextEditingController();

  Future<void> _find() async {
    final q = _q.text.trim();
    if (q.isEmpty) return;
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Find: "$q" (use browser find on web)')),
        );
      }
      return;
    }
    try {
      // Best-effort JS highlight
      await widget.controller.tabs.active.controller.runJavaScript(
        "window.find(${_jsStr(q)});",
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Searching for "$q"')),
        );
      }
    }
  }

  String _jsStr(String s) => "'${s.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('Find in Page')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _q,
              autofocus: true,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search on this page…',
                prefixIcon: const Icon(Icons.find_in_page_rounded),
                filled: true,
                fillColor: AppTheme.bgCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onSubmitted: (_) => _find(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _find,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Find'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
