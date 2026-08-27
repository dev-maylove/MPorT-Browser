import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    final seed = widget.initialPrompt?.trim();
    if (seed != null && seed.isNotEmpty) input.text = seed;
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || loading) return;
    input.clear();
    final history = List<Map<String, String>>.from(messages);
    setState(() {
      messages.add({'role': 'user', 'content': text});
      loading = true;
    });
    try {
      final answer = await ai.chat(text, history: history);
      if (!mounted) return;
      setState(() => messages.add({'role': 'assistant', 'content': answer}));
    } catch (e) {
      if (!mounted) return;
      var msg = '$e';
      if (msg.startsWith('Exception: ')) msg = msg.substring(11);
      setState(() => messages.add({'role': 'assistant', 'content': '⚠️ $msg'}));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: Text('MPorT AI', style: GoogleFonts.orbitron(fontWeight: FontWeight.w700))),
      body: Column(
        children: [
          if (messages.isEmpty)
            Material(
              color: AppTheme.cyanNeon.withValues(alpha: .10),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(children: [
                  Icon(Icons.lock_outline_rounded, color: AppTheme.cyanNeon),
                  SizedBox(width: 10),
                  Expanded(child: Text('AI memakai MPorT AI Gateway. API key Gemini tidak disimpan di perangkat.')),
                ]),
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.auto_awesome_rounded, size: 52, color: AppTheme.cyanNeon),
                      const SizedBox(height: 14),
                      Text('MPorT AI', style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text('Tanya apa saja, ringkas halaman, dan bantu menjelajah dengan aman.', textAlign: TextAlign.center),
                    ]),
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length + (loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == messages.length) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
                      final m = messages[i];
                      final user = m['role'] == 'user';
                      return Align(
                        alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 720),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: user ? AppTheme.cyanNeon.withValues(alpha: .16) : AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(m['content'] ?? ''),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: input,
                  minLines: 1,
                  maxLines: 5,
                  onSubmitted: (_) => send(),
                  decoration: const InputDecoration(hintText: 'Tanya MPorT AI…', border: OutlineInputBorder()),
                )),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: loading ? null : send, icon: const Icon(Icons.send_rounded)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
