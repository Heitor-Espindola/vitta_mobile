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
import 'package:vitta_mobile/features/information/domain/services/news_relevance_filter.dart';
import 'package:vitta_mobile/features/information/domain/services/trusted_news_sources.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_repository.dart';
import 'package:vitta_mobile/features/information/presentation/all_educational_content_screen.dart';
import 'package:vitta_mobile/features/information/presentation/all_news_screen.dart';
import 'package:vitta_mobile/features/information/presentation/controllers/news_controller.dart';
import 'package:vitta_mobile/features/information/presentation/information_screen.dart';
import 'package:vitta_mobile/features/information/presentation/models/educational_content.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/news_article_card.dart';

const articleJson = {
  'source': {'name': 'Agência Saúde'},
  'author': 'Autora',
  'title': 'Campanha de vacinação começa hoje',
  'description': 'Postos estão preparados para atender a população.',
  'url': 'https://www.gov.br/saude/pt-br/assuntos/noticias/noticia-1',
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
      expect(
        NewsRelevanceFilter.isRelevant(
          const NewsArticle(
            sourceName: 'Fonte',
            title: 'Epidemia de Ebola alastra-se pela região',
            description: 'O texto também cita uma vacina em estudo.',
            url: 'https://www.gov.br/saude/pt-br/ebola',
          ),
        ),
        isFalse,
      );
      expect(
        NewsRelevanceFilter.isRelevant(
          const NewsArticle(
            sourceName: 'Fonte',
            title: 'Nova ação começa nesta semana',
            description: 'Campanha de vacinação infantil amplia atendimento.',
            url: 'https://www.gov.br/saude/pt-br/campanha',
          ),
        ),
        isTrue,
      );
    });

    test('allowlist uses exact URL hosts, not the API source label', () {
      expect(
        TrustedNewsSources.nameForUrl('https://www.gov.br/saude/pt-br/abc'),
        'Ministério da Saúde',
      );
      expect(
        TrustedNewsSources.nameForUrl('https://agencia.fiocruz.br/noticia'),
        'Fiocruz',
      );
      expect(
        TrustedNewsSources.nameForUrl('https://www.butantan.gov.br/noticias/x'),
        'Instituto Butantan',
      );
      expect(
        TrustedNewsSources.nameForUrl('https://www.paho.org/pt/noticias/x'),
        'OPAS',
      );
      expect(
        TrustedNewsSources.nameForUrl('https://www.gov.br/economia/noticias/x'),
        isNull,
      );
      expect(
        TrustedNewsSources.nameForUrl('https://fiocruz.br.evil.com/x'),
        isNull,
      );
      expect(TrustedNewsSources.nameForUrl('http://fiocruz.br/x'), isNull);
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
      expect(response.articles.single.sourceName, 'Ministério da Saúde');
      expect(requestedUri.host, 'newsapi.org');
      expect(requestedUri.queryParameters['q'], contains('febre amarela'));
      expect(requestedUri.queryParameters['pageSize'], '20');
      expect(requestedUri.queryParameters['searchIn'], 'title,description');
      expect(requestedUri.queryParameters['sortBy'], 'publishedAt');
      expect(requestedUri.queryParameters['domains'], contains('fiocruz.br'));
      expect(requestedUri.queryParameters['from'], '2026-06-02');
    });

    test(
      'retries within the plan window after NewsAPI rejects older dates',
      () async {
        final requestedDates = <String?>[];
        final client = MockClient((request) async {
          requestedDates.add(request.url.queryParameters['from']);
          if (requestedDates.length == 1) {
            return http.Response(
              jsonEncode({
                'status': 'error',
                'code': 'parameterInvalid',
                'message':
                    'You are trying to request results too far in the past.',
              }),
              426,
            );
          }
          return http.Response(
            jsonEncode({'status': 'ok', 'totalResults': 0, 'articles': []}),
            200,
          );
        });
        final service = NewsApiService(
          client: client,
          apiKey: 'test-key',
          now: () => DateTime.utc(2026, 9, 16),
        );
        final result = await service.fetch(page: 1);
        expect(result.articles, isEmpty);
        expect(requestedDates, ['2026-06-18', '2026-08-18']);
        await service.fetch(page: 2);
        expect(requestedDates.last, '2026-08-18');
        expect(requestedDates, hasLength(3));
      },
    );

    test('does not retry unrelated invalid NewsAPI parameters', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode({
            'status': 'error',
            'code': 'parameterInvalid',
            'message': 'Another parameter is invalid.',
          }),
          426,
        );
      });
      final service = NewsApiService(client: client, apiKey: 'test-key');
      await expectLater(service.fetch(page: 1), throwsA(isA<NewsException>()));
      expect(calls, 1);
    });

    test(
      'allows only trusted, vaccination-focused articles and deduplicates URLs',
      () async {
        Map<String, dynamic> item(String title, String url, String date) => {
          ...articleJson,
          'title': title,
          'url': url,
          'publishedAt': date,
          'source': {'name': 'Fiocruz'},
        };
        final trusted = 'https://www.gov.br/saude/pt-br/noticias/vacina';
        final response = await serviceReturning(200, {
          'status': 'ok',
          'totalResults': 7,
          'articles': [
            item('Campanha de vacinação', trusted, '2026-08-01T10:00:00Z'),
            item(
              'Nova vacina contra HPV',
              'https://agenciabrasil.ebc.com.br/saude/1',
              '2026-08-10T10:00:00Z',
            ),
            item(
              'Vacinação no município',
              'https://qualquer-site.com/saude/1',
              '2026-08-11T10:00:00Z',
            ),
            item(
              'Epidemia de Ebola alastra-se',
              'https://www.gov.br/saude/pt-br/ebola',
              '2026-08-12T10:00:00Z',
            ),
            item(
              'Saúde e economia em debate',
              'https://www.butantan.gov.br/noticias/saude',
              '2026-08-13T10:00:00Z',
            ),
            item(
              'Congresso vota reforma partidária',
              'https://www.gov.br/saude/pt-br/politica',
              '2026-08-14T10:00:00Z',
            ),
            item('Campanha de vacinação', trusted, '2026-08-01T10:00:00Z'),
          ],
        }).fetch(page: 1);
        expect(response.fetchedCount, 7);
        expect(response.articles.map((article) => article.sourceName), [
          'Agência Brasil',
          'Ministério da Saúde',
        ]);
        expect(response.articles.first.title, 'Nova vacina contra HPV');
      },
    );

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

    test('clearing search restores the single editorial feed', () async {
      final repository = RecordingRepository(nextResponse([article('1')]));
      final controller = NewsController(repository: repository);
      await controller.searchNews('adolescente');
      expect(repository.queries.last, 'adolescente');

      await controller.clearSearch();
      expect(controller.currentQuery, isEmpty);
      expect(repository.queries.last, '');
    });

    test(
      'submitting an empty search also restores the complete feed',
      () async {
        final repository = RecordingRepository(nextResponse([article('1')]));
        final controller = NewsController(repository: repository);
        await controller.searchNews('influenza');
        await controller.searchNews('   ');
        expect(controller.currentQuery, isEmpty);
        expect(repository.queries, ['influenza', '']);
      },
    );

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

    test(
      'pagination uses raw API count after editorial filtering and orders newest first',
      () async {
        final older = NewsArticle(
          sourceName: 'Fiocruz',
          title: 'Vacinação de rotina',
          url: 'https://fiocruz.br/older',
          publishedAt: DateTime(2026, 7, 1),
        );
        final newer = NewsArticle(
          sourceName: 'Fiocruz',
          title: 'Vacina infantil',
          url: 'https://fiocruz.br/newer',
          publishedAt: DateTime(2026, 8, 1),
        );
        final controller = NewsController(
          repository: QueueRepository([
            NewsResponse(articles: [older], totalResults: 40, fetchedCount: 20),
            NewsResponse(articles: [newer], totalResults: 40, fetchedCount: 20),
          ]),
        );
        await controller.loadInitialNews();
        expect(controller.hasMore, isTrue);
        await controller.loadMore();
        expect(controller.articles, [newer, older]);
        expect(controller.hasMore, isFalse);
      },
    );

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

    expect(find.text('Notícias e atualizações'), findsOneWidget);
    expect(find.text('Agência Saúde · Data não informada'), findsOneWidget);
    expect(find.text('Campanha nacional de vacinação'), findsOneWidget);
    expect(find.text('Ler notícia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Conteúdo hides category filters and keeps functional search', (
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

    final search = find.byKey(const ValueKey('collapsed-search'));
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Para você'), findsNothing);
    expect(find.text('Campanhas'), findsNothing);
    expect(tester.getTopLeft(search).dx, lessThan(40));
    expect(
      tester.getSize(find.byKey(const Key('information-header-band'))).width,
      412,
    );

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

    expect(find.text('Limpar: vacinação infantil'), findsNothing);
    expect(repository.lastQuery, '');
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

  testWidgets('Conteúdo includes additional life-stage guides', (tester) async {
    final repository = ImmediateRepository(nextResponse([article('1')]));
    await tester.pumpWidget(
      MaterialApp(home: InformationScreen(newsRepository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find
          .byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.vertical,
          )
          .first,
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
    expect(find.text('Guias para cada fase'), findsOneWidget);
    expect(find.text('Vacinação na Gestação'), findsOneWidget);
    expect(
      educationalContents.map((content) => content.title),
      containsAll([
        'Vacinação na Gestação',
        'Vacinação na Adolescência',
        'Vacinação da Pessoa Idosa',
        'Vacinação e Viagens',
      ]),
    );
    await tester.ensureVisible(find.byKey(const Key('life-stage-content-0')));
    await tester.tap(find.byKey(const Key('life-stage-content-0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('protege a pessoa gestante'), findsWidgets);
    expect(tester.takeException(), isNull);
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

    expect(find.text('Nenhuma notícia encontrada'), findsOneWidget);
    expect(find.text('Tente outro termo ou limpe a pesquisa.'), findsOneWidget);
    await tester.tap(find.text('Limpar pesquisa'));
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
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Para você'), findsNothing);
    expect(find.text('HPV'), findsNothing);
    expect(find.text('Gestantes'), findsNothing);
  });

  testWidgets('full content lists respect a 48px Android navigation bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    final repository = ImmediateRepository(nextResponse([article('1')]));
    final controller = NewsController(repository: repository);
    addTearDown(controller.dispose);
    await controller.loadInitialNews();

    await tester.pumpWidget(
      const MaterialApp(home: AllEducationalContentScreen()),
    );
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.byType(ListView)).dy, 520);

    await tester.pumpWidget(
      MaterialApp(home: AllNewsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.byType(ListView)).dy, 520);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full news search clears back to the unfiltered feed', (
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
    await tester.ensureVisible(find.byKey(const Key('show-all-news')));
    await tester.tap(find.byKey(const Key('show-all-news')));
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNothing);
    await tester.tap(find.byTooltip('Pesquisar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('expandable-search-field')),
      'termo inexistente',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma notícia encontrada'), findsOneWidget);
    await tester.tap(find.text('Limpar pesquisa'));
    await tester.pumpAndSettle();
    expect(find.text('Notícia feed'), findsOneWidget);
    expect(repository.queries.last, '');
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('empty API keeps educational content and shows the global state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InformationScreen(
          newsRepository: ImmediateRepository(nextResponse([])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conteúdos educativos'), findsOneWidget);
    expect(find.text('Novas atualizações em breve'), findsOneWidget);
    expect(
      find.text(
        'Enquanto isso, consulte nossos conteúdos educativos e os canais oficiais de saúde.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sem novidades por aqui'), findsNothing);
  });

  testWidgets('Conteúdo features no more than five stories', (tester) async {
    final repository = ImmediateRepository(
      nextResponse(List.generate(8, (index) => article('$index'))),
    );
    await tester.pumpWidget(
      MaterialApp(home: InformationScreen(newsRepository: repository)),
    );
    await tester.pumpAndSettle();
    final featured = tester.widget<ListView>(
      find.byKey(const Key('featured-news-list')),
    );
    // ListView.separated counts the four separators alongside five articles.
    expect(featured.childrenDelegate.estimatedChildCount, 9);
    expect(find.byKey(const Key('show-all-news')), findsOneWidget);
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
    expect(formatNewsDate(DateTime(2026, 8, 31)), '31 ago. 2026');
    expect(formatNewsDate(DateTime.now()), contains('${DateTime.now().year}'));
  });
}

NewsApiService serviceReturning(int statusCode, Map<String, dynamic> body) =>
    NewsApiService(
      apiKey: 'test-key',
      client: MockClient(
        (_) async =>
            http.Response.bytes(utf8.encode(jsonEncode(body)), statusCode),
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
