class HistoryEntry {
  const HistoryEntry({
    required this.url,
    required this.title,
    required this.visitedAt,
    this.private = false,
  });

  final String url;
  final String title;
  final DateTime visitedAt;
  final bool private;

  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        'visitedAt': visitedAt.toIso8601String(),
        'private': private,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        url: '${json['url'] ?? ''}',
        title: '${json['title'] ?? ''}',
        visitedAt: DateTime.tryParse('${json['visitedAt']}') ?? DateTime.now(),
        private: json['private'] == true,
      );
}
