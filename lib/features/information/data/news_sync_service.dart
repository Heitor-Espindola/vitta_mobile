import 'package:vitta_mobile/core/errors/news_exception.dart';
import 'package:vitta_mobile/features/information/domain/models/news_article.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_provider.dart';
import 'package:vitta_mobile/features/information/domain/services/news_article_identity.dart';
import 'package:vitta_mobile/features/information/domain/services/news_relevance_filter.dart';
import 'package:vitta_mobile/features/information/domain/services/trusted_news_sources.dart';

abstract interface class NewsArticleStore {
  Future<int> upsertAll(List<NewsArticle> articles);
}

class NewsSyncReport {
  NewsSyncReport();

  final Map<String, int> returnedByProvider = {};
  final Map<String, String> providerErrors = {};
  int normalized = 0;
  int discardedBySource = 0;
  int discardedByRelevance = 0;
  int discardedByAge = 0;
  int duplicates = 0;
  int persisted = 0;

  Map<String, dynamic> toJson() => {
    'returnedByProvider': returnedByProvider,
    'providerErrors': providerErrors,
    'normalized': normalized,
    'discardedBySource': discardedBySource,
    'discardedByRelevance': discardedByRelevance,
    'discardedByAge': discardedByAge,
    'duplicates': duplicates,
    'persisted': persisted,
  };
}

class NewsSyncException implements Exception {
  const NewsSyncException(this.report);
  final NewsSyncReport report;
}

class NewsSyncService {
  NewsSyncService({
    required List<NewsProvider> providers,
    required NewsArticleStore store,
    DateTime Function()? now,
  }) : _providers = providers,
       _store = store,
       _now = now ?? DateTime.now;

  static const retention = Duration(days: 30);
  final List<NewsProvider> _providers;
  final NewsArticleStore _store;
  final DateTime Function() _now;

  Future<NewsSyncReport> synchronize({int maxPagesPerProvider = 3}) async {
    final report = NewsSyncReport();
    final candidates = <NewsArticle>[];
    var successfulProviders = 0;

    for (final provider in _providers) {
      if (!provider.isConfigured) {
        report.providerErrors[provider.providerName] =
            NewsErrorType.apiKeyMissing.name;
        continue;
      }
      try {
        for (var page = 1; page <= maxPagesPerProvider; page++) {
          final response = await provider.fetchRaw(
            page: page,
            pageSize: provider.pageSizeHint,
            searchTerm: '',
          );
          report.returnedByProvider.update(
            provider.providerName,
            (value) =>
                value + (response.fetchedCount ?? response.articles.length),
            ifAbsent: () => response.fetchedCount ?? response.articles.length,
          );
          report.normalized += response.articles.length;
          candidates.addAll(response.articles);
          final fetched = response.fetchedCount ?? response.articles.length;
          if (fetched < provider.pageSizeHint) break;
        }
        successfulProviders++;
      } on NewsException catch (error) {
        report.providerErrors[provider.providerName] = error.type.name;
      } catch (error) {
        report.providerErrors[provider.providerName] = error.runtimeType
            .toString();
      }
    }

    if (successfulProviders == 0) throw NewsSyncException(report);

    final now = _now().toUtc();
    final cutoff = now.subtract(retention);
    final byUrl = <String, NewsArticle>{};
    final keyToUrl = <String, String>{};

    for (final candidate in candidates) {
      final trustedName = TrustedNewsSources.nameForUrl(candidate.url);
      if (trustedName == null) {
        report.discardedBySource++;
        continue;
      }
      if (!NewsRelevanceFilter.isRelevant(candidate)) {
        report.discardedByRelevance++;
        continue;
      }
      final publishedAt = candidate.publishedAt?.toUtc();
      if (publishedAt == null || publishedAt.isBefore(cutoff)) {
        report.discardedByAge++;
        continue;
      }

      final normalizedUrl = NewsArticleIdentity.normalizeUrl(candidate.url);
      final domain = NewsArticleIdentity.sourceDomain(normalizedUrl);
      final secondaryKey = NewsArticleIdentity.titleSourceKey(
        candidate.title,
        domain,
      );
      final existingUrl = byUrl.containsKey(normalizedUrl)
          ? normalizedUrl
          : keyToUrl[secondaryKey];
      final normalized = candidate.copyWith(
        id: NewsArticleIdentity.stableId(normalizedUrl),
        sourceName: trustedName,
        sourceDomain: domain,
        url: normalizedUrl,
        publishedAt: publishedAt,
        fetchedAt: now,
        expiresAt: publishedAt.add(retention),
        providers: candidate.effectiveProviders,
      );

      if (existingUrl == null) {
        byUrl[normalizedUrl] = normalized;
        keyToUrl[secondaryKey] = normalizedUrl;
        continue;
      }

      report.duplicates++;
      final existing = byUrl[existingUrl]!;
      final providers = <String>{
        ...existing.effectiveProviders,
        ...normalized.effectiveProviders,
      }.toList()..sort();
      byUrl[existingUrl] = existing.copyWith(
        providers: providers,
        description: _prefer(existing.description, normalized.description),
        imageUrl: _prefer(existing.imageUrl, normalized.imageUrl),
      );
    }

    final articles = byUrl.values.toList()
      ..sort((a, b) => b.publishedAt!.compareTo(a.publishedAt!));
    report.persisted = await _store.upsertAll(articles);
    return report;
  }

  static String? _prefer(String? first, String? second) {
    if (first == null || first.trim().isEmpty) return second;
    if (second == null || second.trim().isEmpty) return first;
    return second.length > first.length ? second : first;
  }

  void dispose() {
    for (final provider in _providers) {
      provider.dispose();
    }
  }
}
