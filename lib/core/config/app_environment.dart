abstract final class AppEnvironment {
  static const newsApiKey = String.fromEnvironment(
    'NEWS_API_KEY',
    defaultValue: '',
  );

  static bool get hasNewsApiKey => newsApiKey.trim().isNotEmpty;

  static const newsDataApiKey = String.fromEnvironment(
    'NEWSDATA_API_KEY',
    defaultValue: '',
  );

  static bool get hasNewsDataApiKey => newsDataApiKey.trim().isNotEmpty;
}
