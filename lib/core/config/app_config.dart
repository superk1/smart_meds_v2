class AppConfig {
  /// Base URL for the Smart Med V2 API.
  /// 
  /// Set this via --dart-define=API_BASE_URL=https://your-api.com
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://smartmed-api-production.up.railway.app/v2',
  );

  /// Timeout for network requests in seconds.
  static const int networkTimeoutSeconds = 15;
}
