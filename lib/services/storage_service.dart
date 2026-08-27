import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';
import '../models/history_entry.dart';
import 'secure_storage_service.dart';

class StorageService {
  static const _bookmarks = 'mport_bookmarks';
  static const _history = 'mport_history';
  static const _settings = 'mport_settings';
  static const _session = 'mport_session_tabs';
  static const _sessionActive = 'mport_session_active';
  static const _legacyToken = 'mport_auth_token';
  static const _secureToken = 'mport_auth_token_v2';
  static const _legacyGeminiKey = 'gemini_api_key';
  static const SecureStorageService _secure = SecureStorageService();

  Future<void> migrateSensitiveData() async {
    final p = await SharedPreferences.getInstance();
    final legacyToken = p.getString(_legacyToken);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _secure.write(_secureToken, legacyToken);
    }
    await p.remove(_legacyToken);
    // A client-side Gemini key is never valid for the production architecture.
    await p.remove('$_settings.$_legacyGeminiKey');
    await p.remove(_legacyGeminiKey);
  }

  Future<List<Bookmark>> bookmarks() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_bookmarks) ?? [])
        .map((e) => Bookmark.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveBookmark(Bookmark item) async {
    final p = await SharedPreferences.getInstance();
    final list = await bookmarks();
    list.removeWhere((x) => x.url == item.url);
    list.add(item);
    await p.setStringList(_bookmarks, list.map((x) => jsonEncode(x.toJson())).toList());
  }

  Future<void> deleteBookmark(String id) async {
    final p = await SharedPreferences.getInstance();
    final list = await bookmarks();
    list.removeWhere((x) => x.id == id);
    await p.setStringList(_bookmarks, list.map((x) => jsonEncode(x.toJson())).toList());
  }

  Future<List<HistoryEntry>> history() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_history) ?? [])
        .map((e) => HistoryEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> addHistory(HistoryEntry item) async {
    if (item.private) return;
    final p = await SharedPreferences.getInstance();
    final list = await history();
    list.removeWhere((x) => x.url == item.url);
    list.insert(0, item);
    await p.setStringList(_history, list.take(500).map((x) => jsonEncode(x.toJson())).toList());
  }

  Future<void> clearHistory() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_history);
  }

  Future<void> saveSession(List<Map<String, dynamic>> tabs, int activeIndex) async {
    final p = await SharedPreferences.getInstance();
    final safe = tabs.where((t) => t['private'] != true).toList();
    await p.setStringList(_session, safe.map(jsonEncode).toList());
    await p.setInt(_sessionActive, activeIndex.clamp(0, safe.isEmpty ? 0 : safe.length - 1));
  }

  Future<List<Map<String, dynamic>>> sessionTabs() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_session) ?? []).map((e) {
      final value = jsonDecode(e);
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    }).where((e) => e['url'] is String && (e['url'] as String).isNotEmpty).toList();
  }

  Future<int> sessionActiveIndex() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_sessionActive) ?? 0;
  }

  Future<void> clearSession() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_session);
    await p.remove(_sessionActive);
  }

  Future<void> setBool(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('$_settings.$key', value);
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('$_settings.$key') ?? defaultValue;
  }

  Future<void> setString(String key, String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('$_settings.$key', value);
  }

  Future<String?> getString(String key) async {
    final p = await SharedPreferences.getInstance();
    return p.getString('$_settings.$key');
  }

  Future<void> setToken(String token) async {
    await _secure.write(_secureToken, token);
  }

  Future<String?> getToken() async => _secure.read(_secureToken);

  Future<void> clearToken() async => _secure.delete(_secureToken);
}
