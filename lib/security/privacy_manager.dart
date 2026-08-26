import '../services/storage_service.dart';

class PrivacyManager {
  PrivacyManager(this.storage);

  final StorageService storage;

  Future<void> clearBrowsingData() async {
    await storage.clearHistory();
  }

  Future<void> setPrivateMode(bool enabled) async {
    await storage.setBool('private_mode', enabled);
  }

  Future<bool> privateMode() {
    return storage.getBool('private_mode');
  }
}
