import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    final seed = widget.initialPrompt?.trim();
    if (seed != null && seed.isNotEmpty) {
      input.text = seed;
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
            Text(
              'MPorT AI',
              style: GoogleFonts.orbitron(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 48,
                              color:
                                  AppTheme.cyanNeon.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'MPorT ISP Assistant',
                            style: GoogleFonts.orbitron(
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask about packages, invoices, tickets, or network status.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final user = messages[i]['role'] == 'user';
                      return Align(
                        alignment: user
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 370),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: user ? AppTheme.gradientCyanPurple : null,
                            color: user ? null : AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(18),
                            border: user
                                ? null
                                : Border.all(
                                    color: AppTheme.cyanNeon
                                        .withValues(alpha: 0.15),
                                  ),
                          ),
                          child: Text(
                            messages[i]['content'] ?? '',
                            style: GoogleFonts.inter(
                              color: user
                                  ? AppTheme.bgDeep
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (loading)
            const LinearProgressIndicator(
              color: AppTheme.cyanNeon,
              backgroundColor: AppTheme.bgCard,
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
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
                        hintText: 'Ask about MPorT...',
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
