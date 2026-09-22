import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:vitta_mobile/core/config/app_environment.dart';
import 'package:vitta_mobile/core/errors/news_exception.dart';
import 'package:vitta_mobile/features/information/domain/models/news_article.dart';
import 'package:vitta_mobile/features/information/domain/models/news_response.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_provider.dart';
import 'package:vitta_mobile/features/information/domain/services/news_relevance_filter.dart';
import 'package:vitta_mobile/features/information/domain/services/trusted_news_sources.dart';

/// Optional secondary provider. Configure with --dart-define=NEWSDATA_API_KEY=...
class NewsDataApiService implements NewsProvider {
  NewsDataApiService({
    http.Client? client,
    String? apiKey,
    Duration timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _apiKey = apiKey ?? AppEnvironment.newsDataApiKey,
       _timeout = timeout;

  final http.Client _client;
  final bool _ownsClient;
  final String _apiKey;
  final Duration _timeout;
  final Map<String, Map<int, String>> _pageTokens = {};

  @override
  String get providerName => 'newsdata';

  @override
  int get pageSizeHint => 10;

  @override
  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<NewsResponse> fetch({
    required int page,
    String searchTerm = '',
  }) async {
    final raw = await fetchRaw(page: page, searchTerm: searchTerm);
    return _applyEditorialFilters(raw);
  }

  @override
  Future<NewsResponse> fetchRaw({
    required int page,
    int pageSize = 10,
    String searchTerm = '',
  }) async {
    if (!isConfigured) {
      throw const NewsException(NewsErrorType.apiKeyMissing);
    }
    final normalized = searchTerm.trim().replaceAll(RegExp(r'\s+'), ' ');
    const baseQuery =
        'vacina OR vacinação OR imunização OR imunizante OR HPV OR influenza OR "febre amarela" OR BCG';
    final query = normalized.isEmpty
        ? baseQuery
        : '($baseQuery) AND ($normalized)';
    final parameters = <String, String>{
      'apikey': _apiKey,
      'q': query,
      'language': 'pt',
      'country': 'br',
      'category': 'health',
    };
    if (page > 1) {
      final token = _pageTokens[normalized]?[page];
      if (token == null) {
        return const NewsResponse(
          articles: [],
          totalResults: 0,
          fetchedCount: 0,
        );
      }
      parameters['page'] = token;
    }

    try {
      final response = await _client
          .get(Uri.https('newsdata.io', '/api/1/latest', parameters))
          .timeout(_timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const NewsException(NewsErrorType.apiKeyInvalid);
      }
      if (response.statusCode == 429) {
        throw const NewsException(NewsErrorType.rateLimited);
      }
      if (response.statusCode >= 500) {
        throw const NewsException(NewsErrorType.server);
      }
      if (response.statusCode != 200) {
        throw const NewsException(NewsErrorType.invalidResponse);
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const NewsException(NewsErrorType.invalidResponse);
      }
      if (decoded['status'] != 'success') throw _errorFromBody(decoded);
      final rawResults = decoded['results'];
      if (rawResults is! List) {
        throw const NewsException(NewsErrorType.invalidResponse);
      }
      final nextPage = decoded['nextPage'];
      if (nextPage is String && nextPage.isNotEmpty) {
        (_pageTokens[normalized] ??= {})[page + 1] = nextPage;
      }
      final articles = <NewsArticle>[];
      for (final raw in rawResults.whereType<Map<String, dynamic>>()) {
        final article = NewsArticle.fromNewsDataJson(raw);
        if (article != null) articles.add(article);
      }
      articles.sort(_newestFirst);
      return NewsResponse(
        articles: articles,
        totalResults: decoded['totalResults'] as int? ?? rawResults.length,
        fetchedCount: rawResults.length,
      );
    } on TimeoutException {
      throw const NewsException(NewsErrorType.timeout);
    } on http.ClientException {
      throw const NewsException(NewsErrorType.network);
    } on FormatException catch (error) {
      developer.log(
        'Resposta da NewsData.io inválida: ${error.message}',
        name: 'vitta.news',
      );
      throw const NewsException(NewsErrorType.invalidResponse);
    }
  }

  static NewsResponse _applyEditorialFilters(NewsResponse raw) {
    final seenUrls = <String>{};
    final articles = <NewsArticle>[];
    for (final article in raw.articles) {
      final trustedName = TrustedNewsSources.nameForUrl(article.url);
      if (trustedName == null ||
          !NewsRelevanceFilter.isRelevant(article) ||
          !seenUrls.add(article.url)) {
        continue;
      }
      articles.add(article.withSourceName(trustedName));
    }
    articles.sort(_newestFirst);
    return NewsResponse(
      articles: articles,
      totalResults: raw.totalResults,
      fetchedCount: raw.fetchedCount,
    );
  }

  static NewsException _errorFromBody(Map<String, dynamic> body) {
    final text = '${body['results'] ?? ''} ${body['message'] ?? ''}'
        .toLowerCase();
    if (text.contains('api key') || text.contains('apikey')) {
      return const NewsException(NewsErrorType.apiKeyInvalid);
    }
    if (text.contains('credit') ||
        text.contains('limit') ||
        text.contains('quota')) {
      return const NewsException(NewsErrorType.rateLimited);
    }
    return const NewsException(NewsErrorType.invalidResponse);
  }

  static int _newestFirst(NewsArticle first, NewsArticle second) {
    if (first.publishedAt == null) return second.publishedAt == null ? 0 : 1;
    if (second.publishedAt == null) return -1;
    return second.publishedAt!.compareTo(first.publishedAt!);
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
