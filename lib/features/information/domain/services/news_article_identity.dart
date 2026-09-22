import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'news_relevance_filter.dart';

abstract final class NewsArticleIdentity {
  static const _trackingParameters = {
    'fbclid',
    'gclid',
    'dclid',
    'msclkid',
    'ref',
    'referrer',
    'source',
  };

  static String normalizeUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasAuthority) return value.trim();
    final entries = uri.queryParametersAll.entries.where((entry) {
      final key = entry.key.toLowerCase();
      return !key.startsWith('utm_') &&
          !key.startsWith('mc_') &&
          !_trackingParameters.contains(key);
    }).toList()..sort((a, b) => a.key.compareTo(b.key));
    final query = <String, dynamic>{};
    for (final entry in entries) {
      query[entry.key] = entry.value.length == 1
          ? entry.value.first
          : entry.value;
    }
    var path = uri.path.isEmpty ? '/' : uri.path;
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return Uri(
      scheme: uri.scheme.toLowerCase(),
      userInfo: uri.userInfo,
      host: uri.host.toLowerCase(),
      port: uri.hasPort ? uri.port : null,
      path: path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  static String stableId(String url) =>
      sha256.convert(utf8.encode(normalizeUrl(url))).toString();

  static String sourceDomain(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  static String titleSourceKey(String title, String sourceDomain) {
    final normalizedTitle = NewsRelevanceFilter.normalize(title)
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '$normalizedTitle|${sourceDomain.toLowerCase()}';
  }

  static String dedupeKey(String title, String sourceDomain) => sha256
      .convert(utf8.encode(titleSourceKey(title, sourceDomain)))
      .toString();
}
