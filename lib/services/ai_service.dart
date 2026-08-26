import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'storage_service.dart';

class AiService {
  AiService({StorageService? storage}) : _storage = storage ?? StorageService();
  final StorageService _storage;

  Future<String> chat(
    String message, {
    List<Map<String, String>> history = const [],
    String? token,
  }) async {
    if (!AppConfig.aiEnabled) {
      return 'MPorT AI is disabled.';
    }
    if (AppConfig.apiBaseUrl.isEmpty) {
      return 'MPorT AI is not configured. Set --dart-define=MPORT_API_URL=... '
          '(Laravel API base, e.g. https://portal.mandalanet.id/api).';
    }

    final auth = token ?? await _storage.getToken();
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');

    // Try common MPorT AI endpoints; fall back gracefully.
    final candidates = [
      '$base/v1/ai/chat',
      '$base/ai/chat',
      '$base/v1/chat',
    ];

    Exception? lastError;
    for (final url in candidates) {
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (auth != null && auth.isNotEmpty)
              'Authorization': 'Bearer $auth',
          },
          body: jsonEncode({
            'message': message,
            'history': history,
          }),
        );

        if (response.statusCode == 404) continue;
        if (response.body.isEmpty) {
          throw Exception('Empty AI response (${response.statusCode})');
        }

        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          throw Exception('Invalid JSON from AI');
        }

        final json = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{'message': decoded.toString()};

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
            '${json['message'] ?? 'AI request failed (${response.statusCode})'}',
          );
        }

        return '${json['data']?['answer'] ?? json['answer'] ?? json['message'] ?? 'No answer.'}';
      } catch (e) {
        lastError = e is Exception ? e : Exception('$e');
      }
    }

    throw lastError ??
        Exception(
          'AI endpoint not found on the MPorT backend. '
          'Ensure the /api/v1/ai/chat route is available.',
        );
  }
}
