import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'storage_service.dart';

/// MPorT AI client. Gemini credentials are server-side only.
class AiService {
  AiService({StorageService? storage}) : _storage = storage ?? StorageService();
  final StorageService _storage;

  Future<String?> resolveGeminiKey() async => null;

  Future<void> saveGeminiKey(String key) async {
    // Deliberately ignored: API keys must never be stored in the client.
  }

  Future<String> resolveModel() async {
    return await _storage.getString('ai_model') ?? AppConfig.geminiModel;
  }

  Future<void> saveModel(String model) async {
    await _storage.setString('ai_model', model.trim());
  }

  Future<String> chat(
    String message, {
    List<Map<String, String>> history = const [],
    String? token,
    String? pageContext,
  }) async {
    if (!AppConfig.aiEnabled) return 'MPorT AI is disabled.';
    if (AppConfig.apiBaseUrl.trim().isEmpty) {
      throw Exception('MPorT AI Gateway belum dikonfigurasi. Set MPORT_API_URL.');
    }

    final auth = token ?? await _storage.getToken();
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final endpoints = <String>['$base/${AppConfig.apiVersion}/ai/chat', '$base/ai/chat'];

    Exception? lastError;
    for (final endpoint in endpoints) {
      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-MPorT-Client': 'browser',
            if (auth != null && auth.isNotEmpty) 'Authorization': 'Bearer $auth',
          },
          body: jsonEncode({
            'message': message,
            'history': history,
            if (pageContext != null && pageContext.trim().isNotEmpty)
              'page_context': pageContext,
          }),
        ).timeout(const Duration(seconds: 35));

        if (response.statusCode == 404) continue;
        final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
        final map = body is Map<String, dynamic> ? body : <String, dynamic>{'data': body};
        if (response.statusCode < 200 || response.statusCode >= 300) {
          final code = response.statusCode;
          if (code == 429 || code >= 500) {
            await Future<void>.delayed(Duration(milliseconds: code == 429 ? 800 : 500));
            lastError = Exception('${map['message'] ?? 'AI temporarily unavailable'} ($code)');
            continue;
          }
          throw Exception('${map['message'] ?? map['error'] ?? 'AI request failed'} ($code)');
        }

        final answer = map['data'] is Map ? map['data']['answer'] : map['answer'];
        final value = '$answer'.trim();
        if (value.isEmpty || value == 'null') throw Exception('AI gateway returned an empty answer.');
        return value;
      } on TimeoutException catch (e) {
        lastError = e;
      } on FormatException catch (e) {
        lastError = Exception('Invalid JSON from AI gateway: $e');
      } catch (e) {
        lastError = e is Exception ? e : Exception('$e');
      }
    }
    throw lastError ?? Exception('AI Gateway endpoint tidak ditemukan.');
  }
}
