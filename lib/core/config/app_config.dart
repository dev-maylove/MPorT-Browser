class AppConfig {
  static const appName = 'MPorT Browser';
  static const version = '2.0.6';
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

  /// Google Gemini API key (build-time). Can also be set in-app under MPorT AI.
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Gemini model id (free-tier Flash).
  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.7-flash',
  );

  static const enableHttp = bool.fromEnvironment(
    'MPORT_ALLOW_HTTP',
    defaultValue: true,
  );

  /// Preferred API version path segment.
  static const apiVersion = 'v1';
}
