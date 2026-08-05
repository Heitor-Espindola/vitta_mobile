import '../models/news_response.dart';

abstract interface class NewsRepository {
  Future<NewsResponse> getNews({
    required String query,
    required int page,
    bool forceRefresh = false,
  });

  void dispose();
}
