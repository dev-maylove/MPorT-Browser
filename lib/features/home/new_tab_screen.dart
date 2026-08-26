import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/browser_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../ai/ai_screen.dart';
import '../tabs/tabs_screen.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../history/history_screen.dart';
import '../downloads/downloads_screen.dart';
import '../browser/browser_screen.dart';
import '../search/search_engines_screen.dart';
import '../../widgets/browser_menu.dart';
import '../../models/search_engine.dart';

class NewTabScreen extends StatefulWidget {
  const NewTabScreen({super.key, required this.controller});
  final BrowserController controller;

  @override
  State<NewTabScreen> createState() => _NewTabScreenState();
}

class _NewTabScreenState extends State<NewTabScreen> {
  final address = TextEditingController();

  Future<void> _openAndBrowse(String text, {bool private = false}) async {
    final value = text.trim();
    if (value.isEmpty) return;
    await widget.controller.open(value, private: private);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BrowserScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _goToBrowser() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BrowserScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) => Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Stack(
          children: [
            // Background grid + soft orbs (MandalaNet style)
            const _BgLayer(),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    backgroundColor: AppTheme.bgDeep.withValues(alpha: 0.85),
                    title: Row(
                      children: [
                        Text(
                          'MPorT',
                          style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Browser',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Active browser',
                        onPressed: _goToBrowser,
                        icon: const Icon(Icons.language_rounded,
                            color: AppTheme.cyanNeon),
                      ),
                      IconButton(
                        tooltip: 'Tabs',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TabsScreen(controller: widget.controller),
                          ),
                        ),
                        icon: const Icon(Icons.tab_rounded),
                      ),
                      IconButton(
                        tooltip: 'Menu',
                        onPressed: () =>
                            BrowserMenu.show(context, widget.controller),
                        icon: const Icon(Icons.menu_rounded,
                            color: AppTheme.cyanNeon),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                      child: Column(
                        children: [
                          // Brand logo
                          Text(
                            'MPorT Browser',
                            style: GoogleFonts.orbitron(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Fast  ·  Private  ·  Intelligent',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'MandalaNet ISP Ecosystem',
                            style: GoogleFonts.inter(
                              color: AppTheme.cyanNeon.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 26),
                          TextField(
                            controller: address,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            onSubmitted: (value) => _openAndBrowse(value),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search_rounded),
                              hintText: 'Search or enter address...',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded,
                                    color: AppTheme.cyanNeon),
                                onPressed: () =>
                                    _openAndBrowse(address.text),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _searchEngineChips(context),
                          const SizedBox(height: 20),
                          _grid(context),
                          const SizedBox(height: 24),
                          _aiCard(context),
                          const SizedBox(height: 20),
                          Text(
                            AppConfig.webBaseUrl,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(BuildContext context) {
    final items = <(String, IconData, VoidCallback)>[
      (
        'Portal',
        Icons.dashboard_rounded,
        () => _openAndBrowse(AppConfig.webBaseUrl),
      ),
      (
        'Bookmark',
        Icons.bookmark_rounded,
        () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BookmarksScreen(controller: widget.controller),
              ),
            ),
      ),
      (
        'History',
        Icons.history_rounded,
        () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    HistoryScreen(controller: widget.controller),
              ),
            ),
      ),
      (
        'Download',
        Icons.download_rounded,
        () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DownloadsScreen()),
            ),
      ),
      (
        'Private',
        Icons.visibility_off_rounded,
        () => _openAndBrowse('about:blank', private: true),
      ),
      (
        'Tabs',
        Icons.tab_rounded,
        () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TabsScreen(controller: widget.controller),
              ),
            ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.12,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, i) {
        final item = items[i];
        return InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: item.$3,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.cyanNeon.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.$2, color: AppTheme.cyanNeon, size: 26),
                const SizedBox(height: 8),
                Text(
                  item.$1,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _aiCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          gradient: LinearGradient(
            colors: [
              AppTheme.cyanNeon.withValues(alpha: 0.18),
              AppTheme.blueAccent.withValues(alpha: 0.12),
              AppTheme.purpleAccent.withValues(alpha: 0.15),
            ],
          ),
          border: Border.all(
            color: AppTheme.cyanNeon.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cyanNeon.withValues(alpha: 0.12),
              blurRadius: 24,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.gradientAi,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 22,
                color: AppTheme.bgDeep,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MPorT AI',
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Smart assistant connected to the MPorT ISP backend.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.cyanNeon),
          ],
        ),
      ),
    );
  }


  Widget _searchEngineChips(BuildContext context) {
    final current = widget.controller.searchEngine;
    final quick = [
      SearchEngines.google,
      SearchEngines.duckDuckGo,
      SearchEngines.brave,
      SearchEngines.bing,
      SearchEngines.ecosia,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Search with',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SearchEnginesScreen(controller: widget.controller),
                ),
              ),
              child: Text(
                'All engines',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.cyanNeon,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quick.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final e = quick[i];
              final selected = e.id == current.id;
              return ChoiceChip(
                label: Text(e.name),
                selected: selected,
                onSelected: (_) async {
                  await widget.controller.setSearchEngine(e);
                  if (mounted) setState(() {});
                },
                selectedColor: AppTheme.cyanNeon.withValues(alpha: 0.25),
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppTheme.cyanNeon : AppTheme.textSecondary,
                ),
                backgroundColor: AppTheme.bgCard,
                side: BorderSide(
                  color: selected
                      ? AppTheme.cyanNeon
                      : AppTheme.cyanNeon.withValues(alpha: 0.12),
                ),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    address.dispose();
    super.dispose();
  }
}

class _BgLayer extends StatelessWidget {
  const _BgLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cyanNeon.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.purpleAccent.withValues(alpha: 0.07),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.018)
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
