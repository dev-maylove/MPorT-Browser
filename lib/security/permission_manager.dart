import '../models/permission_rule.dart';

class PermissionManager {
  final List<PermissionRule> _rules = [];

  PermissionState state(String host, PermissionType type) {
    for (final rule in _rules.reversed) {
      if (rule.host == host && rule.type == type) {
        return rule.state;
      }
    }
    return PermissionState.ask;
  }

  void set(String host, PermissionType type, PermissionState state) {
    _rules.removeWhere((x) => x.host == host && x.type == type);
    _rules.add(PermissionRule(host: host, type: type, state: state));
  }

  void clear() => _rules.clear();
}
