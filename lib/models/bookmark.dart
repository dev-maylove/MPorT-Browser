class Bookmark {
  const Bookmark({
    required this.id,
    required this.title,
    required this.url,
    required this.folder,
  });

  final String id;
  final String title;
  final String url;
  final String folder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'folder': folder,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: '${json['id']}',
        title: '${json['title'] ?? 'Bookmark'}',
        url: '${json['url'] ?? ''}',
        folder: '${json['folder'] ?? 'General'}',
      );
}
