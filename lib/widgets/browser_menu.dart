import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/browser_controller.dart';
import '../core/config/app_config.dart';
import '../features/about/about_screen.dart';
import '../features/bookmarks/bookmarks_screen.dart';
import '../features/downloads/downloads_screen.dart';
import '../features/extensions/extensions_screen.dart';
import '../features/history/history_screen.dart';
import '../features/privacy/privacy_screen.dart';
import '../features/search/search_engines_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tabs/tabs_screen.dart';
import '../features/tools/find_in_page_screen.dart';
import '../features/tools/share_sheet.dart';
import '../features/tools/translate_screen.dart';

/// Hamburger menu — visual match to MPorT design (right glass panel).
class BrowserMenu {
  static Future<void> show(BuildContext context, BrowserController controller) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Menu',
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, a, b) {
        return Align(
          alignment: Alignment.centerRight,
          child: _MenuPanel(controller: controller),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
              .animate(c),
          child: FadeTransition(opacity: c, child: child),
        );
      },
    );
  }
}

class _MenuPanel extends StatefulWidget {
  const _MenuPanel({required this.controller});
  final BrowserController controller;

  @override
  State<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<_MenuPanel> {
  BrowserController get c => widget.controller;

  bool get desktopSite => c.desktopSite;

  void _close() => Navigator.of(context).pop();

  void _open(Widget page) {
    _close();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final panelW = (w * 0.82).clamp(300.0, 340.0);
    final maxH = MediaQuery.sizeOf(context).height * 0.94;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
          child: Container(
            width: panelW,
            constraints: BoxConstraints(maxHeight: maxH),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xF00B1220),
              border: Border.all(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.45),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
                  blurRadius: 32,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 28,
                  offset: const Offset(-6, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                      children: [
                        // —— Tabs ——
                        _homeHighlight(),
                        _row(Icons.add_circle_outline_rounded, 'New tab', () {
                          _close();
                          c.open('about:blank');
                        }),
                        _row(Icons.visibility_off_outlined, 'New Private tab', () {
                          _close();
                          c.newPrivateTab();
                        }),
                        _row(Icons.grid_view_rounded, 'Add tab to new group', () {
                          _close();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tab groups coming soon')),
                          );
                        }),

                        _line(),

                        // —— Library ——
                        _row(Icons.history_rounded, 'History', () {
                          _open(HistoryScreen(controller: c));
                        }),
                        _row(Icons.download_rounded, 'Downloads', () {
                          _open(const DownloadsScreen());
                        }),
                        _row(Icons.bookmark_rounded, 'Bookmarks', () {
                          _open(BookmarksScreen(controller: c));
                        }),
                        _row(Icons.web_asset_rounded, 'Recent tabs', () {
                          _open(TabsScreen(controller: c));
                        }),

                        _section('BROWSER TOOLS'),

                        _row(Icons.search_rounded, 'Find in page', () {
                          _open(FindInPageScreen(controller: c));
                        }),
                        _row(Icons.translate_rounded, 'Translate', () {
                          _open(TranslateScreen(controller: c));
                        }),
                        _desktopToggle(),
                        _row(Icons.share_rounded, 'Share', () {
                          _close();
                          ShareSheet.shareCurrent(context, c);
                        }),
                        _row(Icons.extension_rounded, 'Extensions', () {
                          _open(const ExtensionsScreen());
                        }),

                        _section('PRIVACY & SECURITY'),

                        _row(Icons.shield_rounded, 'Privacy & Security', () {
                          _open(const PrivacyScreen());
                        }),
                        _row(Icons.delete_outline_rounded, 'Clear Browsing Data', () {
                          _open(const PrivacyScreen());
                        }),

                        _section('SYSTEM'),

                        _row(Icons.settings_rounded, 'Settings', () {
                          _open(SettingsScreen(controller: c));
                        }),
                        _row(Icons.language_rounded, 'Search Engine', () {
                          _open(SearchEnginesScreen(controller: c));
                        }),
                        if (!kIsWeb)
                          _row(Icons.smartphone_rounded, 'Set as Default Browser', () {
                            _close();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Open system settings to set MPorT as default browser',
                                ),
                              ),
                            );
                          }),

                        _section('ABOUT'),

                        _row(Icons.info_outline_rounded, 'About MPorT Browser', () {
                          _open(const AboutScreen());
                        }),
                        _row(Icons.chat_bubble_outline_rounded, 'Feedback', () {
                          _close();
                          c.open(
                            'mailto:support@mandalanet.id?subject=MPorT%20Browser%20Feedback',
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header (logo + title + Secure + close) ───────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo circle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/mport_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF0A1525),
                child: Icon(Icons.public_rounded, color: Color(0xFF00E5FF), size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MPorT Browser',
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withValues(alpha: 0.7),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Secure',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00E676),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _close,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.75),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Highlighted first row (New Home tab) ─────────────────────────────

  Widget _homeHighlight() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _close();
            c.open(AppConfig.webBaseUrl);
          },
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A6B8A), Color(0xFF0D4A6E)],
              ),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                const Icon(Icons.home_rounded, color: Color(0xFF00E5FF), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'New Home tab',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.9),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Standard row ─────────────────────────────────────────────────────

  Widget _row(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00E5FF), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFE8EEF8),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFF00E5FF).withValues(alpha: 0.55),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Desktop site toggle (matches screenshot) ─────────────────────────

  Widget _desktopToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.desktop_windows_rounded, color: Color(0xFF00E5FF), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Desktop site',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFE8EEF8),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: desktopSite,
              activeThumbColor: const Color(0xFF00E5FF),
              activeTrackColor: const Color(0xFF00E5FF).withValues(alpha: 0.35),
              inactiveThumbColor: const Color(0xFF9AA3B5),
              inactiveTrackColor: const Color(0xFF2A3344),
              onChanged: (v) async {
                await c.setDesktopSite(v);
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(v ? 'Desktop site on' : 'Mobile site'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section label + cyan line ────────────────────────────────────────

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.15,
              color: const Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1.2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x9900E5FF),
                    Color(0x0000E5FF),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Container(
        height: 1,
        color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
      ),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public_rounded,
            size: 13,
            color: const Color(0xFF00E5FF).withValues(alpha: 0.65),
          ),
          const SizedBox(width: 8),
          Text(
            'MPorT Browser  ·  v${AppConfig.version}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF7A8499),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
