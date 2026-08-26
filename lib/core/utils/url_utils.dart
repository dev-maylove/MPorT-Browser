import '../../models/search_engine.dart';
import '../../services/search_service.dart';

class UrlUtils {
  /// Optional shared search service; set from BrowserController after load.
  static SearchService? searchService;

  static bool isUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' ||
        scheme == 'https' ||
        scheme == 'about' ||
        scheme == 'file' ||
        scheme == 'data';
  }

  /// True if input looks like a hostname (example.com, localhost:8080).
  static bool looksLikeDomain(String value) {
    final input = value.trim();
    if (input.contains(' ') || input.isEmpty) return false;
    if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}(:\d+)?$').hasMatch(input)) {
      return true;
    }
    // Require a plausible TLD (2+ letters) to avoid treating "file.txt" style
    // short tokens oddly — still allow multi-dot hosts.
    if (RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)+(:\d+)?(/.*)?$')
        .hasMatch(input)) {
      return true;
    }
    if (input == 'localhost' || input.startsWith('localhost:')) return true;
    return false;
  }

  /// Normalize address-bar input to a navigable URL.
  static String normalize(String value, {SearchEngine? engine}) {
    final input = value.trim();
    if (input.isEmpty) return 'about:blank';
    if (input == 'about:blank') return input;

    // Keyword search: "g flutter", "ddg privacy"
    final space = input.indexOf(' ');
    if (space > 0) {
      final kw = input.substring(0, space);
      final rest = input.substring(space + 1).trim();
      final byKw = SearchEngines.byKeyword(kw);
      if (byKw != null && rest.isNotEmpty) {
        return byKw.buildSearchUrl(rest);
      }
    }

    if (isUrl(input)) {
      final uri = Uri.tryParse(input);
      if (uri != null && uri.scheme.isEmpty) {
        return 'https://$input';
      }
      return input;
    }

    if (looksLikeDomain(input)) {
      return 'https://$input';
    }

    final svc = searchService;
    if (engine != null) return engine.buildSearchUrl(input);
    if (svc != null) return svc.searchUrl(input);
    return SearchEngines.google.buildSearchUrl(input);
  }
}
