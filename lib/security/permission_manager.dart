import 'dart:convert';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/permission_rule.dart';

class PermissionManager {
  static const _key = 'mport_permission_rules';
  final List<PermissionRule> _rules = [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? [];
    _rules
      ..clear()
      ..addAll(raw.map((e) {
        final m = jsonDecode(e) as Map<String, dynamic>;
        return PermissionRule(
          host: '${m['host'] ?? ''}',
          type: PermissionType.values.firstWhere(
            (x) => x.name == m['type'],
            orElse: () => PermissionType.javascript,
          ),
          state: PermissionState.values.firstWhere(
            (x) => x.name == m['state'],
            orElse: () => PermissionState.ask,
          ),
        );
      }));
    _loaded = true;
  }

  PermissionState state(String host, PermissionType type) {
    for (final rule in _rules.reversed) {
      if (rule.host == host && rule.type == type) return rule.state;
    }
    return PermissionState.ask;
  }

  Future<void> set(String host, PermissionType type, PermissionState state) async {
    await load();
    _rules.removeWhere((x) => x.host == host && x.type == type);
    _rules.add(PermissionRule(host: host, type: type, state: state));
    await _save();
  }

  Future<void> clear() async {
    _rules.clear();
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }

  Future<bool> requestNative(PermissionType type) async {
    switch (type) {
      case PermissionType.camera:
        return (await ph.Permission.camera.request()).isGranted;
      case PermissionType.microphone:
        return (await ph.Permission.microphone.request()).isGranted;
      case PermissionType.location:
        return (await ph.Permission.locationWhenInUse.request()).isGranted;
      case PermissionType.notifications:
        return (await ph.Permission.notification.request()).isGranted;
      default:
        return true;
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, _rules.map((r) => jsonEncode({
      'host': r.host,
      'type': r.type.name,
      'state': r.state.name,
    })).toList());
  }
}
