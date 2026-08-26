import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/browser_controller.dart';
import '../../core/theme/app_theme.dart';
import '../ai/ai_screen.dart';

class TranslateScreen extends StatelessWidget {
  const TranslateScreen({super.key, required this.controller});

  final BrowserController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('Translate')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Translate the current page with MPorT AI or open a translation service.',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: AppTheme.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const Icon(Icons.auto_awesome_rounded, color: AppTheme.cyanNeon),
            title: const Text('Translate with MPorT AI'),
            subtitle: const Text('Indonesian / English'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiScreen(
                    initialPrompt: 'Translate this page to Indonesian',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: AppTheme.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const Icon(Icons.translate_rounded, color: AppTheme.cyanNeon),
            title: const Text('Open Google Translate'),
            onTap: () {
              final url = controller.tabs.active.url;
              final target =
                  'https://translate.google.com/translate?sl=auto&tl=id&u=${Uri.encodeComponent(url)}';
              Navigator.pop(context);
              controller.open(target);
            },
          ),
        ],
      ),
    );
  }
}
