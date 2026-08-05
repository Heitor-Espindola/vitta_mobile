import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vitta_mobile/core/config/app_environment.dart';
import 'package:vitta_mobile/core/errors/news_exception.dart';
import 'package:vitta_mobile/features/information/domain/models/news_response.dart';

class NewsApiService {
  NewsApiService({
    http.Client? client,
    String? apiKey,
    Duration timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _apiKey = apiKey ?? AppEnvironment.newsApiKey,
       _timeout = timeout;

  static const defaultQuery =
      '("vacinação" OR "vacinas" OR "imunização" OR "campanha de vacinação" OR "calendário vacinal")';
  final http.Client _client;
  final bool _ownsClient;
  final String _apiKey;
  final Duration _timeout;

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
        : '$defaultQuery AND "${normalized.replaceAll('"', '')}"';
    final uri = Uri.https('newsapi.org', '/v2/everything', {
      'q': query,
      'language': 'pt',
      'sortBy': 'publishedAt',
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
      return NewsResponse.fromJson(decoded);
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
}
