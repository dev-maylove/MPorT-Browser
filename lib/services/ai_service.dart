import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'storage_service.dart';

class AiService {
  AiService({StorageService? storage}) : _storage = storage ?? StorageService();
  final StorageService _storage;

  static const _geminiKeyStorage = 'gemini_api_key';
  static const _geminiModelStorage = 'gemini_model';

  Future<String?> resolveGeminiKey() async {
    final saved = await _storage.getString(_geminiKeyStorage);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    if (AppConfig.geminiApiKey.isNotEmpty) return AppConfig.geminiApiKey;
    return null;
  }

  Future<void> saveGeminiKey(String key) async {
    await _storage.setString(_geminiKeyStorage, key.trim());
  }

  Future<String> resolveModel() async {
    final saved = await _storage.getString(_geminiModelStorage);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    return AppConfig.geminiModel;
  }

  Future<void> saveModel(String model) async {
    await _storage.setString(_geminiModelStorage, model.trim());
  }

  /// Chat with Gemini (primary) or Laravel MPorT API (fallback).
  Future<String> chat(
    String message, {
    List<Map<String, String>> history = const [],
    String? token,
    String? pageContext,
  }) async {
    if (!AppConfig.aiEnabled) {
      return 'MPorT AI is disabled.';
    }

    final geminiKey = await resolveGeminiKey();
    if (geminiKey != null && geminiKey.isNotEmpty) {
      try {
        return await _chatGemini(
          message,
          history: history,
          apiKey: geminiKey,
          pageContext: pageContext,
        );
      } catch (e) {
        // Fall through to Laravel if configured
        if (AppConfig.apiBaseUrl.isEmpty) {
          rethrow;
        }
      }
    }

    if (AppConfig.apiBaseUrl.isNotEmpty) {
      return _chatLaravel(message, history: history, token: token);
    }

    return 'MPorT AI needs a Gemini API key.\n\n'
        '1. Get a key at https://aistudio.google.com/apikey\n'
        '2. Open MPorT AI → settings (key icon) and paste the key\n'
        '   or build with --dart-define=GEMINI_API_KEY=your_key';
  }

  Future<String> _chatGemini(
    String message, {
    required List<Map<String, String>> history,
    required String apiKey,
    String? pageContext,
  }) async {
    final model = await resolveModel();
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent?key=$apiKey',
    );

    final contents = <Map<String, dynamic>>[];
    for (final turn in history) {
      final role = (turn['role'] ?? 'user') == 'assistant' ? 'model' : 'user';
      final text = turn['content'] ?? turn['message'] ?? '';
      if (text.isEmpty) continue;
      contents.add({
        'role': role,
        'parts': [
          {'text': text},
        ],
      });
    }

    var userText = message;
    if (pageContext != null && pageContext.trim().isNotEmpty) {
      userText =
          'Page context:\n${pageContext.trim()}\n\nUser question:\n$message';
    }
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userText},
      ],
    });

    final body = {
      'systemInstruction': {
        'parts': [
          {
            'text':
                'You are MPorT AI, the intelligent assistant built into MPorT Browser '
                'for the MandalaNet ISP ecosystem. Be helpful, concise, and accurate. '
                'You can help with browsing, summarizing pages, translating, privacy tips, '
                'and general questions. Reply in the same language the user writes in '
                'unless they ask otherwise.',
          },
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
      },
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.body.isEmpty) {
      throw Exception('Empty response from Gemini (${response.statusCode})');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid JSON from Gemini');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected Gemini response');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final err = decoded['error'];
      final msg = err is Map
          ? (err['message'] ?? 'Gemini error ${response.statusCode}')
          : 'Gemini error ${response.statusCode}';
      throw Exception('$msg');
    }

    final candidates = decoded['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map) {
        final content = first['content'];
        if (content is Map) {
          final parts = content['parts'];
          if (parts is List && parts.isNotEmpty) {
            final texts = <String>[];
            for (final part in parts) {
              if (part is Map && part['text'] != null) {
                texts.add('${part['text']}');
              }
            }
            if (texts.isNotEmpty) return texts.join('\n').trim();
          }
        }
      }
    }

    final block = decoded['promptFeedback'];
    if (block is Map && block['blockReason'] != null) {
      throw Exception('Blocked by Gemini: ${block['blockReason']}');
    }

    throw Exception('No answer from Gemini');
  }

  Future<String> _chatLaravel(
    String message, {
    required List<Map<String, String>> history,
    String? token,
  }) async {
    final auth = token ?? await _storage.getToken();
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');

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
          'AI endpoint not found. Configure Gemini API key or MPorT Laravel API.',
        );
  }
}
