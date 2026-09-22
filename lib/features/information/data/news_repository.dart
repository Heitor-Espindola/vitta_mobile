import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitta_mobile/core/errors/news_exception.dart';
import 'package:vitta_mobile/features/information/domain/models/news_article.dart';

import '../domain/models/news_response.dart';
import '../domain/repositories/news_repository.dart';
import 'news_api_service.dart';
import 'newsdata_api_service.dart';

class ApiNewsRepository implements NewsRepository {
  ApiNewsRepository({
    NewsApiService? service,
    NewsDataApiService? newsDataService,
    SharedPreferencesAsync? storage,
  }) : _service = service ?? NewsApiService(),
       _newsDataService = newsDataService ?? NewsDataApiService(),
       _storage = storage;
  final NewsApiService _service;
  final NewsDataApiService _newsDataService;
  final SharedPreferencesAsync? _storage;
  static final Map<String, _CacheEntry> _cache = {};
  static const cacheDuration = Duration(minutes: 5);
  static const _persistentFeedKey = 'cached_vaccination_news_v1';

  @override
  Future<NewsResponse> getNews({
    required String query,
    required int page,
    bool forceRefresh = false,
  }) async {
    final key = '$query|$page';
    final cached = _cache[key];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.loadedAt) < cacheDuration) {
      return cached.response;
    }
    final canUsePersistentFeed = query.trim().isEmpty && page == 1;
    try {
      final response = await _fetchFromProviders(query: query, page: page);
      if (canUsePersistentFeed && response.articles.isEmpty) {
        final persistent = await _readPersistentFeed();
        if (persistent != null) return persistent;
      }
      _cache[key] = _CacheEntry(response, DateTime.now());
      if (canUsePersistentFeed && response.articles.isNotEmpty) {
        await _savePersistentFeed(response);
      }
      return response;
    } on NewsException {
      if (canUsePersistentFeed) {
        final persistent = await _readPersistentFeed();
        if (persistent != null) return persistent;
      }
      rethrow;
    }
  }

  Future<NewsResponse> _fetchFromProviders({
    required String query,
    required int page,
  }) async {
    NewsResponse? newsApiResponse;
    NewsResponse? newsDataResponse;
    NewsException? firstError;
    try {
      newsApiResponse = await _service.fetch(page: page, searchTerm: query);
    } on NewsException catch (error) {
      firstError = error;
    }
    if (_newsDataService.isConfigured) {
      try {
        newsDataResponse = await _newsDataService.fetch(
          page: page,
          searchTerm: query,
        );
      } on NewsException catch (error) {
        firstError ??= error;
      }
    }
    if (newsApiResponse == null && newsDataResponse == null) {
      throw firstError ?? const NewsException(NewsErrorType.invalidResponse);
    }
    return _merge(newsApiResponse, newsDataResponse);
  }

  static NewsResponse _merge(NewsResponse? first, NewsResponse? second) {
    final articles = <NewsArticle>[];
    final urls = <String>{};
    for (final response in [first, second]) {
      if (response == null) continue;
      for (final article in response.articles) {
        if (urls.add(article.url)) articles.add(article);
      }
    }
    articles.sort((a, b) {
      if (a.publishedAt == null) return b.publishedAt == null ? 0 : 1;
      if (b.publishedAt == null) return -1;
      return b.publishedAt!.compareTo(a.publishedAt!);
    });
    return NewsResponse(
      articles: articles,
      totalResults: (first?.totalResults ?? 0) + (second?.totalResults ?? 0),
      fetchedCount: (first?.fetchedCount ?? 0) + (second?.fetchedCount ?? 0),
    );
  }

  SharedPreferencesAsync? get _preferences {
    if (_storage != null) return _storage;
    try {
      return SharedPreferencesAsync();
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePersistentFeed(NewsResponse response) async {
    try {
      final value = jsonEncode(
        response.articles
            .take(30)
            .map((article) => article.toCacheJson())
            .toList(),
      );
      await _preferences?.setString(_persistentFeedKey, value);
    } catch (_) {
      // A falha do cache local não deve impedir a exibição da resposta remota.
    }
  }

  Future<NewsResponse?> _readPersistentFeed() async {
    try {
      final value = await _preferences?.getString(_persistentFeedKey);
      if (value == null || value.isEmpty) return null;
      final decoded = jsonDecode(value);
      if (decoded is! List) return null;
      final articles = decoded
          .whereType<Map<String, dynamic>>()
          .map(NewsArticle.fromCacheJson)
          .whereType<NewsArticle>()
          .toList();
      if (articles.isEmpty) return null;
      return NewsResponse(
        articles: articles,
        totalResults: articles.length,
        fetchedCount: articles.length,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _service.dispose();
    _newsDataService.dispose();
  }
}

class _CacheEntry {
  const _CacheEntry(this.response, this.loadedAt);
  final NewsResponse response;
  final DateTime loadedAt;
}
