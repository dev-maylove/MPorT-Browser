import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key, this.initialPrompt});

  /// Optional starter prompt (e.g. Summarize / Translate).
  final String? initialPrompt;

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final ai = AiService();
  final input = TextEditingController();
  final messages = <Map<String, String>>[];
  bool loading = false;
  bool hasKey = false;
  String model = AppConfig.geminiModel;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialPrompt?.trim();
    if (seed != null && seed.isNotEmpty) {
      input.text = seed;
    }
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final key = await ai.resolveGeminiKey();
    final m = await ai.resolveModel();
    if (!mounted) return;
    setState(() {
      hasKey = key != null && key.isNotEmpty;
      model = m;
    });
  }

  Future<void> _openKeySettings() async {
    final keyCtrl = TextEditingController(text: '');
    final existing = await ai.resolveGeminiKey();
    if (existing != null) keyCtrl.text = existing;
    final modelCtrl = TextEditingController(text: await ai.resolveModel());

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text(
          'Gemini API',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get a free key at aistudio.google.com/apikey',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'AIza...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'gemini-2.0-flash',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await ai.saveGeminiKey(keyCtrl.text);
      await ai.saveModel(modelCtrl.text.isEmpty ? AppConfig.geminiModel : modelCtrl.text);
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gemini settings saved')),
        );
      }
    }
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || loading) return;

    input.clear();
    final historyForApi = List<Map<String, String>>.from(messages);

    setState(() {
      messages.add({'role': 'user', 'content': text});
      loading = true;
    });

    try {
      final answer = await ai.chat(text, history: historyForApi);
      if (!mounted) return;
      setState(() {
        messages.add({'role': 'assistant', 'content': answer});
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add({
          'role': 'assistant',
          'content': 'MPorT AI error: $e',
        });
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.gradientAi,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppTheme.bgDeep),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MPorT AI',
                  style: GoogleFonts.orbitron(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  hasKey ? 'Gemini · $model' : 'Gemini key required',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: hasKey ? AppTheme.greenStatus : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Gemini API key',
            onPressed: _openKeySettings,
            icon: Icon(
              hasKey ? Icons.vpn_key_rounded : Icons.vpn_key_off_rounded,
              color: hasKey ? AppTheme.cyanNeon : AppTheme.textMuted,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!hasKey)
            Material(
              color: AppTheme.cyanNeon.withValues(alpha: 0.12),
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: AppTheme.cyanNeon),
                title: const Text('Connect Gemini'),
                subtitle: const Text('Tap the key icon to add your API key'),
                trailing: TextButton(
                  onPressed: _openKeySettings,
                  child: const Text('Setup'),
                ),
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 48, color: AppTheme.cyanNeon),
                          const SizedBox(height: 16),
                          Text(
                            'MPorT AI + Gemini',
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask anything — summaries, translate, privacy tips, browsing help.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: messages.length + (loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (loading && i == messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final m = messages[i];
                      final isUser = m['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppTheme.cyanNeon.withValues(alpha: 0.2)
                                : AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.cyanNeon.withValues(alpha: 0.2),
                            ),
                          ),
                          child: SelectableText(
                            m['content'] ?? '',
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask MPorT AI...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.cyanNeon,
                      foregroundColor: AppTheme.bgDeep,
                    ),
                    onPressed: loading ? null : send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }
}
