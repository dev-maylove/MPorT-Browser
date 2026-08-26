class TrackerBlocker {
  // Architecture for a future native WebView request interceptor.
  // Keep lists configurable and updateable from the backend.
  static const blockedHosts = <String>{
    'doubleclick.net',
    'googlesyndication.com',
    'google-analytics.com',
    'facebook.net',
  };

  bool shouldBlock(Uri uri) {
    final host = uri.host.toLowerCase();
    return blockedHosts.any(
      (blocked) => host == blocked || host.endsWith('.$blocked'),
    );
  }
}
