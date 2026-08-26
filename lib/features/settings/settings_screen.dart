import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/browser_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../about/about_screen.dart';
import '../permissions/permissions_screen.dart';
import '../privacy/privacy_screen.dart';
import '../search/search_engines_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.controller, this.initialSection});

  final BrowserController? controller;
  final String? initialSection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        children: [
          _section('General'),
          _tile(Icons.tune_rounded, 'General', 'Startup, defaults, and behavior', null),
          if (controller != null)
            ListTile(
              leading: const Icon(Icons.search_rounded, color: AppTheme.cyanNeon),
              title: const Text('Search engine'),
              subtitle: Text(
                controller!.searchEngine.name,
                style: GoogleFonts.inter(fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchEnginesScreen(controller: controller!),
                  ),
                );
              },
            )
          else
            _tile(Icons.search_rounded, 'Search engine', 'Open from browser menu', null),

          _section('Appearance'),
          _tile(Icons.palette_outlined, 'Theme', 'Dark (MPorT neon)', null),
          _tile(Icons.font_download_outlined, 'Font size', 'System default', null),

          _section('Homepage'),
          _tile(Icons.home_outlined, 'Homepage', AppConfig.webBaseUrl, null),
          _tile(Icons.tab_outlined, 'New tab page', 'MPorT Home', null),

          _section('Tabs'),
          _tile(Icons.tab_rounded, 'Tab behavior', 'Restore last session', null),
          _tile(Icons.visibility_off_outlined, 'Private tabs', 'No history saved', null),

          _section('Downloads'),
          _tile(Icons.download_rounded, 'Download location', 'System default', null),
          _tile(Icons.folder_open_rounded, 'Ask where to save', 'Off', null),

          _section('Privacy'),
          ListTile(
            leading: const Icon(Icons.shield_rounded, color: AppTheme.cyanNeon),
            title: const Text('Privacy protection'),
            subtitle: const Text('Tracking, ads, private mode'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded, color: AppTheme.cyanNeon),
            title: const Text('Site permissions'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PermissionsScreen(manager: controller?.permissions),
                ),
              );
            },
          ),

          _section('Security'),
          _tile(Icons.security_rounded, 'Secure DNS', 'Provider default', null),
          _tile(Icons.https_rounded, 'HTTPS-Only Mode', 'Preferred', null),

          _section('Languages'),
          _tile(Icons.language_rounded, 'Display language', 'System', null),
          _tile(Icons.translate_rounded, 'Translate pages', 'Offer when needed', null),

          _section('Advanced'),
          _tile(Icons.developer_mode_rounded, 'Developer options', 'Diagnostics & console', null),
          _tile(Icons.storage_rounded, 'Storage', 'Cache and site data', null),

          _section('About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: AppTheme.cyanNeon),
            title: const Text('About MPorT Browser'),
            subtitle: Text(
              '${AppConfig.version} · ${AppConfig.brandName}',
              style: GoogleFonts.jetBrainsMono(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.auto_awesome_rounded, color: AppTheme.cyanNeon),
            title: Text('MPorT AI'),
            subtitle: Text('Connected via the MPorT Laravel API.'),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© MandalaNet · PT. Network Bumi Saridin',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppTheme.cyanNeon,
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.cyanNeon),
      title: Text(title),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 13)),
      onTap: onTap,
    );
  }
}
