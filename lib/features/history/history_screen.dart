import 'package:flutter/material.dart';
import '../../controllers/browser_controller.dart';
import '../../models/history_entry.dart';
import '../browser/browser_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.controller});
  final BrowserController controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String search = '';
  int _reload = 0;

  Future<List<HistoryEntry>> _load() => widget.controller.storage.history();

  Future<void> _openHistory(String url) async {
    await widget.controller.load(url);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => BrowserScreen(controller: widget.controller),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Clear history',
            onPressed: () async {
              await widget.controller.storage.clearHistory();
              if (mounted) setState(() => _reload++);
            },
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<HistoryEntry>>(
        key: ValueKey(_reload),
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }
          final all = snapshot.data ?? <HistoryEntry>[];
          final items = all.where((x) {
            final q = search.toLowerCase();
            return x.title.toLowerCase().contains(q) ||
                x.url.toLowerCase().contains(q);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (v) => setState(() => search = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search history...',
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No history yet.'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => ListTile(
                          leading: const Icon(Icons.history_rounded),
                          title: Text(
                            items[i].title.isEmpty
                                ? items[i].url
                                : items[i].title,
                          ),
                          subtitle: Text(items[i].url),
                          onTap: () => _openHistory(items[i].url),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
