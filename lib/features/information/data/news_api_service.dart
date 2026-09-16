import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vitta_mobile/core/config/app_environment.dart';
import 'package:vitta_mobile/core/errors/news_exception.dart';
import 'package:vitta_mobile/features/information/domain/models/news_article.dart';
import 'package:vitta_mobile/features/information/domain/models/news_response.dart';
import 'package:vitta_mobile/features/information/domain/services/news_relevance_filter.dart';
import 'package:vitta_mobile/features/information/domain/services/trusted_news_sources.dart';

class NewsApiService {
  NewsApiService({
    http.Client? client,
    String? apiKey,
    Duration timeout = const Duration(seconds: 15),
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _apiKey = apiKey ?? AppEnvironment.newsApiKey,
       _timeout = timeout,
       _now = now ?? DateTime.now;

  static const defaultQuery =
      '("vacina" OR "vacinas" OR "vacinação" OR "imunização" OR "imunizante" OR "calendário vacinal" OR "cobertura vacinal" OR "campanha de vacinação")';
  final http.Client _client;
  final bool _ownsClient;
  final String _apiKey;
  final Duration _timeout;
  final DateTime Function() _now;
  bool _limitedHistory = false;

  Future<NewsResponse> fetch({
    required int page,
    int pageSize = 20,
    String searchTerm = '',
  }) async {
    if (_apiKey.trim().isEmpty) {
      debugPrint('NEWS_API_KEY não configurada.');
      throw const NewsException(NewsErrorType.apiKeyMissing);
    }
    final normalized = searchTerm.trim().replaceAll(RegExp(r'\s+'), ' ');
    final query = normalized.isEmpty
        ? defaultQuery
        : '$defaultQuery AND ($normalized)';
    Uri requestUri({required int daysBack}) =>
        Uri.https('newsapi.org', '/v2/everything', {
          'q': query,
          'searchIn': 'title,description',
          'domains': TrustedNewsSources.trustedNewsDomains.join(','),
          'language': 'pt',
          'sortBy': 'publishedAt',
          'from': _formatApiDate(
            _now().toUtc().subtract(Duration(days: daysBack)),
          ),
          'pageSize': '$pageSize',
          'page': '$page',
        });
    try {
      Future<http.Response> request(int daysBack) => _client
          .get(requestUri(daysBack: daysBack), headers: {'X-Api-Key': _apiKey})
          .timeout(_timeout);
      var response = await request(_limitedHistory ? 29 : 90);
      // The free NewsAPI plan can reject a 90-day search with HTTP 426.
      // Preserve the wider window on plans that support it; retry once within
      // the restricted window when the server explicitly rejects older dates.
      if (!_limitedHistory && _isHistoryLimit(response)) {
        _limitedHistory = true;
        response = await request(29);
      }
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
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'ok') {
        throw const NewsException(NewsErrorType.invalidResponse);
      }
      final parsed = NewsResponse.fromJson(decoded);
      final seenUrls = <String>{};
      final articles = <NewsArticle>[];
      for (final article in parsed.articles) {
        final trustedName = TrustedNewsSources.nameForUrl(article.url);
        if (trustedName == null ||
            !NewsRelevanceFilter.isRelevant(article) ||
            !seenUrls.add(article.url)) {
          continue;
        }
        articles.add(article.withSourceName(trustedName));
      }
      articles.sort((a, b) {
        final first = a.publishedAt;
        final second = b.publishedAt;
        if (first == null) return second == null ? 0 : 1;
        if (second == null) return -1;
        return second.compareTo(first);
      });
      return NewsResponse(
        articles: articles,
        totalResults: parsed.totalResults,
        fetchedCount: parsed.fetchedCount,
      );
    } on TimeoutException {
      throw const NewsException(NewsErrorType.timeout);
    } on http.ClientException {
      throw const NewsException(NewsErrorType.network);
    } on FormatException catch (error) {
      debugPrint('Resposta de notícias inválida: ${error.message}');
      throw const NewsException(NewsErrorType.invalidResponse);
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }

  static String _formatApiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static bool _isHistoryLimit(http.Response response) {
    if (response.statusCode != 426) return false;
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body is Map<String, dynamic> &&
          body['code'] == 'parameterInvalid' &&
          body['message'] is String &&
          (body['message'] as String).contains('far in the past');
    } on FormatException {
      return false;
    }
  }
}
