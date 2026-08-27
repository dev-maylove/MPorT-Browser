class TrackerBlocker {
  // Fallback navigation-level protection for iOS/other platforms. Android uses
  // the native resource-level WebViewClient interceptor in MainActivity.kt.
  // Keep this list conservative to avoid breaking legitimate sites.
  static const blockedHosts = <String>{
    'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
    'google-analytics.com', 'analytics.google.com', 'googletagmanager.com',
    'facebook.net', 'connect.facebook.net', 'facebook.com/tr',
    'ads-twitter.com', 'ads.linkedin.com', 'bat.bing.com',
    'scorecardresearch.com', 'quantserve.com', 'hotjar.com',
    'clarity.ms', 'segment.io', 'segment.com', 'mixpanel.com',
    'amplitude.com', 'criteo.com', 'adnxs.com', 'taboola.com',
    'outbrain.com', 'zedo.com', 'rubiconproject.com', 'pubmatic.com',
  };

  bool shouldBlock(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    return blockedHosts.any((blocked) {
      if (blocked.contains('/')) {
        final parts = blocked.split('/');
        return host == parts.first && path.startsWith('/${parts.skip(1).join('/')}');
      }
      return host == blocked || host.endsWith('.$blocked');
    });
  }
}
