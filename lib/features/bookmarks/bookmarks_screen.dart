import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/browser_controller.dart';
import '../../models/bookmark.dart';
import '../browser/browser_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key, required this.controller});
  final BrowserController controller;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  String search = '';
  int _reload = 0;

  Future<List<Bookmark>> _load() => widget.controller.storage.bookmarks();

  Future<void> _openBookmark(String url) async {
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
      appBar: AppBar(title: const Text('Bookmarks')),
      body: FutureBuilder<List<Bookmark>>(
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
          final all = snapshot.data ?? <Bookmark>[];
          final items = all.where((x) {
            final q = search.toLowerCase();
            return x.title.toLowerCase().contains(q) ||
                x.url.toLowerCase().contains(q) ||
                x.folder.toLowerCase().contains(q);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (v) => setState(() => search = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search bookmarks or folders...',
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No bookmarks yet.'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) => ListTile(
                          leading: const Icon(Icons.bookmark_rounded),
                          title: Text(items[i].title),
                          subtitle:
                              Text('${items[i].folder} • ${items[i].url}'),
                          onTap: () => _openBookmark(items[i].url),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await widget.controller.storage
                                  .deleteBookmark(items[i].id);
                              if (mounted) setState(() => _reload++);
                            },
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final tab = widget.controller.tabs.active;
          final url = tab.url.trim();
          if (url.isEmpty || url == 'about:blank') {
            messenger.showSnackBar(
              const SnackBar(content: Text('No page to bookmark.')),
            );
            return;
          }
          await widget.controller.storage.saveBookmark(
            Bookmark(
              id: const Uuid().v4(),
              title: tab.title.isEmpty ? tab.url : tab.title,
              url: tab.url,
              folder: 'General',
            ),
          );
          if (!mounted) return;
          setState(() => _reload++);
          messenger.showSnackBar(
            const SnackBar(content: Text('Bookmark saved.')),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
