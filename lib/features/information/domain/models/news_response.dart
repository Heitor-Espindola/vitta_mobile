import 'news_article.dart';

class NewsResponse {
  const NewsResponse({
    required this.articles,
    required this.totalResults,
    this.fetchedCount,
  });
  final List<NewsArticle> articles;
  final int totalResults;

  /// Number of articles returned by the API before editorial filtering.
  /// Pagination must not depend on how many survived the filter.
  final int? fetchedCount;

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    final rawArticles = json['articles'];
    final articles = rawArticles is List
        ? rawArticles
              .whereType<Map<String, dynamic>>()
              .map(NewsArticle.fromJson)
              .whereType<NewsArticle>()
              .toList()
        : <NewsArticle>[];
    return NewsResponse(
      articles: articles,
      totalResults: json['totalResults'] as int? ?? articles.length,
      fetchedCount: rawArticles is List ? rawArticles.length : 0,
    );
  }
}
