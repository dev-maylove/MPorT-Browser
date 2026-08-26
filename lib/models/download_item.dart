enum DownloadStatus { queued, downloading, completed, failed, cancelled }

class DownloadItem {
  DownloadItem({
    required this.id,
    required this.url,
    required this.fileName,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.localPath,
  });

  final String id;
  final String url;
  final String fileName;
  DownloadStatus status;
  double progress;
  String? localPath;
}
