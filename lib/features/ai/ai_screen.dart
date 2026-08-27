import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key, this.initialPrompt});

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatus());
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final key = await ai.resolveGeminiKey();
      final m = await ai.resolveModel();
      if (!mounted) return;
      setState(() {
        hasKey = key != null && key.isNotEmpty;
        model = m;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => hasKey = false);
    }
  }

  Future<void> _openKeySettings() async {
    final keyCtrl = TextEditingController();
    final modelCtrl = TextEditingController(text: model);
    var obscure = true;

    try {
      final existing = await ai.resolveGeminiKey();
      if (existing != null && existing.isNotEmpty) {
        keyCtrl.text = existing;
      }
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Setup MPorT AI',
                    style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ambil API key gratis di aistudio.google.com/apikey, lalu tempel di bawah.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: keyCtrl,
                    obscureText: obscure,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'AIza...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => setModal(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: modelCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Model (opsional)',
                      hintText: 'gemini-2.5-flash',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final key = keyCtrl.text.trim();
                      final m = modelCtrl.text.trim().isEmpty
                          ? AppConfig.geminiModel
                          : modelCtrl.text.trim();
                      await ai.saveGeminiKey(key);
                      await ai.saveModel(m);
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _loadStatus();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              key.isEmpty
                                  ? 'API key dihapus'
                                  : 'API key tersimpan — siap dipakai',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Simpan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.cyanNeon,
                      foregroundColor: AppTheme.bgDeep,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ai.saveGeminiKey('');
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _loadStatus();
                    },
                    child: const Text('Hapus key'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    keyCtrl.dispose();
    modelCtrl.dispose();
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || loading) return;

    // Re-check key every send (build-time key / storage may change)
    final key = await ai.resolveGeminiKey();
    hasKey = key != null && key.isNotEmpty;
    if (!hasKey) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Setup API key dulu agar MPorT AI bisa menjawab'),
          action: SnackBarAction(label: 'Setup', onPressed: _openKeySettings),
        ),
      );
      await _openKeySettings();
      return;
    }

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
      var msg = '$e';
      // Strip Exception: prefix for cleaner UI
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring('Exception: '.length);
      }
      setState(() {
        messages.add({
          'role': 'assistant',
          'content': '⚠️ $msg',
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
        title: GestureDetector(
          onLongPress: _openKeySettings,
          child: Text(
            'MPorT AI',
            style: GoogleFonts.orbitron(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: Column(
        children: [
          if (!hasKey)
            Material(
              color: AppTheme.cyanNeon.withValues(alpha: 0.12),
              child: InkWell(
                onTap: _openKeySettings,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.cyanNeon, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Belum ada API key — ketuk untuk setup (gratis)',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textMuted),
                    ],
                  ),
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
                            'MPorT AI',
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tanya apa saja — ringkas halaman, terjemah, tips privasi.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (!hasKey) ...[
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _openKeySettings,
                              icon: const Icon(Icons.settings_rounded),
                              label: const Text('Setup AI'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.cyanNeon,
                                foregroundColor: AppTheme.bgDeep,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: messages.length + (loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (loading && i == messages.length) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Menunggu Gemini…',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
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
                        hintText: 'Tanya MPorT AI...',
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
}
