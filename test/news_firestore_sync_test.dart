import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:vitta_mobile/core/errors/news_exception.dart';
import 'package:vitta_mobile/features/information/data/firestore_news_repository.dart';
import 'package:vitta_mobile/features/information/data/news_sync_service.dart';
import 'package:vitta_mobile/features/information/domain/models/news_article.dart';
import 'package:vitta_mobile/features/information/domain/models/news_response.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_provider.dart';
import 'package:vitta_mobile/features/information/domain/services/news_article_identity.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/news_article_card.dart';

void main() {
  final now = DateTime.utc(2026, 9, 22, 12);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('NewsArticle normalization', () {
    test('maps NewsData fields to the common NewsArticle model', () {
      final article = NewsArticle.fromNewsDataJson({
        'article_id': 'newsdata-id',
        'title': 'Campanha de vacinação contra influenza',
        'description': 'Imunização começa nesta semana.',
        'link': 'https://www.gov.br/saude/pt-br/noticias/influenza',
        'image_url': 'https://example.com/image.jpg',
        'source_name': 'Portal Saúde',
        'pubDate': '2026-09-21 10:00:00',
        'language': 'portuguese',
        'country': ['brazil'],
      })!;

      expect(article.id, 'newsdata-id');
      expect(article.provider, 'newsdata');
      expect(article.sourceDomain, 'www.gov.br');
      expect(article.title, contains('vacinação'));
      expect(article.publishedAt, isNotNull);
    });

    test('maps Firestore Timestamp values without provider coupling', () {
      final publishedAt = DateTime.utc(2026, 9, 21, 10);
      final article = NewsArticle.fromFirestore('document-id', {
        'title': 'Campanha de vacinação contra influenza',
        'url': 'https://www.gov.br/saude/pt-br/noticias/influenza',
        'sourceName': 'Ministério da Saúde',
        'publishedAt': Timestamp.fromDate(publishedAt),
        'expiresAt': Timestamp.fromDate(
          publishedAt.add(const Duration(days: 30)),
        ),
      });

      expect(article, isNotNull);
      expect(article!.publishedAt?.toUtc(), publishedAt);
      expect(
        article.expiresAt?.toUtc(),
        publishedAt.add(const Duration(days: 30)),
      );
    });

    test('normalizes tracking URLs into one deterministic SHA-256 id', () {
      const first =
          'https://g1.globo.com/saude/vacina/?utm_source=x&fbclid=abc';
      const second = 'https://g1.globo.com/saude/vacina';
      expect(
        NewsArticleIdentity.normalizeUrl(first),
        NewsArticleIdentity.normalizeUrl(second),
      );
      expect(
        NewsArticleIdentity.stableId(first),
        NewsArticleIdentity.stableId(second),
      );
      expect(NewsArticleIdentity.stableId(first), hasLength(64));
    });
  });

  group('NewsSyncService', () {
    test(
      'combines two providers and deduplicates the normalized URL',
      () async {
        final store = _FakeStore();
        final first = _article(
          provider: 'newsapi',
          url: 'https://www.gov.br/saude/pt-br/noticias/vacina?utm_source=api',
          date: now.subtract(const Duration(days: 1)),
        );
        final second = _article(
          provider: 'newsdata',
          url: 'https://www.gov.br/saude/pt-br/noticias/vacina',
          date: now.subtract(const Duration(days: 1)),
        );
        final report = await NewsSyncService(
          providers: [
            _FakeProvider('newsapi', [first]),
            _FakeProvider('newsdata', [second]),
          ],
          store: store,
          now: () => now,
        ).synchronize(maxPagesPerProvider: 1);

        expect(report.duplicates, 1);
        expect(store.articles, hasLength(1));
        expect(store.articles.single.effectiveProviders, [
          'newsapi',
          'newsdata',
        ]);
      },
    );

    test('deduplicates equal title and source with different URLs', () async {
      final store = _FakeStore();
      final result = await NewsSyncService(
        providers: [
          _FakeProvider('newsapi', [
            _article(
              provider: 'newsapi',
              url: 'https://g1.globo.com/saude/noticia/a',
              date: now,
            ),
          ]),
          _FakeProvider('newsdata', [
            _article(
              provider: 'newsdata',
              url: 'https://g1.globo.com/saude/noticia/a-amp',
              date: now,
            ),
          ]),
        ],
        store: store,
        now: () => now,
      ).synchronize(maxPagesPerProvider: 1);

      expect(result.duplicates, 1);
      expect(store.articles, hasLength(1));
    });

    test('rejects untrusted sources and unrelated Ebola coverage', () async {
      final store = _FakeStore();
      final report = await NewsSyncService(
        providers: [
          _FakeProvider('newsapi', [
            _article(
              provider: 'newsapi',
              url: 'https://untrusted.example/vacina',
              date: now,
            ),
            _article(
              provider: 'newsapi',
              url: 'https://www.gov.br/saude/pt-br/noticias/ebola',
              title: 'Surto de Ebola cresce na região',
              description: 'Uma vacina é citada no fim da matéria.',
              date: now,
            ),
          ]),
        ],
        store: store,
        now: () => now,
      ).synchronize(maxPagesPerProvider: 1);

      expect(report.discardedBySource, 1);
      expect(report.discardedByRelevance, 1);
      expect(store.articles, isEmpty);
    });

    test('uses publishedAt plus 30 days and drops older articles', () async {
      final store = _FakeStore();
      final within = _article(
        provider: 'newsapi',
        url: 'https://www.gov.br/saude/pt-br/noticias/within',
        date: now.subtract(const Duration(days: 30)),
      );
      final old = _article(
        provider: 'newsapi',
        url: 'https://www.gov.br/saude/pt-br/noticias/old',
        date: now.subtract(const Duration(days: 30, seconds: 1)),
      );
      final report = await NewsSyncService(
        providers: [
          _FakeProvider('newsapi', [within, old]),
        ],
        store: store,
        now: () => now,
      ).synchronize(maxPagesPerProvider: 1);

      expect(report.discardedByAge, 1);
      expect(store.articles, hasLength(1));
      expect(
        store.articles.single.expiresAt,
        within.publishedAt!.add(const Duration(days: 30)),
      );
    });

    test('continues when NewsAPI fails and NewsData succeeds', () async {
      final store = _FakeStore();
      final report = await NewsSyncService(
        providers: [
          _FakeProvider.error('newsapi'),
          _FakeProvider('newsdata', [
            _article(provider: 'newsdata', date: now),
          ]),
        ],
        store: store,
        now: () => now,
      ).synchronize(maxPagesPerProvider: 1);
      expect(report.providerErrors, contains('newsapi'));
      expect(store.articles, hasLength(1));
    });

    test('continues when NewsData fails and NewsAPI succeeds', () async {
      final store = _FakeStore();
      final report = await NewsSyncService(
        providers: [
          _FakeProvider('newsapi', [_article(provider: 'newsapi', date: now)]),
          _FakeProvider.error('newsdata'),
        ],
        store: store,
        now: () => now,
      ).synchronize(maxPagesPerProvider: 1);
      expect(report.providerErrors, contains('newsdata'));
      expect(store.articles, hasLength(1));
    });

    test('both providers failing never calls the persistent store', () async {
      final store = _FakeStore();
      final service = NewsSyncService(
        providers: [
          _FakeProvider.error('newsapi'),
          _FakeProvider.error('newsdata'),
        ],
        store: store,
        now: () => now,
      );
      await expectLater(
        service.synchronize(maxPagesPerProvider: 1),
        throwsA(isA<NewsSyncException>()),
      );
      expect(store.calls, 0);
    });
  });

  group('FirestoreNewsRepository', () {
    test(
      'returns a friendly empty result when Firestore has no articles',
      () async {
        final repository = FirestoreNewsRepository(
          source: _FakeSource([]),
          storage: SharedPreferencesAsync(),
          now: () => now,
        );
        final result = await repository.getNews(query: '', page: 1);
        expect(result.articles, isEmpty);
        expect(result.totalResults, 0);
      },
    );

    test('keeps only 30-day articles and orders newest first', () async {
      final repository = FirestoreNewsRepository(
        source: _FakeSource([
          _article(
            provider: 'newsapi',
            date: now.subtract(const Duration(days: 31)),
            url: 'https://www.gov.br/saude/pt-br/noticias/old-firestore',
          ),
          _article(
            provider: 'newsapi',
            date: now.subtract(const Duration(days: 2)),
            url: 'https://www.gov.br/saude/pt-br/noticias/two',
          ),
          _article(
            provider: 'newsdata',
            date: now.subtract(const Duration(days: 1)),
            url: 'https://www.gov.br/saude/pt-br/noticias/one',
          ),
        ]),
        storage: SharedPreferencesAsync(),
        now: () => now,
      );
      final result = await repository.getNews(query: '', page: 1);
      expect(result.articles, hasLength(2));
      expect(result.articles.first.url, endsWith('/one'));
    });

    test(
      'searches title, description, and journalistic source locally',
      () async {
        final repository = FirestoreNewsRepository(
          source: _FakeSource([
            _article(
              provider: 'newsapi',
              title: 'Vacinação infantil ampliada',
              description: 'Postos atendem aos sábados.',
              date: now,
            ),
          ]),
          storage: SharedPreferencesAsync(),
          now: () => now,
        );
        expect(
          (await repository.getNews(query: 'infantil', page: 1)).articles,
          hasLength(1),
        );
        expect(
          (await repository.getNews(query: 'Ministério', page: 1)).articles,
          hasLength(1),
        );
        expect(
          (await repository.getNews(query: 'economia', page: 1)).articles,
          isEmpty,
        );
      },
    );

    testWidgets('provider metadata is never rendered as the source', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewsArticleCard(
              article: _article(
                provider: 'newsdata',
                date: now,
              ).copyWith(sourceName: 'Fiocruz'),
            ),
          ),
        ),
      );
      expect(find.textContaining('Fiocruz'), findsOneWidget);
      expect(find.textContaining('newsdata'), findsNothing);
      expect(find.textContaining('newsapi'), findsNothing);
    });
  });
}

NewsArticle _article({
  required String provider,
  DateTime? date,
  String title = 'Campanha de vacinação infantil',
  String description = 'A imunização será ampliada.',
  String url = 'https://www.gov.br/saude/pt-br/noticias/vacina',
}) => NewsArticle(
  id: NewsArticleIdentity.stableId(url),
  sourceName: 'Ministério da Saúde',
  sourceDomain: NewsArticleIdentity.sourceDomain(url),
  provider: provider,
  providers: [provider],
  title: title,
  description: description,
  url: url,
  publishedAt: date,
);

class _FakeProvider implements NewsProvider {
  _FakeProvider(this.providerName, this.articles) : error = null;
  _FakeProvider.error(this.providerName)
    : articles = const [],
      error = const NewsException(NewsErrorType.server);

  @override
  final String providerName;
  final List<NewsArticle> articles;
  final NewsException? error;

  @override
  bool get isConfigured => true;

  @override
  int get pageSizeHint => 20;

  @override
  Future<NewsResponse> fetchRaw({
    required int page,
    int pageSize = 20,
    String searchTerm = '',
  }) async {
    if (error != null) throw error!;
    return NewsResponse(
      articles: articles,
      totalResults: articles.length,
      fetchedCount: articles.length,
    );
  }

  @override
  void dispose() {}
}

class _FakeStore implements NewsArticleStore {
  List<NewsArticle> articles = [];
  int calls = 0;

  @override
  Future<int> upsertAll(List<NewsArticle> values) async {
    calls++;
    articles = [...values];
    return values.length;
  }
}

class _FakeSource implements PersistedNewsSource {
  const _FakeSource(this.articles);
  final List<NewsArticle> articles;

  @override
  Future<List<NewsArticle>> fetchPublishedSince(
    DateTime cutoff, {
    int limit = 100,
  }) async => articles.take(limit).toList(growable: false);
}
