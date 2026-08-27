import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'storage_service.dart';

class AiService {
  AiService({StorageService? storage}) : _storage = storage ?? StorageService();
  final StorageService _storage;

  static const _geminiKeyStorage = 'gemini_api_key';
  static const _geminiModelStorage = 'gemini_model';

  /// Reliable free-tier models first (simple chat, low latency).
  static const _fallbackModels = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-3.5-flash-lite',
    'gemini-3.5-flash',
    'gemini-3.6-flash',
    'gemini-3.7-flash',
  ];

  static const _systemPrompt =
      'You are MPorT AI, the intelligent assistant in MPorT Browser '
      'for MandalaNet ISP. Be helpful, concise, and accurate. '
      'Reply in the same language the user writes in.';

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
    if (saved != null && saved.trim().isNotEmpty) {
      final m = saved.trim();
      // Prefer stable free Flash on mobile; 3.7 often aborts on weak networks.
      const migrate = {
        'gemini-2.0-flash',
        'gemini-2.0-flash-lite',
        'gemini-1.5-flash',
        'gemini-1.5-pro',
        'gemini-pro',
        'gemini-3.7-flash',
        'gemini-3.6-flash',
      };
      if (migrate.contains(m)) {
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
        ).timeout(
          const Duration(seconds: 35),
          onTimeout: () => throw TimeoutException(
            'Timeout: koneksi lambat atau Gemini tidak merespons. Coba lagi.',
          ),
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
        '3. Tekan lama judul "MPorT AI" → tempel key → Simpan\n\n'
        'Atau build dengan --dart-define=GEMINI_API_KEY=your_key';
  }

  Future<String> _chatGeminiWithRetry(
    String message, {
    required List<Map<String, String>> history,
    required String apiKey,
    String? pageContext,
  }) async {
    final preferred = await resolveModel();
    // Prefer fast free models; put preferred first but de-prioritize heavy 3.7 if it stalls
    final models = <String>[
      preferred,
      ..._fallbackModels.where((m) => m != preferred),
    ];

    Exception? lastError;

    for (var modelIndex = 0; modelIndex < models.length; modelIndex++) {
      final model = models[modelIndex];
      // 2 attempts max on preferred, 1 on fallbacks — avoid endless spinner
      final maxAttempts = modelIndex == 0 ? 2 : 1;

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

          final isTimeout = msg.contains('timeout') ||
              msg.contains('timed out') ||
              e is TimeoutException;

          final isNet = msg.contains('connection abort') ||
              msg.contains('connection closed') ||
              msg.contains('connection reset') ||
              msg.contains('failed host lookup') ||
              msg.contains('network is unreachable') ||
              msg.contains('socket') ||
              msg.contains('clientexception') ||
              msg.contains('software caused connection');

          if (isNotFound) break;

          // Network blip → short wait then retry same model once
          if ((isOverload || isTimeout || isNet) && attempt < maxAttempts) {
            await Future<void>.delayed(Duration(milliseconds: 600 * attempt));
            continue;
          }
          // Then switch model
          if (isOverload || isTimeout || isNet) {
            // Persist stable model so next open doesn't stick on 3.7
            try {
              await _storage.setString(_geminiModelStorage, 'gemini-2.5-flash');
            } catch (_) {}
            break;
          }

          if (msg.contains('api key not valid') ||
              msg.contains('api_key_invalid') ||
              msg.contains('permission denied') ||
              msg.contains('[401]') ||
              msg.contains('[403]')) {
            rethrow;
          }
          // 400 invalid argument → try next model / simplified payload
          if (msg.contains('invalid argument') || msg.contains('[400]')) {
            break;
          }

          // Empty answer / parse → try next model
          if (msg.contains('empty') || msg.contains('no answer')) break;

          rethrow;
        }
      }
    }

    final hint = lastError != null ? '$lastError' : 'unknown';
    final low = hint.toLowerCase();
    if (low.contains('connection abort') ||
        low.contains('clientexception') ||
        low.contains('socket') ||
        low.contains('failed host lookup')) {
      throw Exception(
        'Koneksi ke Gemini terputus (connection abort).\n'
        'Coba: Wi-Fi stabil, matikan VPN, atau ulangi sebentar lagi.\n'
        'Model otomatis diganti ke gemini-2.5-flash.\n\n$hint',
      );
    }
    throw Exception('Gagal mendapat jawaban dari Gemini.\n$hint');
  }

  Future<String> _chatGeminiOnce(
    String message, {
    required List<Map<String, String>> history,
    required String apiKey,
    required String model,
    String? pageContext,
  }) async {
    // Query key = most compatible with Gemini REST API
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent?key=${Uri.encodeQueryComponent(apiKey)}',
    );

    final contents = <Map<String, dynamic>>[];
    for (final turn in history) {
      final role = (turn['role'] ?? 'user') == 'assistant' ? 'model' : 'user';
      var text = turn['content'] ?? turn['message'] ?? '';
      // Skip error bubbles in history
      if (text.startsWith('⚠️')) continue;
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

    final normalized = _normalizeContents(contents);

    // Minimal valid Gemini payload (avoid 400 invalid argument)
    final body = <String, dynamic>{
      'contents': normalized,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    };
    // systemInstruction supported on most Flash models; omit if it causes 400 (retried below)
    body['systemInstruction'] = {
      'parts': [
        {'text': _systemPrompt},
      ],
    };

    Future<http.Response> doPost(Map<String, dynamic> payload) {
      return http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
    }

    late http.Response response;
    try {
      response = await doPost(body);
    } on TimeoutException {
      throw TimeoutException('Timeout memanggil $model (20s)');
    }

    // One automatic retry without systemInstruction on 400 invalid argument
    if (response.statusCode == 400 && body.containsKey('systemInstruction')) {
      final slim = Map<String, dynamic>.from(body)..remove('systemInstruction');
      // Prepend system as first user turn
      final contents = (slim['contents'] as List).toList();
      contents.insert(0, {
        'role': 'user',
        'parts': [
          {'text': '[System] $_systemPrompt'},
        ],
      });
      contents.insert(1, {
        'role': 'model',
        'parts': [
          {'text': 'OK'},
        ],
      });
      slim['contents'] = contents;
      try {
        response = await doPost(slim);
      } on TimeoutException {
        throw TimeoutException('Timeout memanggil $model (20s)');
      }
    }

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

    final finish = _finishReason(decoded);
    throw Exception(
      'No answer from $model'
      '${finish != null ? ' (finish: $finish)' : ''}',
    );
  }

  String? _finishReason(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map && first['finishReason'] != null) {
        return '${first['finishReason']}';
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _normalizeContents(
    List<Map<String, dynamic>> raw,
  ) {
    final out = <Map<String, dynamic>>[];
    String? lastRole;
    for (final item in raw) {
      final role = item['role'] as String? ?? 'user';
      final parts = item['parts'];
      if (parts is! List || parts.isEmpty) continue;
      // Gemini requires strictly alternating user/model roles
      if (lastRole == role && out.isNotEmpty) {
        final prevParts = (out.last['parts'] as List).toList();
        prevParts.addAll(parts);
        out.last = {'role': role, 'parts': prevParts};
      } else {
        out.add({'role': role, 'parts': List<dynamic>.from(parts)});
        lastRole = role;
      }
    }
    if (out.isEmpty) {
      return [
        {
          'role': 'user',
          'parts': [
            {'text': 'Hello'},
          ],
        },
      ];
    }
    // Must start with user
    if (out.first['role'] != 'user') {
      out.insert(0, {
        'role': 'user',
        'parts': [
          {'text': 'Hi'},
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
      if (part is! Map) continue;
      // Skip pure thought parts if present
      if (part['thought'] == true && part['text'] == null) continue;
      final t = part['text'];
      if (t != null) {
        final s = '$t'.trim();
        if (s.isNotEmpty) texts.add(s);
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
        final response = await http
            .post(
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
            )
            .timeout(const Duration(seconds: 20));

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
