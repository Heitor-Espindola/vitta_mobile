import 'package:flutter/foundation.dart';
import 'package:vitta_mobile/core/errors/news_exception.dart';
import 'package:vitta_mobile/features/information/domain/models/news_article.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_repository.dart';

enum NewsState { initial, loading, success, empty, error, loadingMore }

class NewsController extends ChangeNotifier {
  NewsController({required NewsRepository repository})
    : _repository = repository;
  final NewsRepository _repository;

  List<NewsArticle> articles = [];
  String? errorMessage;
  NewsState state = NewsState.initial;
  bool hasMore = true;
  int currentPage = 0;
  String currentQuery = '';

  bool get isLoading => state == NewsState.loading;
  bool get isLoadingMore => state == NewsState.loadingMore;

  Future<void> loadInitialNews() => _load(reset: true);

  Future<void> searchNews(String term) async {
    final normalized = term.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return;
    currentQuery = normalized;
    await _load(reset: true);
  }

  Future<void> clearSearch() async {
    currentQuery = '';
    await _load(reset: true);
  }

  Future<void> refreshNews() => _load(reset: true, forceRefresh: true);
  Future<void> retry() => _load(reset: articles.isEmpty, forceRefresh: true);

  Future<void> loadMore() async {
    if (!hasMore || isLoading || isLoadingMore) return;
    await _load(reset: false);
  }

  Future<void> _load({required bool reset, bool forceRefresh = false}) async {
    if (isLoading || isLoadingMore) return;
    state = reset ? NewsState.loading : NewsState.loadingMore;
    errorMessage = null;
    if (reset) {
      currentPage = 0;
      hasMore = true;
    }
    notifyListeners();
    try {
      final nextPage = currentPage + 1;
      final response = await _repository.getNews(
        query: currentQuery,
        page: nextPage,
        forceRefresh: forceRefresh,
      );
      final combined = reset ? <NewsArticle>[] : [...articles];
      final knownUrls = combined.map((article) => article.url).toSet();
      for (final article in response.articles) {
        if (knownUrls.add(article.url)) combined.add(article);
      }
      articles = combined;
      currentPage = nextPage;
      hasMore =
          response.articles.length >= 20 &&
          currentPage * 20 < response.totalResults;
      state = articles.isEmpty ? NewsState.empty : NewsState.success;
    } on NewsException catch (error) {
      errorMessage = error.userMessage;
      state = NewsState.error;
    } catch (error) {
      debugPrint('Falha técnica ao carregar notícias: ${error.runtimeType}');
      errorMessage = 'Não foi possível carregar as notícias no momento.';
      state = NewsState.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
