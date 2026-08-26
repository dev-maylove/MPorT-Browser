enum PermissionType {
  camera,
  microphone,
  location,
  notifications,
  storage,
  downloads,
  javascript,
}

enum PermissionState {
  ask,
  allow,
  deny,
}

class PermissionRule {
  const PermissionRule({
    required this.host,
    required this.type,
    required this.state,
  });

  final String host;
  final PermissionType type;
  final PermissionState state;
}
