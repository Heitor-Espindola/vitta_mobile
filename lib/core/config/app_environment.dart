abstract final class AppEnvironment {
  static const newsApiKey = String.fromEnvironment(
    'NEWS_API_KEY',
    defaultValue: '317634d722e84992ba25bfec8c974a8d',
  );

  static bool get hasNewsApiKey => newsApiKey.trim().isNotEmpty;
}
