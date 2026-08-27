import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/browser_controller.dart';

const kChromeWebStoreExtensions =
    'https://chromewebstore.google.com/category/extensions';

class ExtensionsScreen extends StatelessWidget {
  const ExtensionsScreen({super.key, this.controller});

  final BrowserController? controller;

  Future<void> _openStore(BuildContext context) async {
    final uri = Uri.parse(kChromeWebStoreExtensions);
    // Prefer in-app browser if controller available
    if (controller != null) {
      Navigator.of(context).pop();
      await controller!.open(kChromeWebStoreExtensions);
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Chrome Web Store')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('Extensions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cyanNeon.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                const Icon(Icons.extension_rounded, size: 48, color: AppTheme.cyanNeon),
                const SizedBox(height: 12),
                Text(
                  'Chrome Web Store',
                  style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse and discover extensions from the official Chrome Web Store.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openStore(context),
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('Open Extensions Store'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.cyanNeon,
                    foregroundColor: AppTheme.bgDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: AppTheme.bgCard,
            leading: const Icon(Icons.storefront_rounded, color: AppTheme.cyanNeon),
            title: const Text('Chrome Web Store'),
            subtitle: Text(
              kChromeWebStoreExtensions,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openStore(context),
          ),
        ],
      ),
    );
  }
}
