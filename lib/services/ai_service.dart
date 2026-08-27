import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'storage_service.dart';

class AiService {
  AiService({StorageService? storage}) : _storage = storage ?? StorageService();
  final StorageService _storage;

  static const _geminiKeyStorage = 'gemini_api_key';
  static const _geminiModelStorage = 'gemini_model';

  /// Free-tier Gemini models to try when primary is overloaded.
  static const _fallbackModels = [
    'gemini-3.7-flash',
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-3.5-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];

  static const _systemPrompt =
      'You are MPorT AI, the intelligent assistant built into MPorT Browser '
      'for the MandalaNet ISP ecosystem. Be helpful, concise, and accurate. '
      'You can help with browsing, summarizing pages, translating, privacy tips, '
      'and general questions. Reply in the same language the user writes in '
      'unless they ask otherwise.';

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

  /// Chat with Gemini (primary, free tier) or Laravel MPorT API (fallback).
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
        return await _chatGeminiWithRetry(
          message,
          history: history,
          apiKey: geminiKey,
          pageContext: pageContext,
        );
      } catch (e) {
        if (AppConfig.apiBaseUrl.isEmpty) {
          rethrow;
        }
      }
    }

    if (AppConfig.apiBaseUrl.isNotEmpty) {
      return _chatLaravel(message, history: history, token: token);
    }

    return 'MPorT AI needs a Gemini API key (free tier).\n\n'
        '1. Get a key at https://aistudio.google.com/apikey\n'
        '2. Open MPorT AI → settings (key icon) and paste the key\n'
        '   or build with --dart-define=GEMINI_API_KEY=your_key';
  }

  /// Retry + model fallback for high demand / rate limit / transient errors.
  Future<String> _chatGeminiWithRetry(
    String message, {
    required List<Map<String, String>> history,
    required String apiKey,
    String? pageContext,
  }) async {
    final preferred = await resolveModel();
    final models = <String>[
      preferred,
      ..._fallbackModels.where((m) => m != preferred),
    ];

    Exception? lastError;

    for (var modelIndex = 0; modelIndex < models.length; modelIndex++) {
      final model = models[modelIndex];
      // More retries on preferred model; fewer on fallbacks.
      final maxAttempts = modelIndex == 0 ? 3 : 2;

      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          return await _chatGeminiOnce(
            message,
            history: history,
            apiKey: apiKey,
            model: model,
            pageContext: pageContext,
          );
        } catch (e) {
          lastError = e is Exception ? e : Exception('$e');
          final msg = '$e'.toLowerCase();

          final isOverload = msg.contains('high demand') ||
              msg.contains('overloaded') ||
              msg.contains('resource_exhausted') ||
              msg.contains('unavailable') ||
              msg.contains('try again later') ||
              msg.contains('503') ||
              msg.contains('429') ||
              msg.contains('rate limit') ||
              msg.contains('quota');

          final isNotFound = msg.contains('not found') ||
              msg.contains('no longer available') ||
              msg.contains('is not supported') ||
              msg.contains('404');

          // Model gone → skip to next model immediately.
          if (isNotFound) break;

          // Overload / rate limit → wait then retry, or try next model.
          if (isOverload && attempt < maxAttempts) {
            final delayMs = 800 * attempt * attempt; // 800, 3200, …
            await Future<void>.delayed(Duration(milliseconds: delayMs));
            continue;
          }

          // Overload exhausted on this model → try next model.
          if (isOverload) break;

          // Other errors (auth, blocked, etc.) → don't spin on other models.
          rethrow;
        }
      }
    }

    final hint = lastError != null ? '$lastError' : 'unknown error';
    if (hint.toLowerCase().contains('high demand') ||
        hint.toLowerCase().contains('overloaded') ||
        hint.toLowerCase().contains('try again later')) {
      throw Exception(
        'Gemini sedang sibuk (high demand). '
        'Sudah dicoba ulang & ganti model otomatis. '
        'Coba lagi beberapa detik kemudian.\n\nDetail: $hint',
      );
    }
    throw lastError ?? Exception('No answer from Gemini');
  }

  Future<String> _chatGeminiOnce(
    String message, {
    required List<Map<String, String>> history,
    required String apiKey,
    required String model,
    String? pageContext,
  }) async {
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
          {'text': _systemPrompt},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
      },
    };

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 45));

    if (response.body.isEmpty) {
      throw Exception('Empty response from Gemini (${response.statusCode})');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid JSON from Gemini (${response.statusCode})');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected Gemini response');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final err = decoded['error'];
      final msg = err is Map
          ? (err['message'] ?? 'Gemini error ${response.statusCode}')
          : 'Gemini error ${response.statusCode}';
      // Preserve status code in message so retry logic can detect 429/503.
      throw Exception('$msg [${response.statusCode}]');
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
