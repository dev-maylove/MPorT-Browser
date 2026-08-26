import '../models/search_engine.dart';
import 'storage_service.dart';

/// Mengelola mesin pencarian default + resolve query → URL.
class SearchService {
  SearchService({StorageService? storage})
      : _storage = storage ?? StorageService();

  final StorageService _storage;
  static const _prefKey = 'search_engine_id';

  SearchEngine _current = SearchEngines.google;
  bool _loaded = false;

  SearchEngine get current => _current;

  Future<SearchEngine> load() async {
    if (_loaded) return _current;
    final id = await _storage.getString(_prefKey);
    _current = SearchEngines.byId(id);
    _loaded = true;
    return _current;
  }

  Future<void> setEngine(SearchEngine engine) async {
    _current = engine;
    _loaded = true;
    await _storage.setString(_prefKey, engine.id);
  }

  Future<void> setEngineById(String id) async {
    await setEngine(SearchEngines.byId(id));
  }

  /// Bangun URL pencarian memakai engine default.
  String searchUrl(String query) => _current.buildSearchUrl(query);

  /// Omnibox-style:
  /// - `g flutter` → Google search "flutter"
  /// - `ddg privacy` → DuckDuckGo
  /// - URL / domain → dinormalisasi di UrlUtils
  /// - teks biasa → engine default
  ResolvedQuery resolve(String raw, {SearchEngine? prefer}) {
    final input = raw.trim();
    if (input.isEmpty) {
      return const ResolvedQuery(url: 'about:blank', kind: QueryKind.empty);
    }

    // Keyword prefix: "g query here"
    final space = input.indexOf(' ');
    if (space > 0) {
      final kw = input.substring(0, space);
      final rest = input.substring(space + 1).trim();
      final engine = SearchEngines.byKeyword(kw);
      if (engine != null && rest.isNotEmpty) {
        return ResolvedQuery(
          url: engine.buildSearchUrl(rest),
          kind: QueryKind.search,
          engine: engine,
          query: rest,
        );
      }
    }

    final engine = prefer ?? _current;
    return ResolvedQuery(
      url: engine.buildSearchUrl(input),
      kind: QueryKind.search,
      engine: engine,
      query: input,
    );
  }
}

enum QueryKind { empty, search, url }

class ResolvedQuery {
  const ResolvedQuery({
    required this.url,
    required this.kind,
    this.engine,
    this.query,
  });

  final String url;
  final QueryKind kind;
  final SearchEngine? engine;
  final String? query;
}
