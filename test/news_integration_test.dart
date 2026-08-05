import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vitta_mobile/core/errors/news_exception.dart';
import 'package:vitta_mobile/features/information/data/news_api_service.dart';
import 'package:vitta_mobile/features/information/data/news_repository.dart';
import 'package:vitta_mobile/features/information/domain/models/news_article.dart';
import 'package:vitta_mobile/features/information/domain/models/news_response.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_repository.dart';
import 'package:vitta_mobile/features/information/presentation/controllers/news_controller.dart';

const articleJson = {
  'source': {'name': 'Agência Saúde'},
  'author': 'Autora',
  'title': 'Campanha de vacinação começa hoje',
  'description': 'Postos estão preparados para atender a população.',
  'url': 'https://example.com/noticia-1',
  'urlToImage': 'https://example.com/image.jpg',
  'publishedAt': '2026-08-05T12:30:00Z',
  'content': 'Conteúdo truncado',
};

void main() {
  group('NewsArticle', () {
    test('parses a complete article', () {
      final article = NewsArticle.fromJson(articleJson)!;
      expect(article.sourceName, 'Agência Saúde');
      expect(article.title, contains('vacinação'));
      expect(article.publishedAt, isNotNull);
    });

    test('accepts optional null fields', () {
      final article = NewsArticle.fromJson({
        'source': null,
        'title': 'Vacinação atualizada',
        'url': 'https://example.com/valid',
        'description': null,
      })!;
      expect(article.sourceName, 'Fonte externa');
      expect(article.description, isNull);
      expect(article.imageUrl, isNull);
    });

    test('rejects missing title, removed title, and invalid URL', () {
      expect(NewsArticle.fromJson({'url': 'https://example.com'}), isNull);
      expect(
        NewsArticle.fromJson({
          'title': '[Removed]',
          'url': 'https://example.com',
        }),
        isNull,
      );
      expect(
        NewsArticle.fromJson({
          'title': 'Notícia',
          'url': 'javascript:alert(1)',
        }),
        isNull,
      );
    });
  });

  group('NewsApiService', () {
    test('parses a valid response and encodes query parameters', () async {
      late Uri requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        expect(request.headers['X-Api-Key'], 'test-key');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'status': 'ok',
              'totalResults': 1,
              'articles': [articleJson],
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final response = await NewsApiService(
        client: client,
        apiKey: 'test-key',
      ).fetch(page: 1, searchTerm: 'febre amarela');
      expect(response.articles, hasLength(1));
      expect(requestedUri.host, 'newsapi.org');
      expect(requestedUri.queryParameters['q'], contains('febre amarela'));
      expect(requestedUri.queryParameters['pageSize'], '20');
    });

    test('parses an empty response', () async {
      final response = await serviceReturning(200, {
        'status': 'ok',
        'totalResults': 0,
        'articles': [],
      }).fetch(page: 1);
      expect(response.articles, isEmpty);
    });

    for (final entry in {
      401: NewsErrorType.apiKeyInvalid,
      429: NewsErrorType.rateLimited,
      500: NewsErrorType.server,
    }.entries) {
      test('maps HTTP ${entry.key}', () async {
        expect(
          () => serviceReturning(entry.key, {}).fetch(page: 1),
          throwsA(
            isA<NewsException>().having((e) => e.type, 'type', entry.value),
          ),
        );
      });
    }

    test('maps timeout', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('{}', 200);
      });
      final service = NewsApiService(
        client: client,
        apiKey: 'test-key',
        timeout: const Duration(milliseconds: 1),
      );
      expect(
        () => service.fetch(page: 1),
        throwsA(
          isA<NewsException>().having(
            (e) => e.type,
            'type',
            NewsErrorType.timeout,
          ),
        ),
      );
    });

    test('maps network exception', () async {
      final client = MockClient((_) async => throw http.ClientException('off'));
      expect(
        () => NewsApiService(client: client, apiKey: 'test-key').fetch(page: 1),
        throwsA(
          isA<NewsException>().having(
            (e) => e.type,
            'type',
            NewsErrorType.network,
          ),
        ),
      );
    });

    test('does not request when API key is absent', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      });
      expect(
        () => NewsApiService(client: client, apiKey: '').fetch(page: 1),
        throwsA(
          isA<NewsException>().having(
            (e) => e.type,
            'type',
            NewsErrorType.apiKeyMissing,
          ),
        ),
      );
      expect(calls, 0);
    });
  });

  test('repository caches the same query and page in memory', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response(
        jsonEncode({'status': 'ok', 'totalResults': 0, 'articles': []}),
        200,
      );
    });
    final repository = ApiNewsRepository(
      service: NewsApiService(client: client, apiKey: 'test-key'),
    );
    await repository.getNews(query: '', page: 1);
    await repository.getNews(query: '', page: 1);
    expect(calls, 1);
    await repository.getNews(query: '', page: 1, forceRefresh: true);
    expect(calls, 2);
  });

  group('NewsController', () {
    test('reports loading then success', () async {
      final repository = FakeNewsRepository();
      final controller = NewsController(repository: repository);
      final operation = controller.loadInitialNews();
      expect(controller.state, NewsState.loading);
      repository.complete(nextResponse([article('1')]));
      await operation;
      expect(controller.state, NewsState.success);
      expect(controller.articles, hasLength(1));
    });

    test('search normalizes query', () async {
      final repository = ImmediateRepository(nextResponse([article('1')]));
      final controller = NewsController(repository: repository);
      await controller.searchNews('  febre   amarela ');
      expect(controller.currentQuery, 'febre amarela');
      expect(repository.lastQuery, 'febre amarela');
    });

    test('pagination removes duplicate URLs', () async {
      final repository = QueueRepository([
        nextResponse(List.generate(20, (i) => article('$i')), total: 40),
        nextResponse([article('0'), article('20')], total: 40),
      ]);
      final controller = NewsController(repository: repository);
      await controller.loadInitialNews();
      await controller.loadMore();
      expect(controller.currentPage, 2);
      expect(controller.articles, hasLength(21));
    });

    test('reports empty and error states', () async {
      final empty = NewsController(
        repository: ImmediateRepository(nextResponse([])),
      );
      await empty.loadInitialNews();
      expect(empty.state, NewsState.empty);

      final failed = NewsController(repository: ErrorRepository());
      await failed.loadInitialNews();
      expect(failed.state, NewsState.error);
      expect(failed.errorMessage, contains('Sem conexão'));
    });
  });
}

NewsApiService serviceReturning(int statusCode, Map<String, dynamic> body) =>
    NewsApiService(
      apiKey: 'test-key',
      client: MockClient(
        (_) async => http.Response(jsonEncode(body), statusCode),
      ),
    );

NewsArticle article(String id) => NewsArticle(
  sourceName: 'Fonte',
  title: 'Notícia $id',
  url: 'https://example.com/$id',
);

NewsResponse nextResponse(List<NewsArticle> articles, {int? total}) =>
    NewsResponse(articles: articles, totalResults: total ?? articles.length);

class FakeNewsRepository implements NewsRepository {
  final _completer = Completer<NewsResponse>();
  void complete(NewsResponse response) => _completer.complete(response);
  @override
  Future<NewsResponse> getNews({
    required String query,
    required int page,
    bool forceRefresh = false,
  }) => _completer.future;
  @override
  void dispose() {}
}

class ImmediateRepository implements NewsRepository {
  ImmediateRepository(this.response);
  final NewsResponse response;
  String? lastQuery;
  @override
  Future<NewsResponse> getNews({
    required String query,
    required int page,
    bool forceRefresh = false,
  }) async {
    lastQuery = query;
    return response;
  }

  @override
  void dispose() {}
}

class QueueRepository implements NewsRepository {
  QueueRepository(this.responses);
  final List<NewsResponse> responses;
  @override
  Future<NewsResponse> getNews({
    required String query,
    required int page,
    bool forceRefresh = false,
  }) async => responses.removeAt(0);
  @override
  void dispose() {}
}

class ErrorRepository implements NewsRepository {
  @override
  Future<NewsResponse> getNews({
    required String query,
    required int page,
    bool forceRefresh = false,
  }) => throw const NewsException(NewsErrorType.network);
  @override
  void dispose() {}
}
