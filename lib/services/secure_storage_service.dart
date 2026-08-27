import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sensitive credentials only. Android uses encrypted secure storage/Keystore-backed keys.
class SecureStorageService {
  const SecureStorageService();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);
}
