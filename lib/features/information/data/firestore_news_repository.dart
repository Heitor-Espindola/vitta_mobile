import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitta_mobile/core/errors/news_exception.dart';
import 'package:vitta_mobile/features/information/domain/models/news_article.dart';
import 'package:vitta_mobile/features/information/domain/models/news_response.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_repository.dart';
import 'package:vitta_mobile/features/information/domain/services/news_relevance_filter.dart';
import 'package:vitta_mobile/features/information/domain/services/trusted_news_sources.dart';

abstract interface class PersistedNewsSource {
  Future<List<NewsArticle>> fetchPublishedSince(DateTime cutoff, {int limit});
}

class FirestorePersistedNewsSource implements PersistedNewsSource {
  FirestorePersistedNewsSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<NewsArticle>> fetchPublishedSince(
    DateTime cutoff, {
    int limit = 100,
  }) async {
    final snapshot = await _firestore
        .collection('news_articles')
        .where(
          'publishedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff.toUtc()),
        )
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => NewsArticle.fromFirestore(doc.id, doc.data()))
        .whereType<NewsArticle>()
        .toList(growable: false);
  }
}

class FirestoreNewsRepository implements NewsRepository {
  FirestoreNewsRepository({
    PersistedNewsSource? source,
    SharedPreferencesAsync? storage,
    DateTime Function()? now,
  }) : _source = source ?? FirestorePersistedNewsSource(),
       _storage = storage,
       _now = now ?? DateTime.now;

  static const cacheDuration = Duration(minutes: 5);
  static const retention = Duration(days: 30);
  static const pageSize = 20;
  static const maxArticlesPerRefresh = 100;
  static const _persistentFeedKey = 'cached_firestore_vaccination_news_v2';

  final PersistedNewsSource _source;
  final SharedPreferencesAsync? _storage;
  final DateTime Function() _now;
  List<NewsArticle>? _memoryArticles;
  DateTime? _loadedAt;

  @override
  Future<NewsResponse> getNews({
    required String query,
    required int page,
    bool forceRefresh = false,
  }) async {
    final now = _now().toUtc();
    final cacheFresh =
        _loadedAt != null &&
        now.difference(_loadedAt!) < cacheDuration &&
        _memoryArticles != null;
    if (forceRefresh || !cacheFresh) {
      try {
        final loaded = await _source.fetchPublishedSince(
          now.subtract(retention),
          limit: maxArticlesPerRefresh,
        );
        _memoryArticles = _sanitize(loaded, now);
        _loadedAt = now;
        await _savePersistentFeed(_memoryArticles!);
      } on FirebaseException catch (error) {
        final cached = await _readPersistentFeed(now);
        if (cached == null) {
          throw NewsException(
            error.code == 'unavailable'
                ? NewsErrorType.network
                : NewsErrorType.server,
          );
        }
        _memoryArticles = cached;
        _loadedAt = now;
      } catch (_) {
        final cached = await _readPersistentFeed(now);
        if (cached == null) {
          throw const NewsException(NewsErrorType.network);
        }
        _memoryArticles = cached;
        _loadedAt = now;
      }
    }

    final normalizedQuery = NewsRelevanceFilter.normalize(query);
    final filtered = normalizedQuery.isEmpty
        ? [...?_memoryArticles]
        : _memoryArticles!
              .where((article) {
                final searchable = NewsRelevanceFilter.normalize(
                  '${article.title} ${article.description ?? ''} ${article.sourceName}',
                );
                return searchable.contains(normalizedQuery);
              })
              .toList(growable: false);
    final start = (page - 1) * pageSize;
    final articles = start >= filtered.length
        ? const <NewsArticle>[]
        : filtered.sublist(start, (start + pageSize).clamp(0, filtered.length));
    return NewsResponse(
      articles: articles,
      totalResults: filtered.length,
      fetchedCount: articles.length,
    );
  }

  static List<NewsArticle> _sanitize(
    Iterable<NewsArticle> articles,
    DateTime now,
  ) {
    final cutoff = now.subtract(retention);
    final byId = <String, NewsArticle>{};
    for (final article in articles) {
      final publishedAt = article.publishedAt?.toUtc();
      if (publishedAt == null || publishedAt.isBefore(cutoff)) continue;
      final trustedName = TrustedNewsSources.nameForUrl(article.url);
      if (trustedName == null || !NewsRelevanceFilter.isRelevant(article)) {
        continue;
      }
      byId[article.id ?? article.url] = article.withSourceName(trustedName);
    }
    final values = byId.values.toList()
      ..sort((a, b) => b.publishedAt!.compareTo(a.publishedAt!));
    return values;
  }

  SharedPreferencesAsync? get _preferences {
    if (_storage != null) return _storage;
    try {
      return SharedPreferencesAsync();
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePersistentFeed(List<NewsArticle> articles) async {
    try {
      await _preferences?.setString(
        _persistentFeedKey,
        jsonEncode(articles.map((article) => article.toCacheJson()).toList()),
      );
    } catch (_) {
      // Local cache failures never hide a valid Firestore response.
    }
  }

  Future<List<NewsArticle>?> _readPersistentFeed(DateTime now) async {
    try {
      final value = await _preferences?.getString(_persistentFeedKey);
      if (value == null || value.isEmpty) return null;
      final decoded = jsonDecode(value);
      if (decoded is! List) return null;
      final articles = decoded
          .whereType<Map<String, dynamic>>()
          .map(NewsArticle.fromCacheJson)
          .whereType<NewsArticle>();
      final sanitized = _sanitize(articles, now);
      return sanitized.isEmpty ? null : sanitized;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {}
}
