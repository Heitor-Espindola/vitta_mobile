abstract final class AppEnvironment {
  /// SQL Connect is the production domain backend. `firestore` exists only as
  /// an explicit, temporary rollback switch and never enables dual writes.
  static const domainBackend = String.fromEnvironment(
    'VITTA_DOMAIN_BACKEND',
    defaultValue: 'sql',
  );

  static bool get useLegacyFirestoreDomain =>
      domainBackend.trim().toLowerCase() == 'firestore';

  static const newsApiKey = String.fromEnvironment(
    'NEWS_API_KEY',
    defaultValue: '',
  );

  static bool get hasNewsApiKey => newsApiKey.trim().isNotEmpty;

  static const newsDataApiKey = String.fromEnvironment(
    'NEWSDATA_API_KEY',
    defaultValue: String.fromEnvironment('NEWS_DATA_API_KEY', defaultValue: ''),
  );

  static bool get hasNewsDataApiKey => newsDataApiKey.trim().isNotEmpty;
}
