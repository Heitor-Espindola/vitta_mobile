import '../domain/models/news_response.dart';
import '../domain/repositories/news_repository.dart';
import 'news_api_service.dart';

class ApiNewsRepository implements NewsRepository {
  ApiNewsRepository({NewsApiService? service})
    : _service = service ?? NewsApiService();
  final NewsApiService _service;
  static final Map<String, _CacheEntry> _cache = {};
  static const cacheDuration = Duration(minutes: 5);

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
    final response = await _service.fetch(page: page, searchTerm: query);
    _cache[key] = _CacheEntry(response, DateTime.now());
    return response;
  }

  @override
  void dispose() => _service.dispose();
}

class _CacheEntry {
  const _CacheEntry(this.response, this.loadedAt);
  final NewsResponse response;
  final DateTime loadedAt;
}
