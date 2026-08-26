import 'package:flutter/material.dart';
import '../../controllers/browser_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/browser_toolbar.dart';
import '../../widgets/browser_menu.dart';
import '../../widgets/browser_view.dart';
import '../tabs/tabs_screen.dart';
import '../home/new_tab_screen.dart';

/// Main browsing UI: address bar + WebView for the active tab.
class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key, required this.controller});

  final BrowserController controller;

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final TextEditingController _address;
  bool _editingAddress = false;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(text: widget.controller.tabs.active.url);
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (!_editingAddress) {
      final url = widget.controller.tabs.active.url;
      if (_address.text != url) {
        _address.text = url;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _address.dispose();
    super.dispose();
  }

  void _showMenu() {
    BrowserMenu.show(context, widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) {
        final tab = widget.controller.tabs.active;
        return Scaffold(
          backgroundColor: AppTheme.bgDeep,
          body: Column(
            children: [
              BrowserToolbar(
                controller: _address,
                onEditingChanged: (editing) => _editingAddress = editing,
                onSubmitted: (value) async {
                  _editingAddress = false;
                  await widget.controller.load(value);
                },
                onBack: () async {
                  final wentBack = await widget.controller.back();
                  if (!wentBack && context.mounted) {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              NewTabScreen(controller: widget.controller),
                        ),
                      );
                    }
                  }
                },
                onForward: () => widget.controller.forward(),
                onRefresh: () => widget.controller.refresh(),
                onTabs: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TabsScreen(controller: widget.controller),
                    ),
                  );
                },
                onMenu: _showMenu,
              ),
              if (tab.private)
                Container(
                  width: double.infinity,
                  color: AppTheme.purpleAccent.withValues(alpha: 0.22),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Text(
                    'Private Tab — history is not saved',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              Expanded(child: BrowserView(tab: tab)),
            ],
          ),
        );
      },
    );
  }
}
