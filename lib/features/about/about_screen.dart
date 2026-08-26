import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('About MPorT Browser')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.gradientAi,
                boxShadow: const [
                  BoxShadow(color: AppTheme.cyanGlow, blurRadius: 24, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.public_rounded, size: 44, color: AppTheme.bgDeep),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              AppConfig.appName,
              style: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Version ${AppConfig.version}',
              style: GoogleFonts.jetBrainsMono(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              AppConfig.brandName,
              style: GoogleFonts.inter(color: AppTheme.cyanNeon),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Cross-platform browser for the MandalaNet / MPorT ISP ecosystem. '
            'Privacy-focused browsing with multi-tab, search engines, and MPorT AI.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(height: 1.45, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.policy_outlined, color: AppTheme.cyanNeon),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: AppTheme.cyanNeon),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.balance_rounded, color: AppTheme.cyanNeon),
            title: const Text('Open Source Licenses'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: AppConfig.appName,
                applicationVersion: AppConfig.version,
              );
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© MandalaNet · PT. Network Bumi Saridin',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
