import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'storage_service.dart';

class AiService {
  AiService({StorageService? storage}) : _storage = storage ?? StorageService();
  final StorageService _storage;

  static const _geminiKeyStorage = 'gemini_api_key';
  static const _geminiModelStorage = 'gemini_model';

  /// Free-tier Flash models (order = prefer faster/cheaper first after preferred).
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
    final k = key.trim();
    await _storage.setString(_geminiKeyStorage, k);
  }

  Future<String> resolveModel() async {
    final saved = await _storage.getString(_geminiModelStorage);
    if (saved != null && saved.trim().isNotEmpty) {
      final m = saved.trim();
      const shutdown = {
        'gemini-2.0-flash',
        'gemini-2.0-flash-lite',
        'gemini-1.5-flash',
        'gemini-1.5-pro',
        'gemini-pro',
      };
      if (shutdown.contains(m)) {
        await _storage.setString(_geminiModelStorage, AppConfig.geminiModel);
        return AppConfig.geminiModel;
      }
      return m;
    }
    return AppConfig.geminiModel;
  }

  Future<void> saveModel(String model) async {
    await _storage.setString(_geminiModelStorage, model.trim());
  }

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
        if (AppConfig.apiBaseUrl.isEmpty) rethrow;
      }
    }

    if (AppConfig.apiBaseUrl.isNotEmpty) {
      return _chatLaravel(message, history: history, token: token);
    }

    return 'MPorT AI butuh Gemini API key (gratis).\n\n'
        '1. Buka https://aistudio.google.com/apikey\n'
        '2. Buat key → salin\n'
        '3. Di MPorT AI tekan ikon pengaturan (pojok kanan) → tempel key → Simpan\n\n'
        'Atau build dengan --dart-define=GEMINI_API_KEY=your_key';
  }

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

          if (isNotFound) break;

          if (isOverload && attempt < maxAttempts) {
            await Future<void>.delayed(
              Duration(milliseconds: 700 * attempt * attempt),
            );
            continue;
          }
          if (isOverload) break;

          // Auth errors → stop
          if (msg.contains('api key') ||
              msg.contains('permission') ||
              msg.contains('401') ||
              msg.contains('403')) {
            rethrow;
          }

          rethrow;
        }
      }
    }

    final hint = lastError != null ? '$lastError' : 'unknown error';
    if (hint.toLowerCase().contains('high demand') ||
        hint.toLowerCase().contains('overloaded') ||
        hint.toLowerCase().contains('try again later')) {
      throw Exception(
        'Gemini sedang sibuk (high demand). Coba lagi beberapa detik.\n\n$hint',
      );
    }
    throw lastError ?? Exception('Tidak ada jawaban dari Gemini');
  }

  Future<String> _chatGeminiOnce(
    String message, {
    required List<Map<String, String>> history,
    required String apiKey,
    required String model,
    String? pageContext,
  }) async {
    // Prefer header auth (more reliable than query key on some clients)
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent',
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

    // Ensure roles alternate starting with user (Gemini requirement)
    final normalized = _normalizeContents(contents);

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt},
        ],
      },
      'contents': normalized,
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
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

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
      throw Exception('$msg [${response.statusCode}]');
    }

    final text = _extractText(decoded);
    if (text != null && text.isNotEmpty) return text;

    final block = decoded['promptFeedback'];
    if (block is Map && block['blockReason'] != null) {
      throw Exception('Diblokir Gemini: ${block['blockReason']}');
    }

    throw Exception('No answer from Gemini (empty candidates)');
  }

  List<Map<String, dynamic>> _normalizeContents(
    List<Map<String, dynamic>> raw,
  ) {
    if (raw.isEmpty) {
      return [
        {
          'role': 'user',
          'parts': [
            {'text': 'Hello'},
          ],
        },
      ];
    }
    final out = <Map<String, dynamic>>[];
    String? lastRole;
    for (final item in raw) {
      final role = item['role'] as String? ?? 'user';
      final parts = item['parts'];
      if (parts is! List || parts.isEmpty) continue;
      if (lastRole == role && out.isNotEmpty) {
        // Merge consecutive same-role turns
        final prevParts = (out.last['parts'] as List).toList();
        prevParts.addAll(parts);
        out.last = {'role': role, 'parts': prevParts};
      } else {
        out.add({'role': role, 'parts': parts});
        lastRole = role;
      }
    }
    if (out.isEmpty || out.first['role'] != 'user') {
      out.insert(0, {
        'role': 'user',
        'parts': [
          {'text': '(start)'},
        ],
      });
    }
    return out;
  }

  String? _extractText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final first = candidates.first;
    if (first is! Map) return null;
    final content = first['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;
    final texts = <String>[];
    for (final part in parts) {
      if (part is Map && part['text'] != null) {
        final t = '${part['text']}'.trim();
        if (t.isNotEmpty) texts.add(t);
      }
    }
    if (texts.isEmpty) return null;
    return texts.join('\n').trim();
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
