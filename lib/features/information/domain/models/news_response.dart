import 'news_article.dart';

class NewsResponse {
  const NewsResponse({required this.articles, required this.totalResults});
  final List<NewsArticle> articles;
  final int totalResults;

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
    );
  }
}
