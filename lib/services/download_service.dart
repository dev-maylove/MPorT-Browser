import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'download_io_stub.dart'
    if (dart.library.io) 'download_io_io.dart' as io_bridge;

/// Download path helper. Safe on web (no dart:io).
class DownloadService {
  final _uuid = const Uuid();

  Future<String> targetPath(String fileName) async {
    final safe = fileName.replaceAll(RegExp(r'[^\w.\- ]'), '_');
    final id = _uuid.v4();
    if (kIsWeb) {
      return 'web_download/${id}_$safe';
    }
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/${id}_$safe';
  }

  Future<void> writeBytes(String path, List<int> bytes) async {
    if (kIsWeb) return;
    final file = io_bridge.createFile(path);
    await file.writeAsBytes(bytes, flush: true);
  }
}
