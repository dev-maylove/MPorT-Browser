import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'storage_service.dart';

/// Client for MPorT Laravel API (v1 / v2 Sanctum).
class MportApiService {
  MportApiService({StorageService? storage})
      : _storage = storage ?? StorageService();

  final StorageService _storage;

  String get base {
    final b = AppConfig.apiBaseUrl.trim();
    if (b.isEmpty) return '';
    return b.endsWith('/') ? b.substring(0, b.length - 1) : b;
  }

  String get _v1 => '$base/${AppConfig.apiVersion}';

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        h['Authorization'] = 'Bearer $token';
      }
    }
    return h;
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    if (response.body.isEmpty) {
      throw Exception('Empty response (HTTP ${response.statusCode})');
    }
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid JSON (HTTP ${response.statusCode})');
    }
    final map = body is Map<String, dynamic>
        ? body
        : <String, dynamic>{'data': body};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = map['message'] ??
          map['error'] ??
          'API error ${response.statusCode}';
      throw Exception('$msg');
    }
    return map;
  }

  /// POST /api/v1/auth/login
  /// Body: login | email, password, device_name
  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
    String deviceName = 'mport-browser',
  }) async {
    if (base.isEmpty) {
      throw Exception('MPORT_API_URL is not configured.');
    }
    final response = await http.post(
      Uri.parse('$_v1/auth/login'),
      headers: await _headers(),
      body: jsonEncode({
        'login': login,
        'email': login,
        'password': password,
        'device_name': deviceName,
      }),
    );
    final json = await _decode(response);
    final token = '${json['token'] ?? json['data']?['token'] ?? ''}';
    if (token.isNotEmpty) {
      await _storage.setToken(token);
    }
    return json;
  }

  Future<void> logout() async {
    if (base.isEmpty) {
      await _storage.clearToken();
      return;
    }
    try {
      await http.post(
        Uri.parse('$_v1/auth/logout'),
        headers: await _headers(auth: true),
      );
    } catch (_) {}
    await _storage.clearToken();
  }

  Future<Map<String, dynamic>> me() async {
    final response = await http.get(
      Uri.parse('$_v1/auth/me'),
      headers: await _headers(auth: true),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> dashboard() async {
    final response = await http.get(
      Uri.parse('$_v1/dashboard'),
      headers: await _headers(auth: true),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> packages() async {
    final response = await http.get(
      Uri.parse('$_v1/packages'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> forgotPassword(String login) async {
    final response = await http.post(
      Uri.parse('$_v1/auth/forgot-password'),
      headers: await _headers(),
      body: jsonEncode({'login': login, 'email': login}),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    if (base.isEmpty) {
      throw Exception('MPORT_API_URL is not configured.');
    }
    final p = path.startsWith('/') ? path : '/$path';
    final response = await http.get(
      Uri.parse('$base$p'),
      headers: await _headers(auth: auth),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    if (base.isEmpty) {
      throw Exception('MPORT_API_URL is not configured.');
    }
    final p = path.startsWith('/') ? path : '/$path';
    final response = await http.post(
      Uri.parse('$base$p'),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }
}
