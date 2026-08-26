import 'package:flutter/material.dart';
import '../../security/permission_manager.dart';
import '../../models/permission_rule.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key, this.manager});

  /// Optional shared manager from BrowserController. If null, uses local instance.
  final PermissionManager? manager;

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  late final PermissionManager manager;

  @override
  void initState() {
    super.initState();
    manager = widget.manager ?? PermissionManager();
  }

  @override
  Widget build(BuildContext context) {
    const host = 'current-site';

    return Scaffold(
      appBar: AppBar(title: const Text('Permission Manager')),
      body: ListView(
        children: PermissionType.values.map((type) {
          return ListTile(
            leading: Icon(_icon(type)),
            title: Text(type.name),
            subtitle: Text(manager.state(host, type).name),
            trailing: PopupMenuButton<PermissionState>(
              onSelected: (value) {
                manager.set(host, type, value);
                setState(() {});
              },
              itemBuilder: (_) => PermissionState.values
                  .map((x) => PopupMenuItem(value: x, child: Text(x.name)))
                  .toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _icon(PermissionType type) => switch (type) {
        PermissionType.camera => Icons.camera_alt_rounded,
        PermissionType.microphone => Icons.mic_rounded,
        PermissionType.location => Icons.location_on_rounded,
        PermissionType.notifications => Icons.notifications_rounded,
        PermissionType.storage => Icons.folder_rounded,
        PermissionType.downloads => Icons.download_rounded,
        PermissionType.javascript => Icons.code_rounded,
      };
}
