import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/browser_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

/// Developer tools inspired by Chromium mobile DevTools.
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({
    super.key,
    this.controller,
    this.initialTab = 0,
  });

  final BrowserController? controller;
  final int initialTab;

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _consoleLog = <_LogLine>[];
  final _consoleInput = TextEditingController();
  String _elementsHtml = '';
  String _pageInfo = '';
  bool _loadingElements = false;

  BrowserController? get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 5).toInt(),
    );
    _tabs.addListener(() {
      if (_tabs.index == 0) _refreshElements();
      if (_tabs.index == 5) _refreshPageInfo();
    });
    _log('system', 'DevTools ready — MPorT Browser ${AppConfig.version}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshElements();
      _refreshPageInfo();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _consoleInput.dispose();
    super.dispose();
  }

  void _log(String level, String msg) {
    setState(() {
      _consoleLog.add(_LogLine(level: level, message: msg, at: DateTime.now()));
      if (_consoleLog.length > 200) _consoleLog.removeAt(0);
    });
  }

  String _decodeJsResult(dynamic result) {
    if (result == null) return '';
    if (result is String) {
      final s = result.trim();
      if ((s.startsWith('"') && s.endsWith('"')) ||
          (s.startsWith("'") && s.endsWith("'"))) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is String) return decoded;
        } catch (_) {
          if (s.length >= 2) return s.substring(1, s.length - 1);
        }
      }
      return s;
    }
    return result.toString();
  }

  Future<void> _refreshElements() async {
    if (c == null) {
      setState(() => _elementsHtml =
          'Tidak ada BrowserController.\nBuka halaman web dulu, lalu buka Developer Tools dari menu.');
      return;
    }
    if (kIsWeb) {
      setState(() => _elementsHtml = '(Inspect tidak tersedia di build web)');
      return;
    }
    final tab = c!.tabs.active;
    final url = tab.url;
    if (url.isEmpty || url == 'about:blank') {
      setState(() => _elementsHtml =
          'Belum ada halaman dimuat (about:blank).\n'
          'Buka situs di tab browser, lalu tekan Inspect lagi.');
      return;
    }
    setState(() => _loadingElements = true);
    try {
      final result = await tab.controller.runJavaScriptReturningResult(
        '(function(){try{'
        'var html=document.documentElement'
        '? (document.documentElement.outerHTML||"")'
        ': (document.body?document.body.outerHTML:"");'
        'if(!html)return "(empty document)";'
        'if(html.length>16000)html=html.substring(0,16000)+"\\n... truncated ...";'
        'return html;'
        '}catch(e){return "JS Error: "+e;}})()',
      );
      final html = _decodeJsResult(result);
      setState(() {
        _elementsHtml = html.isEmpty ? '(empty result from WebView)' : html;
        _loadingElements = false;
      });
    } catch (e) {
      setState(() {
        _elementsHtml =
            'Inspect gagal: $e\n\n'
            'Tips:\n'
            '• Pastikan halaman sudah selesai loading\n'
            '• Buka Developer Tools dari menu saat tab web aktif\n'
            '• Beberapa halaman (chrome://, about:) tidak bisa di-inspect';
        _loadingElements = false;
      });
    }
  }

  Future<void> _refreshPageInfo() async {
    if (c == null) {
      setState(() => _pageInfo = 'No active controller');
      return;
    }
    final tab = c!.tabs.active;
    final buf = StringBuffer()
      ..writeln('URL: ${tab.url}')
      ..writeln('Title: ${tab.title}')
      ..writeln('Private: ${tab.private}')
      ..writeln('Loading: ${tab.loading}')
      ..writeln('Desktop mode: ${c!.desktopSite}')
      ..writeln('Can go back: ${tab.canBack}')
      ..writeln('Can go forward: ${tab.canForward}');
    if (!kIsWeb) {
      try {
        final ua = await tab.controller.getUserAgent();
        buf.writeln('User-Agent: $ua');
      } catch (_) {}
    }
    setState(() => _pageInfo = buf.toString());
  }

  Future<void> _runConsole() async {
    final code = _consoleInput.text.trim();
    if (code.isEmpty) return;
    _log('input', code);
    final browserController = c;
    if (browserController == null || kIsWeb) {
      _log('error', 'JavaScript evaluation requires an active native WebView');
      return;
    }
    try {
      final result = await browserController.tabs.active.controller
          .runJavaScriptReturningResult(code);
      _log('result', result.toString());
    } catch (e) {
      _log('error', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Text(
          'Developer Tools',
          style: GoogleFonts.jetBrainsMono(fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: AppTheme.cyanNeon,
          labelColor: AppTheme.cyanNeon,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Elements'),
            Tab(text: 'Console'),
            Tab(text: 'Network'),
            Tab(text: 'Sources'),
            Tab(text: 'Application'),
            Tab(text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _elementsTab(),
          _consoleTab(),
          _networkTab(),
          _sourcesTab(),
          _applicationTab(),
          _infoTab(),
        ],
      ),
    );
  }

  Widget _elementsTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF161B22),
          child: Row(
            children: [
              Text(
                'document',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AppTheme.cyanNeon,
                ),
              ),
              const Spacer(),
              if (_loadingElements)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              TextButton(
                onPressed: _refreshElements,
                child: const Text('Inspect', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              _elementsHtml.isEmpty
                  ? 'Tap Inspect to load DOM…'
                  : _elementsHtml,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: const Color(0xFFC9D1D9),
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _consoleTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _consoleLog.length,
            itemBuilder: (_, i) {
              final line = _consoleLog[i];
              Color color;
              switch (line.level) {
                case 'error':
                  color = const Color(0xFFFF7B72);
                  break;
                case 'input':
                  color = AppTheme.cyanNeon;
                  break;
                case 'result':
                  color = const Color(0xFF7EE787);
                  break;
                default:
                  color = const Color(0xFF8B949E);
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SelectableText(
                  '[${line.level}] ${line.message}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 12, color: color),
                ),
              );
            },
          ),
        ),
        Container(
          color: const Color(0xFF161B22),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _consoleInput,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'js >',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _runConsole(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _runConsole,
                icon: const Icon(Icons.play_arrow_rounded,
                    color: AppTheme.cyanNeon),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _networkTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Network inspection is limited in System WebView.\n'
          'Use browser Network panel or proxy tools for full traces.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 12),
        Text(
          'Active URL: ${c?.tabs.active.url ?? '-'}',
          style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppTheme.cyanNeon),
        ),
      ],
    );
  }

  Widget _sourcesTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Sources panel: view page HTML via Elements tab.\n'
          'Script breakpoints are not supported in embedded WebView.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _applicationTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ListTile(
          tileColor: const Color(0xFF161B22),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: const Icon(Icons.delete_outline_rounded,
              color: Color(0xFFFF7B72)),
          title: const Text('Clear site data (JS)'),
          onTap: () async {
            if (c == null || kIsWeb) return;
            try {
              await c!.tabs.active.controller.runJavaScript(
                'try{localStorage.clear();sessionStorage.clear();}catch(e){}',
              );
              _log('system', 'Cleared localStorage + sessionStorage');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Site storage cleared')),
                );
              }
            } catch (e) {
              _log('error', e.toString());
            }
          },
        ),
      ],
    );
  }

  Widget _infoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _pageInfo.isEmpty ? 'Loading…' : _pageInfo,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          color: const Color(0xFFC9D1D9),
          height: 1.4,
        ),
      ),
    );
  }
}

class _LogLine {
  _LogLine({required this.level, required this.message, required this.at});
  final String level;
  final String message;
  final DateTime at;
}
