import 'package:flutter/material.dart';
import '../../security/privacy_manager.dart';
import '../../services/storage_service.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late final PrivacyManager privacy;
  bool privateMode = false;

  @override
  void initState() {
    super.initState();
    privacy = PrivacyManager(StorageService());
    _load();
  }

  Future<void> _load() async {
    privateMode = await privacy.privateMode();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        children: [
          SwitchListTile(
            value: privateMode,
            title: const Text('Private mode'),
            subtitle: const Text('Do not save browsing history.'),
            onChanged: (value) async {
              await privacy.setPrivateMode(value);
              setState(() => privateMode = value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_rounded),
            title: const Text('Clear browsing data'),
            onTap: () async {
              await privacy.clearBrowsingData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Browsing data cleared.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
