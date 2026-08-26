import 'package:flutter/material.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Manager')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_done_rounded, size: 54),
            SizedBox(height: 12),
            Text('Download Manager'),
            SizedBox(height: 6),
            Text('Queue, progress, pause, resume, and download history — ready for a native download worker.'),
          ],
        ),
      ),
    );
  }
}
