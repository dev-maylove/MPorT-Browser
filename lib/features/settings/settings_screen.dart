import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/browser_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/storage_service.dart';
import '../about/about_screen.dart';
import '../developer/developer_screen.dart';
import '../permissions/permissions_screen.dart';
import '../privacy/privacy_screen.dart';
import '../search/search_engines_screen.dart';
import '../tabs/tabs_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.controller, this.initialSection});

  final BrowserController? controller;
  final String? initialSection;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final storage = StorageService();
  bool trackingProtection = true;
  bool adBlocking = true;
  bool httpsOnly = true;
  bool showImages = true;
  bool javascriptEnabled = true;
  String homepage = AppConfig.webBaseUrl;

  BrowserController? get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    trackingProtection =
        await storage.getBool('tracking_protection', defaultValue: true);
    adBlocking = await storage.getBool('ad_blocking', defaultValue: true);
    httpsOnly = await storage.getBool('https_only', defaultValue: true);
    showImages = await storage.getBool('show_images', defaultValue: true);
    javascriptEnabled =
        await storage.getBool('javascript_enabled', defaultValue: true);
    homepage = await storage.getString('homepage') ?? AppConfig.webBaseUrl;
    if (mounted) setState(() {});
  }

  Future<void> _editHomepage() async {
    final ctrl = TextEditingController(text: homepage);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Homepage'),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'https://...',
            hintStyle: TextStyle(color: AppTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await storage.setString('homepage', result);
      setState(() => homepage = result);
    }
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppTheme.cyanNeon,
        ),
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.cyanNeon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted)),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

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
          _tile(Icons.home_rounded, 'Homepage', homepage, _editHomepage),
          _tile(
            Icons.search_rounded,
            'Search engine',
            controller?.searchEngine.name ?? 'Default',
            controller == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SearchEnginesScreen(controller: controller!),
                      ),
                    );
                  },
          ),
          _tile(
            Icons.palette_rounded,
            'Appearance',
            'Dark theme',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dark theme is active')),
              );
            },
          ),
          _tile(
            Icons.tab_rounded,
            'Tabs',
            'Open tabs manager',
            controller == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TabsScreen(controller: controller!),
                      ),
                    );
                  },
          ),
          _section('Privacy'),
          SwitchListTile(
            value: trackingProtection,
            title: const Text('Tracking protection'),
            subtitle: const Text('Block known trackers'),
            activeColor: AppTheme.cyanNeon,
            onChanged: (v) async {
              await storage.setBool('tracking_protection', v);
              setState(() => trackingProtection = v);
            },
          ),
          SwitchListTile(
            value: adBlocking,
            title: const Text('Ad blocking'),
            subtitle: const Text('Block common ad domains'),
            activeColor: AppTheme.cyanNeon,
            onChanged: (v) async {
              await storage.setBool('ad_blocking', v);
              setState(() => adBlocking = v);
            },
          ),
          _tile(
            Icons.shield_rounded,
            'Privacy protection',
            'Open privacy controls',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyScreen()),
              );
            },
          ),
          _tile(
            Icons.delete_sweep_rounded,
            'Clear browsing data',
            'History and saved data',
            () async {
              await storage.clearHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Browsing data cleared')),
                );
              }
            },
          ),
          _section('Security'),
          SwitchListTile(
            value: httpsOnly,
            title: const Text('HTTPS-Only Mode'),
            subtitle: const Text('Prefer secure connections'),
            activeColor: AppTheme.cyanNeon,
            onChanged: (v) async {
              await storage.setBool('https_only', v);
              setState(() => httpsOnly = v);
            },
          ),
          _tile(
            Icons.lock_outline_rounded,
            'Site permissions',
            'Camera, mic, location',
            controller == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PermissionsScreen(
                          manager: controller!.permissions,
                        ),
                      ),
                    );
                  },
          ),
          _section('Downloads'),
          _tile(
            Icons.download_rounded,
            'Download location',
            'App Downloads folder',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Using app Downloads folder')),
              );
            },
          ),
          _section('Advanced'),
          _tile(
            Icons.developer_mode_rounded,
            'Developer Tools',
            'Elements, Console, Network, Sources',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeveloperScreen(controller: controller),
                ),
              );
            },
          ),
          SwitchListTile(
            value: javascriptEnabled,
            title: const Text('JavaScript'),
            subtitle: const Text('Allow pages to run scripts'),
            activeColor: AppTheme.cyanNeon,
            onChanged: (v) async {
              await storage.setBool('javascript_enabled', v);
              setState(() => javascriptEnabled = v);
            },
          ),
          SwitchListTile(
            value: showImages,
            title: const Text('Show images'),
            subtitle: const Text('Load images on pages'),
            activeColor: AppTheme.cyanNeon,
            onChanged: (v) async {
              await storage.setBool('show_images', v);
              setState(() => showImages = v);
            },
          ),
          _section('About'),
          ListTile(
            leading:
                const Icon(Icons.info_outline_rounded, color: AppTheme.cyanNeon),
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
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: AppTheme.cyanNeon),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              if (controller != null) {
                Navigator.pop(context);
                controller!.open('https://mandalanet.id/privacy');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined,
                color: AppTheme.cyanNeon),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              if (controller != null) {
                Navigator.pop(context);
                controller!.open('https://mandalanet.id/terms');
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
