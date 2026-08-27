import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/browser_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

/// Developer tools inspired by Chromium / Mises mobile DevTools.
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
  final _networkNotes = <String>[];
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
      initialIndex: widget.initialTab.clamp(0, 5),
    );
    _tabs.addListener(() {
      if (_tabs.index == 0) _refreshElements();
      if (_tabs.index == 3) _refreshPageInfo();
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

  Future<void> _refreshElements() async {
    if (c == null || kIsWeb) {
      setState(() => _elementsHtml = '(WebView not available)');
      return;
    }
    setState(() => _loadingElements = true);
    try {
      final ctrl = c!.tabs.active.controller;
      if (ctrl == null) {
        setState(() {
          _elementsHtml = '(WebView controller not ready)';
          _loadingElements = false;
        });
        return;
      }
      final result = await ctrl.evaluateJavascript(
        source: '(function(){try{var html=document.documentElement.outerHTML||"";if(html.length>12000)html=html.substring(0,12000)+"\n...truncated";return html;}catch(e){return String(e);}})()',
      );
      setState(() {
        _elementsHtml = result?.toString() ?? '(empty)';
        _loadingElements = false;
      });
    } catch (e) {
      setState(() {
        _elementsHtml = 'Error: $e';
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
        final ctrlUa = tab.controller;
        if (ctrlUa != null) {
          try {
            final settings = await ctrlUa.getSettings();
            final ua = settings?.userAgent;
            if (ua != null && ua.isNotEmpty) buf.writeln('User-Agent: $ua');
          } catch (_) {}
        }
      } catch (_) {}
    }
    setState(() => _pageInfo = buf.toString());
  }

  Future<void> _runConsole() async {
    final code = _consoleInput.text.trim();
    if (code.isEmpty) return;
    _log('input', code);
    if (c == null || kIsWeb) {
      _log('error', 'JavaScript evaluation requires an active native WebView');
      return;
    }
    try {
      final ctrl = c!.tabs.active.controller;
      if (ctrl == null) {
        _log('error', 'WebView controller not ready');
        return;
      }
      final result = await ctrl.evaluateJavascript(source: code);
      _log('result', result?.toString() ?? 'undefined');
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
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              _refreshElements();
              _refreshPageInfo();
              _log('system', 'Refreshed');
            },
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: AppTheme.cyanNeon,
          labelColor: AppTheme.cyanNeon,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
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
              Text('document', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppTheme.cyanNeon)),
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
              _elementsHtml.isEmpty ? 'Tap Inspect to load DOM…' : _elementsHtml,
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
                  color = AppTheme.textMuted;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SelectableText(
                  '> ${line.message}',
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
              Text('›', style: GoogleFonts.jetBrainsMono(color: AppTheme.cyanNeon, fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _consoleInput,
                  style: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.white),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Run JavaScript…',
                    hintStyle: TextStyle(color: Color(0xFF6E7681)),
                  ),
                  onSubmitted: (_) => _runConsole(),
                ),
              ),
              IconButton(
                onPressed: _runConsole,
                icon: const Icon(Icons.play_arrow_rounded, color: AppTheme.cyanNeon),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _networkTab() {
    final url = c?.tabs.active.url ?? '—';
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _devCard(
          'Document',
          url,
          Icons.language_rounded,
        ),
        _devCard(
          'Note',
          'Full network waterfall requires platform WebView debugging. '
          'Request URL of the active document is shown above.',
          Icons.info_outline_rounded,
        ),
        for (final n in _networkNotes)
          _devCard('Log', n, Icons.http_rounded),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _networkNotes.add('Ping ${DateTime.now().toIso8601String()} · $url');
            });
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Record current URL'),
        ),
      ],
    );
  }

  Widget _sourcesTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _devCard('Page source', 'Use Elements tab for live DOM HTML', Icons.code_rounded),
        ListTile(
          tileColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: const Icon(Icons.copy_rounded, color: AppTheme.cyanNeon),
          title: const Text('Copy page HTML'),
          onTap: () async {
            await _refreshElements();
            await Clipboard.setData(ClipboardData(text: _elementsHtml));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('HTML copied')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _applicationTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _section('Storage'),
        _devCard('Local storage', 'Inspect via Console: localStorage', Icons.storage_rounded),
        _devCard('Session storage', 'Inspect via Console: sessionStorage', Icons.folder_open_rounded),
        _devCard('Cookies', 'Inspect via Console: document.cookie', Icons.cookie_rounded),
        const SizedBox(height: 8),
        _section('Actions'),
        ListTile(
          tileColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF7B72)),
          title: const Text('Clear site data (JS)'),
          onTap: () async {
            if (c == null || kIsWeb) return;
            try {
              final ctrl = c!.tabs.active.controller;
              if (ctrl == null) return;
              await ctrl.evaluateJavascript(
                source: 'try{localStorage.clear();sessionStorage.clear();}catch(e){}',
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
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _section('Page'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            _pageInfo.isEmpty ? 'Loading…' : _pageInfo,
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFFC9D1D9), height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        _section('App'),
        _devCard('Name', AppConfig.appName, Icons.apps_rounded),
        _devCard('Version', AppConfig.version, Icons.tag_rounded),
        _devCard('Platform', kIsWeb ? 'Web' : 'Android', Icons.phone_android_rounded),
        _devCard('Portal', AppConfig.webBaseUrl, Icons.public_rounded),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppTheme.cyanNeon,
        ),
      ),
    );
  }

  Widget _devCard(String title, String body, IconData icon) {
    return Card(
      color: const Color(0xFF161B22),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.cyanNeon, size: 22),
        title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(body, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppTheme.textMuted)),
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
