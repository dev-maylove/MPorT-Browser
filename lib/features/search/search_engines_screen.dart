import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/browser_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/search_engine.dart';

class SearchEnginesScreen extends StatelessWidget {
  const SearchEnginesScreen({super.key, required this.controller});

  final BrowserController controller;

  IconData _icon(SearchEngine e) {
    switch (e.id) {
      case 'duckduckgo':
      case 'brave':
      case 'startpage':
        return Icons.shield_rounded;
      case 'ecosia':
        return Icons.eco_rounded;
      case 'bing':
        return Icons.grid_view_rounded;
      case 'yahoo':
      case 'yandex':
        return Icons.language_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final current = controller.searchEngine;
        return Scaffold(
          backgroundColor: AppTheme.bgDeep,
          appBar: AppBar(
            title: Text(
              'Search Engine',
              style: GoogleFonts.orbitron(fontWeight: FontWeight.w700),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Used when you type keywords in the address bar (not a URL). '
                  'Quick keywords: g, ddg, b, br, eco, sp, y, ya, gid.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              ...SearchEngines.all.map((engine) {
                final selected = engine.id == current.id;
                return Material(
                  color: selected
                      ? AppTheme.cyanNeon.withValues(alpha: 0.08)
                      : Colors.transparent,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.bgCard,
                      child: Icon(
                        _icon(engine),
                        color: selected
                            ? AppTheme.cyanNeon
                            : AppTheme.textSecondary,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      engine.name,
                      style: GoogleFonts.inter(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Keyword: ${engine.keyword}  ·  ${engine.homepage ?? engine.id}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppTheme.cyanNeon)
                        : null,
                    onTap: () async {
                      await controller.setSearchEngine(engine);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Search engine: ${engine.name}',
                              style: GoogleFonts.inter(),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                );
              }),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.cyanNeon.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    'Example: type "ddg best vpn" in the address bar to search DuckDuckGo without changing the default.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
