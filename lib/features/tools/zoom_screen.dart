import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/browser_controller.dart';
import '../../core/theme/app_theme.dart';

class ZoomScreen extends StatefulWidget {
  const ZoomScreen({super.key, required this.controller});

  final BrowserController controller;

  @override
  State<ZoomScreen> createState() => _ZoomScreenState();
}

class _ZoomScreenState extends State<ZoomScreen> {
  double _zoom = 1.0;

  Future<void> _apply(double z) async {
    setState(() => _zoom = z);
    if (kIsWeb) return;
    try {
      final pct = (z * 100).round();
      await widget.controller.tabs.active.controller.runJavaScript(
        'document.body.style.zoom = "$pct%";',
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('Zoom')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '${(_zoom * 100).round()}%',
              style: GoogleFonts.orbitron(fontSize: 36, color: AppTheme.cyanNeon),
            ),
            Slider(
              value: _zoom,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: '${(_zoom * 100).round()}%',
              onChanged: (v) => _apply(v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final z in [0.75, 1.0, 1.25, 1.5, 2.0])
                  ActionChip(
                    label: Text('${(z * 100).round()}%'),
                    onPressed: () => _apply(z),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
