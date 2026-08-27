import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/browser_controller.dart';
import '../../core/theme/app_theme.dart';

/// Page translation — Google Translate (Chrome-like) + language picker.
class TranslateScreen extends StatelessWidget {
  const TranslateScreen({super.key, required this.controller});

  final BrowserController controller;

  static const _langs = <String, String>{
    'id': 'Bahasa Indonesia',
    'en': 'English',
    'ja': '日本語 (Japanese)',
    'ko': '한국어 (Korean)',
    'zh-CN': '中文简体 (Chinese)',
    'zh-TW': '中文繁體',
    'ar': 'العربية (Arabic)',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt': 'Português',
    'ru': 'Русский',
    'th': 'ไทย (Thai)',
    'vi': 'Tiếng Việt',
    'hi': 'हिन्दी (Hindi)',
    'ms': 'Bahasa Melayu',
  };

  Future<void> _translate(BuildContext context, String code) async {
    final url = controller.tabs.active.url;
    if (url.isEmpty ||
        url == 'about:blank' ||
        url.startsWith('about:') ||
        url.startsWith('chrome:')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Open a web page first to translate')),
        );
      }
      return;
    }
    Navigator.pop(context);
    await controller.translatePageWithGoogle(targetLang: code);
  }

  @override
  Widget build(BuildContext context) {
    final pageUrl = controller.tabs.active.url;
    final canTranslate = pageUrl.isNotEmpty &&
        pageUrl != 'about:blank' &&
        !pageUrl.startsWith('about:');

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: Text(
          'Translate',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.cyanNeon.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.translate_rounded, color: AppTheme.cyanNeon),
                    const SizedBox(width: 10),
                    Text(
                      'Google Translate',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  canTranslate
                      ? 'Current page will be translated in-page (like Chrome).'
                      : 'Open a website first, then choose a language.',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (canTranslate) ...[
                  const SizedBox(height: 6),
                  Text(
                    pageUrl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'TRANSLATE THIS PAGE TO',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppTheme.cyanNeon,
            ),
          ),
          const SizedBox(height: 10),
          ..._langs.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.cyanNeon.withValues(alpha: 0.15),
                    child: Text(
                      e.key.length > 2 ? e.key.substring(0, 2).toUpperCase() : e.key.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.cyanNeon,
                      ),
                    ),
                  ),
                  title: Text(e.value),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  enabled: canTranslate,
                  onTap: canTranslate ? () => _translate(context, e.key) : null,
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          ListTile(
            tileColor: AppTheme.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.undo_rounded, color: AppTheme.cyanNeon),
            title: const Text('Show original page'),
            onTap: () async {
              Navigator.pop(context);
              await controller.showOriginalPage();
              // If on translate.google proxy, go back
              final went = await controller.back();
              if (!went) {
                // no-op
              }
            },
          ),
        ],
      ),
    );
  }
}
