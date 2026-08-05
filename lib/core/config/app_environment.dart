abstract final class AppEnvironment {
  static const newsApiKey = String.fromEnvironment('NEWS_API_KEY');

  static bool get hasNewsApiKey => newsApiKey.trim().isNotEmpty;
}
