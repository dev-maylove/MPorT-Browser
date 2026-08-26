import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';
import '../models/history_entry.dart';

class StorageService {
  static const _bookmarks = 'mport_bookmarks';
  static const _history = 'mport_history';
  static const _settings = 'mport_settings';
  static const _token = 'mport_auth_token';

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
    await p.setStringList(
      _bookmarks,
      list.map((x) => jsonEncode(x.toJson())).toList(),
    );
  }

  Future<void> deleteBookmark(String id) async {
    final p = await SharedPreferences.getInstance();
    final list = await bookmarks();
    list.removeWhere((x) => x.id == id);
    await p.setStringList(
      _bookmarks,
      list.map((x) => jsonEncode(x.toJson())).toList(),
    );
  }

  Future<List<HistoryEntry>> history() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_history) ?? [])
        .map((e) =>
            HistoryEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> addHistory(HistoryEntry item) async {
    if (item.private) return;
    final p = await SharedPreferences.getInstance();
    final list = await history();
    list.removeWhere((x) => x.url == item.url);
    list.insert(0, item);
    await p.setStringList(
      _history,
      list.take(500).map((x) => jsonEncode(x.toJson())).toList(),
    );
  }

  Future<void> clearHistory() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_history);
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
    final p = await SharedPreferences.getInstance();
    await p.setString(_token, token);
  }

  Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_token);
  }

  Future<void> clearToken() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_token);
  }
}
