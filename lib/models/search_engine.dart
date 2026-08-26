/// Definisi mesin pencarian yang bisa dipilih pengguna.
class SearchEngine {
  const SearchEngine({
    required this.id,
    required this.name,
    required this.keyword,
    required this.searchUrlTemplate,
    this.suggestUrlTemplate,
    this.homepage,
    this.icon = 'search',
  });

  /// ID stabil untuk penyimpanan (mis. google, duckduckgo).
  final String id;

  /// Nama tampilan.
  final String name;

  /// Keyword omnibox, mis. `g` → `g flutter` pakai engine ini.
  final String keyword;

  /// Template URL; wajib berisi `{query}`.
  final String searchUrlTemplate;

  /// Opsional suggestion API template.
  final String? suggestUrlTemplate;

  final String? homepage;

  /// Hint ikon Material (nama logis).
  final String icon;

  String buildSearchUrl(String query) {
    final q = query.trim();
    return searchUrlTemplate.replaceAll('{query}', Uri.encodeComponent(q));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'keyword': keyword,
        'searchUrlTemplate': searchUrlTemplate,
        'suggestUrlTemplate': suggestUrlTemplate,
        'homepage': homepage,
        'icon': icon,
      };

  factory SearchEngine.fromJson(Map<String, dynamic> json) => SearchEngine(
        id: '${json['id']}',
        name: '${json['name'] ?? json['id']}',
        keyword: '${json['keyword'] ?? ''}',
        searchUrlTemplate:
            '${json['searchUrlTemplate'] ?? 'https://www.google.com/search?q={query}'}',
        suggestUrlTemplate: json['suggestUrlTemplate'] as String?,
        homepage: json['homepage'] as String?,
        icon: '${json['icon'] ?? 'search'}',
      );

  @override
  bool operator ==(Object other) =>
      other is SearchEngine && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Katalog bawaan MPorT Browser.
class SearchEngines {
  SearchEngines._();

  static const google = SearchEngine(
    id: 'google',
    name: 'Google',
    keyword: 'g',
    searchUrlTemplate: 'https://www.google.com/search?q={query}',
    homepage: 'https://www.google.com',
    icon: 'g',
  );

  static const duckDuckGo = SearchEngine(
    id: 'duckduckgo',
    name: 'DuckDuckGo',
    keyword: 'ddg',
    searchUrlTemplate: 'https://duckduckgo.com/?q={query}',
    homepage: 'https://duckduckgo.com',
    icon: 'privacy',
  );

  static const bing = SearchEngine(
    id: 'bing',
    name: 'Bing',
    keyword: 'b',
    searchUrlTemplate: 'https://www.bing.com/search?q={query}',
    homepage: 'https://www.bing.com',
    icon: 'b',
  );

  static const brave = SearchEngine(
    id: 'brave',
    name: 'Brave Search',
    keyword: 'br',
    searchUrlTemplate: 'https://search.brave.com/search?q={query}',
    homepage: 'https://search.brave.com',
    icon: 'shield',
  );

  static const ecosia = SearchEngine(
    id: 'ecosia',
    name: 'Ecosia',
    keyword: 'eco',
    searchUrlTemplate: 'https://www.ecosia.org/search?q={query}',
    homepage: 'https://www.ecosia.org',
    icon: 'eco',
  );

  static const startpage = SearchEngine(
    id: 'startpage',
    name: 'Startpage',
    keyword: 'sp',
    searchUrlTemplate: 'https://www.startpage.com/sp/search?query={query}',
    homepage: 'https://www.startpage.com',
    icon: 'lock',
  );

  static const yahoo = SearchEngine(
    id: 'yahoo',
    name: 'Yahoo',
    keyword: 'y',
    searchUrlTemplate: 'https://search.yahoo.com/search?p={query}',
    homepage: 'https://www.yahoo.com',
    icon: 'y',
  );

  static const yandex = SearchEngine(
    id: 'yandex',
    name: 'Yandex',
    keyword: 'ya',
    searchUrlTemplate: 'https://yandex.com/search/?text={query}',
    homepage: 'https://yandex.com',
    icon: 'ya',
  );

  /// Regional Indonesia search engine.
  static const googleId = SearchEngine(
    id: 'google_id',
    name: 'Google Indonesia',
    keyword: 'gid',
    searchUrlTemplate: 'https://www.google.co.id/search?q={query}&hl=id',
    homepage: 'https://www.google.co.id',
    icon: 'g',
  );

  static const List<SearchEngine> all = [
    google,
    googleId,
    duckDuckGo,
    bing,
    brave,
    ecosia,
    startpage,
    yahoo,
    yandex,
  ];

  static SearchEngine byId(String? id) {
    if (id == null || id.isEmpty) return google;
    return all.firstWhere((e) => e.id == id, orElse: () => google);
  }

  static SearchEngine? byKeyword(String keyword) {
    final k = keyword.toLowerCase().trim();
    if (k.isEmpty) return null;
    for (final e in all) {
      if (e.keyword == k) return e;
    }
    return null;
  }
}
