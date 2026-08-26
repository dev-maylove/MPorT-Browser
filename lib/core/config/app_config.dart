class AppConfig {
  static const appName = 'MPorT Browser';
  static const version = '2.0.1';
  static const brandName = 'MandalaNet';

  /// Public web portal (New Tab default / home page inside WebView).
  static const webBaseUrl = String.fromEnvironment(
    'MPORT_URL',
    defaultValue: 'https://mandalanet.id',
  );

  /// Laravel API base, e.g. https://portal.example.com/api
  static const apiBaseUrl = String.fromEnvironment(
    'MPORT_API_URL',
    defaultValue: '',
  );

  static const aiEnabled = bool.fromEnvironment(
    'MPORT_AI',
    defaultValue: true,
  );

  static const enableHttp = bool.fromEnvironment(
    'MPORT_ALLOW_HTTP',
    defaultValue: true,
  );

  /// Preferred API version path segment.
  static const apiVersion = 'v1';
}
