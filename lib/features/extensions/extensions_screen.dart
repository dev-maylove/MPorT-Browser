import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class ExtensionsScreen extends StatelessWidget {
  const ExtensionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('Extensions')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.extension_rounded, size: 56, color: AppTheme.cyanNeon),
              const SizedBox(height: 16),
              Text('Extensions', style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Extension support is planned for a future MPorT Browser release.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
