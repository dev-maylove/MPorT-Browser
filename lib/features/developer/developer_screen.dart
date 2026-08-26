import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Developer'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tools'),
            Tab(text: 'Inspector'),
            Tab(text: 'Console'),
            Tab(text: 'Diagnostics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _pane('Developer Tools', 'Inspect layout, network, and performance in a future release.'),
          _pane('Web Inspector', 'DOM and style inspection will appear here.'),
          _console(),
          _diagnostics(),
        ],
      ),
    );
  }

  Widget _pane(String title, String body) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.code_rounded, size: 48, color: AppTheme.cyanNeon),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.orbitron(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _console() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Console', style: GoogleFonts.orbitron(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '> MPorT Browser console ready\n'
            '> Platform: ${kIsWeb ? "web" : "native"}\n'
            '> App: ${AppConfig.appName} ${AppConfig.version}',
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppTheme.greenStatus),
          ),
        ),
      ],
    );
  }

  Widget _diagnostics() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('App', AppConfig.appName),
        _card('Version', AppConfig.version),
        _card('Brand', AppConfig.brandName),
        _card('Platform', kIsWeb ? 'Web' : 'Native'),
        _card('AI', AppConfig.aiEnabled ? 'Enabled' : 'Disabled'),
        _card('Portal', AppConfig.webBaseUrl),
      ],
    );
  }

  Widget _card(String k, String v) {
    return Card(
      color: AppTheme.bgCard,
      child: ListTile(
        title: Text(k, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        subtitle: Text(v, style: GoogleFonts.jetBrainsMono(fontSize: 13)),
      ),
    );
  }
}
