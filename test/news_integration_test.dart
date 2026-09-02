import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vitta_mobile/core/errors/news_exception.dart';
import 'package:vitta_mobile/features/information/data/news_api_service.dart';
import 'package:vitta_mobile/features/information/data/news_repository.dart';
import 'package:vitta_mobile/features/information/domain/models/news_article.dart';
import 'package:vitta_mobile/features/information/domain/models/news_response.dart';
import 'package:vitta_mobile/features/information/domain/models/news_category.dart';
import 'package:vitta_mobile/features/information/domain/services/news_relevance_filter.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_repository.dart';
import 'package:vitta_mobile/features/information/presentation/controllers/news_controller.dart';
import 'package:vitta_mobile/features/information/presentation/information_screen.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/news_article_card.dart';

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
    test('accepts vaccine news and rejects unrelated politics', () {
      expect(
        NewsRelevanceFilter.isRelevant(
          const NewsArticle(
            sourceName: 'Fonte',
            title: 'Campanha de vacinação começa hoje',
            url: 'https://example.com/vacina',
          ),
        ),
        isTrue,
      );
      expect(
        NewsRelevanceFilter.isRelevant(
          const NewsArticle(
            sourceName: 'Fonte',
            title: 'Saúde e bem-estar ganham destaque nesta semana',
            description: 'A programação também menciona uma vacina.',
            url: 'https://example.com/saude-generica',
          ),
        ),
        isFalse,
      );
      expect(
        NewsRelevanceFilter.isRelevant(
          const NewsArticle(
            sourceName: 'Fonte',
            title: 'Congresso debate nova proposta partidária',
            description: 'O texto cita vacinação apenas de forma lateral.',
            url: 'https://example.com/politica-com-mencao',
          ),
        ),
        isFalse,
      );
      expect(
        NewsRelevanceFilter.isRelevant(
          const NewsArticle(
            sourceName: 'Fonte',
            title: 'Congresso debate campanha de vacinação infantil',
            url: 'https://example.com/vacinacao-no-congresso',
          ),
        ),
        isTrue,
      );
      expect(
        NewsRelevanceFilter.isRelevant(
          const NewsArticle(
            sourceName: 'Fonte',
            title: 'Congresso debate nova proposta política',
            description: 'Votação acontece nesta semana.',
            url: 'https://example.com/politica',
          ),
        ),
        isFalse,
      );
    });

    test('categories use vaccine-specific queries', () {
      expect(NewsCategory.hpv.query, contains('HPV'));
      expect(NewsCategory.influenza.query, contains('influenza'));
    });

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
        now: () => DateTime.utc(2026, 8, 31),
      ).fetch(page: 1, searchTerm: 'febre amarela');
      expect(response.articles, hasLength(1));
      expect(requestedUri.host, 'newsapi.org');
      expect(requestedUri.queryParameters['q'], contains('febre amarela'));
      expect(requestedUri.queryParameters['pageSize'], '20');
      expect(requestedUri.queryParameters['searchIn'], 'title,description');
      expect(requestedUri.queryParameters['from'], '2026-08-01');
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

    test('combines search with category and clearing keeps category', () async {
      final repository = RecordingRepository(nextResponse([article('1')]));
      final controller = NewsController(repository: repository);

      await controller.selectCategory(NewsCategory.hpv);
      await controller.searchNews('adolescente');

      expect(controller.selectedCategory, NewsCategory.hpv);
      expect(repository.queries.last, contains(NewsCategory.hpv.query));
      expect(repository.queries.last, contains('"adolescente"'));

      await controller.clearSearch();
      expect(controller.selectedCategory, NewsCategory.hpv);
      expect(controller.currentQuery, isEmpty);
      expect(repository.queries.last, NewsCategory.hpv.query);
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

  testWidgets('Conteúdos renders news returned by the repository', (
    tester,
  ) async {
    final repository = ImmediateRepository(
      NewsResponse(
        articles: [
          const NewsArticle(
            sourceName: 'Agência Saúde',
            title: 'Campanha nacional de vacinação',
            description: 'Postos de saúde ampliam o atendimento.',
            url: 'https://example.com/campanha',
          ),
        ],
        totalResults: 1,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: InformationScreen(newsRepository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notícias recentes'), findsOneWidget);
    expect(find.text('Agência Saúde · Data não informada'), findsOneWidget);
    expect(find.text('Campanha nacional de vacinação'), findsOneWidget);
    expect(find.text('Ler notícia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Conteúdo keeps category above search and clears only the term', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = ImmediateRepository(nextResponse([article('layout')]));
    await tester.pumpWidget(
      MaterialApp(home: InformationScreen(newsRepository: repository)),
    );
    await tester.pumpAndSettle();

    final category = find.byKey(const Key('news-category-forYou'));
    final search = find.byKey(const ValueKey('collapsed-search'));
    expect(
      tester.getTopLeft(category).dy,
      lessThan(tester.getTopLeft(search).dy),
    );
    expect(tester.getTopLeft(search).dx, lessThan(40));
    expect(
      tester.getSize(find.byKey(const Key('information-header-band'))).width,
      412,
    );

    await tester.tap(find.byKey(const Key('news-category-children')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Pesquisar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('expandable-search-field')),
      'vacinação infantil',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Limpar: vacinação infantil'), findsOneWidget);
    await tester.tap(find.text('Limpar: vacinação infantil'));
    await tester.pumpAndSettle();

    final selectedChip = tester.widget<ChoiceChip>(
      find.byKey(const Key('news-category-children')),
    );
    expect(selectedChip.selected, isTrue);
    expect(find.text('Limpar: vacinação infantil'), findsNothing);
  });

  testWidgets('educational cards open content and trigger related search', (
    tester,
  ) async {
    final repository = ImmediateRepository(nextResponse([article('1')]));
    await tester.pumpWidget(
      MaterialApp(home: InformationScreen(newsRepository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('educational-content-0')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('A vacinação na infância ajuda'),
      findsOneWidget,
    );
    expect(find.text('Buscar notícias relacionadas'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('search-related-news')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('search-related-news')));
    await tester.pumpAndSettle();
    expect(repository.lastQuery, 'vacinação infantil');
    expect(find.text('Limpar: vacinação infantil'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('educational-content-1')));
    await tester.tap(find.byKey(const Key('educational-content-1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pesquisas em imunização'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('educational-content-2')));
    await tester.tap(find.byKey(const Key('educational-content-2')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Informações confiáveis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty category explains state and returns to all news', (
    tester,
  ) async {
    final repository = CallbackRepository((query) {
      if (query == NewsCategory.children.query) return nextResponse([]);
      return nextResponse([article('feed')]);
    });
    await tester.pumpWidget(
      MaterialApp(home: InformationScreen(newsRepository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('news-category-children')));
    await tester.pumpAndSettle();
    expect(find.text('Sem novidades por aqui'), findsOneWidget);
    expect(
      find.text('Não encontramos notícias recentes sobre este tema.'),
      findsOneWidget,
    );

    await tester.drag(
      find
          .byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.vertical,
          )
          .first,
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('empty-show-all-news')));
    await tester.pumpAndSettle();
    expect(repository.queries.last, '');
    expect(find.text('Notícia feed'), findsOneWidget);
  });

  testWidgets('empty search has its own state and can be cleared', (
    tester,
  ) async {
    final repository = CallbackRepository(
      (query) =>
          query.isEmpty ? nextResponse([article('feed')]) : nextResponse([]),
    );
    await tester.pumpWidget(
      MaterialApp(home: InformationScreen(newsRepository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Pesquisar').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('expandable-search-field')),
      'termo inexistente',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.drag(
      find
          .byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.vertical,
          )
          .first,
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum resultado encontrado'), findsOneWidget);
    expect(find.text('Tente outro termo ou limpe a pesquisa.'), findsOneWidget);
    await tester.tap(find.text('Limpar busca'));
    await tester.pumpAndSettle();
    expect(find.text('Notícia feed'), findsOneWidget);
  });

  testWidgets('both Ver todos actions open useful listings', (tester) async {
    final repository = ImmediateRepository(nextResponse([article('1')]));
    await tester.pumpWidget(
      MaterialApp(home: InformationScreen(newsRepository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('show-all-educational-content')),
    );
    await tester.tap(find.byKey(const Key('show-all-educational-content')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Orientações gerais sobre vacinação'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('show-all-news')));
    await tester.tap(find.byKey(const Key('show-all-news')));
    await tester.pumpAndSettle();
    expect(find.text('Notícias e atualizações'), findsOneWidget);
    expect(find.text('Notícia 1'), findsOneWidget);
  });

  testWidgets('API error keeps educational content visible and retry works', (
    tester,
  ) async {
    final repository = FlakyRepository();
    await tester.pumpWidget(
      MaterialApp(home: InformationScreen(newsRepository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conteúdos educativos'), findsOneWidget);
    expect(find.text('Sem conexão. Verifique sua internet.'), findsOneWidget);
    await tester.drag(
      find
          .byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.vertical,
          )
          .first,
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Notícia recuperada'), findsOneWidget);
  });

  testWidgets('invalid article URL shows a friendly message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NewsArticleCard(
            article: NewsArticle(
              sourceName: 'Fonte',
              title: 'Vacinação sem URL válida',
              url: 'url-invalida',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Vacinação sem URL válida'));
    await tester.pump();
    expect(find.text('Não foi possível abrir esta notícia.'), findsOneWidget);
  });

  test('formats news dates in Brazilian Portuguese', () {
    expect(
      formatNewsDate(DateTime(2026, 8, 31), now: DateTime(2026, 9, 5)),
      '31 ago. 2026',
    );
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

class RecordingRepository implements NewsRepository {
  RecordingRepository(this.response);
  final NewsResponse response;
  final List<String> queries = [];

  @override
  Future<NewsResponse> getNews({
    required String query,
    required int page,
    bool forceRefresh = false,
  }) async {
    queries.add(query);
    return response;
  }

  @override
  void dispose() {}
}

class CallbackRepository implements NewsRepository {
  CallbackRepository(this.callback);
  final NewsResponse Function(String query) callback;
  final List<String> queries = [];

  @override
  Future<NewsResponse> getNews({
    required String query,
    required int page,
    bool forceRefresh = false,
  }) async {
    queries.add(query);
    return callback(query);
  }

  @override
  void dispose() {}
}

class FlakyRepository implements NewsRepository {
  int calls = 0;

  @override
  Future<NewsResponse> getNews({
    required String query,
    required int page,
    bool forceRefresh = false,
  }) async {
    calls++;
    if (calls == 1) throw const NewsException(NewsErrorType.network);
    return nextResponse([article('recuperada')]);
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
