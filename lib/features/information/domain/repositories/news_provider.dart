import '../models/news_response.dart';

abstract interface class NewsProvider {
  String get providerName;
  int get pageSizeHint;
  bool get isConfigured;

  /// Returns normalized provider data before editorial filtering.
  Future<NewsResponse> fetchRaw({
    required int page,
    int pageSize,
    String searchTerm,
  });

  void dispose();
}
