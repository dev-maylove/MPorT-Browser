class AppConfig {
  static const appName = 'MPorT Browser';
  static const version = '2.1.7';
  static const brandName = 'MandalaNet';

  static const webBaseUrl = String.fromEnvironment(
    'MPORT_URL',
    defaultValue: 'https://mandalanet.id',
  );

  static const apiBaseUrl = String.fromEnvironment(
    'MPORT_API_URL',
    defaultValue: '',
  );

  static const aiEnabled = bool.fromEnvironment(
    'MPORT_AI',
    defaultValue: true,
  );

  /// AI credentials never belong in the APK. MPorT AI uses the server gateway.
  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash',
  );

  /// HTTP is opt-in per build. The browser still shows an explicit warning for HTTP.
  static const enableHttp = bool.fromEnvironment(
    'MPORT_ALLOW_HTTP',
    defaultValue: false,
  );

  static const apiVersion = 'v1';

  static bool isHttpAllowed(Uri uri) =>
      uri.scheme.toLowerCase() == 'https' ||
      (uri.scheme.toLowerCase() == 'http' && enableHttp);
}
