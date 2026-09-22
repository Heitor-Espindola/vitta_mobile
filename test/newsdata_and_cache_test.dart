import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:vitta_mobile/core/errors/news_exception.dart';
import 'package:vitta_mobile/features/information/data/news_api_service.dart';
import 'package:vitta_mobile/features/information/data/news_repository.dart';
import 'package:vitta_mobile/features/information/data/newsdata_api_service.dart';

void main() {
  late SharedPreferencesAsync storage;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    storage = SharedPreferencesAsync();
  });

  test(
    'NewsData.io maps its result without mixing provider field names',
    () async {
      late Uri requestedUri;
      final service = NewsDataApiService(
        apiKey: 'newsdata-test-key',
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'status': 'success',
                'totalResults': 1,
                'nextPage': 'next-token',
                'results': [
                  {
                    'article_id': 'one',
                    'title': 'Campanha de vacinação infantil começa hoje',
                    'link':
                        'https://www.gov.br/saude/pt-br/assuntos/noticias/teste',
                    'description': 'Vacinas estão disponíveis nos postos.',
                    'image_url': 'https://example.com/vacina.jpg',
                    'pubDate': '2026-09-20 12:30:00',
                    'source_name': 'Portal Saúde',
                    'creator': ['Equipe Saúde'],
                  },
                ],
              }),
            ),
            200,
          );
        }),
      );

      final response = await service.fetch(page: 1);

      expect(requestedUri.host, 'newsdata.io');
      expect(requestedUri.path, '/api/1/latest');
      expect(requestedUri.queryParameters['apikey'], 'newsdata-test-key');
      expect(requestedUri.queryParameters['language'], 'pt');
      expect(requestedUri.queryParameters['country'], 'br');
      expect(requestedUri.queryParameters['category'], 'health');
      expect(response.articles, hasLength(1));
      expect(response.articles.single.sourceName, 'Ministério da Saúde');
      expect(response.articles.single.author, 'Equipe Saúde');
    },
  );

  test('NewsData.io uses the returned cursor on the next page', () async {
    final requestedUris = <Uri>[];
    final service = NewsDataApiService(
      apiKey: 'newsdata-test-key',
      client: MockClient((request) async {
        requestedUris.add(request.url);
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'status': 'success',
              'totalResults': 20,
              if (requestedUris.length == 1) 'nextPage': 'opaque-cursor',
              'results': const <Map<String, dynamic>>[],
            }),
          ),
          200,
        );
      }),
    );

    await service.fetchRaw(page: 1);
    await service.fetchRaw(page: 2);

    expect(requestedUris, hasLength(2));
    expect(requestedUris.first.queryParameters['page'], isNull);
    expect(requestedUris.last.queryParameters['page'], 'opaque-cursor');
    service.dispose();
  });

  test('NewsData.io distinguishes invalid key and credit limit', () async {
    Future<NewsErrorType> errorFor(int statusCode) async {
      final service = NewsDataApiService(
        apiKey: 'newsdata-test-key',
        client: MockClient((_) async => http.Response('{}', statusCode)),
      );
      try {
        await service.fetchRaw(page: 1);
        fail('Expected NewsException');
      } on NewsException catch (error) {
        return error.type;
      } finally {
        service.dispose();
      }
    }

    expect(await errorFor(401), NewsErrorType.apiKeyInvalid);
    expect(await errorFor(429), NewsErrorType.rateLimited);
  });

  test('NewsData.io maps timeout and network failures', () async {
    final timeoutService = NewsDataApiService(
      apiKey: 'newsdata-test-key',
      timeout: Duration.zero,
      client: MockClient(
        (_) async => Future<http.Response>.delayed(
          const Duration(milliseconds: 10),
          () => http.Response('{}', 200),
        ),
      ),
    );
    await expectLater(
      timeoutService.fetchRaw(page: 1),
      throwsA(
        isA<NewsException>().having(
          (error) => error.type,
          'type',
          NewsErrorType.timeout,
        ),
      ),
    );
    timeoutService.dispose();

    final networkService = NewsDataApiService(
      apiKey: 'newsdata-test-key',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      networkService.fetchRaw(page: 1),
      throwsA(
        isA<NewsException>().having(
          (error) => error.type,
          'type',
          NewsErrorType.network,
        ),
      ),
    );
    networkService.dispose();
  });

  test('NewsData.io rejects malformed responses', () async {
    final service = NewsDataApiService(
      apiKey: 'newsdata-test-key',
      client: MockClient((_) async => http.Response('not-json', 200)),
    );

    await expectLater(
      service.fetchRaw(page: 1),
      throwsA(
        isA<NewsException>().having(
          (error) => error.type,
          'type',
          NewsErrorType.invalidResponse,
        ),
      ),
    );
    service.dispose();
  });

  test('last successful feed survives a later provider failure', () async {
    final successRepository = ApiNewsRepository(
      storage: storage,
      service: NewsApiService(
        apiKey: 'newsapi-test-key',
        client: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'status': 'ok',
                'totalResults': 1,
                'articles': [
                  {
                    'source': {'name': 'Saúde'},
                    'title': 'Nova campanha de vacinação infantil',
                    'description': 'A vacinação será ampliada.',
                    'url':
                        'https://www.gov.br/saude/pt-br/assuntos/noticias/cache',
                    'publishedAt': '2026-09-20T12:00:00Z',
                  },
                ],
              }),
            ),
            200,
          ),
        ),
      ),
      newsDataService: NewsDataApiService(apiKey: ''),
    );
    final fresh = await successRepository.getNews(
      query: '',
      page: 1,
      forceRefresh: true,
    );
    expect(fresh.articles, hasLength(1));
    successRepository.dispose();

    final failingRepository = ApiNewsRepository(
      storage: storage,
      service: NewsApiService(
        apiKey: 'newsapi-test-key',
        client: MockClient((_) async => http.Response('{}', 500)),
      ),
      newsDataService: NewsDataApiService(apiKey: ''),
    );
    final cached = await failingRepository.getNews(
      query: '',
      page: 1,
      forceRefresh: true,
    );

    expect(cached.articles, hasLength(1));
    expect(cached.articles.single.title, 'Nova campanha de vacinação infantil');
    failingRepository.dispose();
  });
}
