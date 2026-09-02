import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vitta_mobile/core/config/app_environment.dart';
import 'package:vitta_mobile/core/errors/news_exception.dart';
import 'package:vitta_mobile/features/information/domain/models/news_response.dart';
import 'package:vitta_mobile/features/information/domain/services/news_relevance_filter.dart';

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
    final from = _now().toUtc().subtract(const Duration(days: 30));
    final uri = Uri.https('newsapi.org', '/v2/everything', {
      'q': query,
      'searchIn': 'title,description',
      'language': 'pt',
      'sortBy': 'publishedAt',
      'from': _formatApiDate(from),
      'pageSize': '$pageSize',
      'page': '$page',
    });
    try {
      final response = await _client
          .get(uri, headers: {'X-Api-Key': _apiKey})
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
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'ok') {
        throw const NewsException(NewsErrorType.invalidResponse);
      }
      final parsed = NewsResponse.fromJson(decoded);
      return NewsResponse(
        articles: parsed.articles
            .where(NewsRelevanceFilter.isRelevant)
            .toList(growable: false),
        totalResults: parsed.totalResults,
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
}
