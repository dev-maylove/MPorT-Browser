import 'package:flutter/material.dart';
import '../../controllers/browser_controller.dart';
import '../browser/browser_screen.dart';
import '../home/new_tab_screen.dart';

class TabsScreen extends StatelessWidget {
  const TabsScreen({super.key, required this.controller});
  final BrowserController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          title: Text('${controller.tabs.tabs.length} Tab'),
          actions: [
            IconButton(
              tooltip: 'Private tab',
              onPressed: () async {
                controller.newPrivateTab();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => NewTabScreen(controller: controller),
                    ),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.visibility_off_rounded),
            ),
            IconButton(
              tooltip: 'New tab',
              onPressed: () async {
                await controller.newTab();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => NewTabScreen(controller: controller),
                    ),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.tabs.tabs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .78,
          ),
          itemBuilder: (_, index) {
            if (index >= controller.tabs.tabs.length) {
              return const SizedBox.shrink();
            }
            final tab = controller.tabs.tabs[index];
            final isActive = index == controller.tabs.activeIndex;
            return Card(
              clipBehavior: Clip.antiAlias,
              color: isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: InkWell(
                onTap: () {
                  controller.selectTab(index);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          BrowserScreen(controller: controller),
                    ),
                    (route) => false,
                  );
                },
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                tab.url,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            tab.private
                                ? 'Private Tab'
                                : (tab.groupName != null
                                    ? '[${tab.groupName}] ${tab.title.isEmpty ? 'New Tab' : tab.title}'
                                    : (tab.title.isEmpty ? 'New Tab' : tab.title)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        onPressed: () {
                          // Defer so GridView is not rebuilt mid-build.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            controller.closeTab(index);
                          });
                        },
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ),
                    if (tab.private)
                      const Positioned(
                        left: 8,
                        top: 8,
                        child: Icon(Icons.visibility_off, size: 16),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
