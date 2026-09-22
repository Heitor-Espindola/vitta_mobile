class NewsArticle {
  const NewsArticle({
    required this.sourceName,
    required this.title,
    required this.url,
    this.id,
    this.sourceDomain,
    this.provider = 'newsapi',
    this.providers = const [],
    this.language = 'pt',
    this.country = 'br',
    this.author,
    this.description,
    this.imageUrl,
    this.publishedAt,
    this.fetchedAt,
    this.expiresAt,
    this.content,
  });

  final String? id;
  final String sourceName;
  final String? sourceDomain;
  final String provider;
  final List<String> providers;
  final String language;
  final String country;
  final String? author;
  final String title;
  final String? description;
  final String url;
  final String? imageUrl;
  final DateTime? publishedAt;
  final DateTime? fetchedAt;
  final DateTime? expiresAt;

  /// Kept only for backward-compatible parsing of provider responses. The
  /// administrative sync never writes full article content to Firestore.
  final String? content;

  List<String> get effectiveProviders {
    final values = <String>{
      ...providers.where((value) => value.trim().isNotEmpty),
      if (provider.trim().isNotEmpty) provider,
    };
    final sorted = values.toList()..sort();
    return sorted;
  }

  NewsArticle copyWith({
    String? id,
    String? sourceName,
    String? sourceDomain,
    String? provider,
    List<String>? providers,
    String? language,
    String? country,
    String? author,
    String? title,
    String? description,
    String? url,
    String? imageUrl,
    DateTime? publishedAt,
    DateTime? fetchedAt,
    DateTime? expiresAt,
    String? content,
  }) => NewsArticle(
    id: id ?? this.id,
    sourceName: sourceName ?? this.sourceName,
    sourceDomain: sourceDomain ?? this.sourceDomain,
    provider: provider ?? this.provider,
    providers: providers ?? this.providers,
    language: language ?? this.language,
    country: country ?? this.country,
    author: author ?? this.author,
    title: title ?? this.title,
    description: description ?? this.description,
    url: url ?? this.url,
    imageUrl: imageUrl ?? this.imageUrl,
    publishedAt: publishedAt ?? this.publishedAt,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    content: content ?? this.content,
  );

  NewsArticle withSourceName(String name) => copyWith(sourceName: name);

  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'sourceName': sourceName,
    'sourceDomain': sourceDomain,
    'provider': provider,
    'providers': effectiveProviders,
    'language': language,
    'country': country,
    'author': author,
    'title': title,
    'description': description,
    'url': url,
    'imageUrl': imageUrl,
    'publishedAt': publishedAt?.toIso8601String(),
    'fetchedAt': fetchedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
  };

  static NewsArticle? fromCacheJson(Map<String, dynamic> json) {
    final title = _string(json['title']) ?? '';
    final url = _string(json['url']) ?? '';
    if (title.isEmpty || !_isWebUri(Uri.tryParse(url))) return null;
    return NewsArticle(
      id: _string(json['id']),
      sourceName: _string(json['sourceName']) ?? 'Fonte externa',
      sourceDomain: _string(json['sourceDomain']),
      provider: _string(json['provider']) ?? 'firestore',
      providers: _strings(json['providers']),
      language: _string(json['language']) ?? 'pt',
      country: _string(json['country']) ?? 'br',
      author: _string(json['author']),
      title: title,
      description: _string(json['description']),
      url: url,
      imageUrl: _string(json['imageUrl']),
      publishedAt: DateTime.tryParse(
        _string(json['publishedAt']) ?? '',
      )?.toLocal(),
      fetchedAt: DateTime.tryParse(_string(json['fetchedAt']) ?? '')?.toLocal(),
      expiresAt: DateTime.tryParse(_string(json['expiresAt']) ?? '')?.toLocal(),
    );
  }

  static NewsArticle? fromFirestore(
    String documentId,
    Map<String, dynamic> json,
  ) {
    final title = _string(json['title']) ?? '';
    final url = _string(json['url']) ?? '';
    if (title.isEmpty || !_isWebUri(Uri.tryParse(url))) return null;
    return NewsArticle(
      id: documentId,
      sourceName: _string(json['sourceName']) ?? 'Fonte externa',
      sourceDomain: _string(json['sourceDomain']),
      provider: _string(json['provider']) ?? 'firestore',
      providers: _strings(json['providers']),
      language: _string(json['language']) ?? 'pt',
      country: _string(json['country']) ?? 'br',
      title: title,
      description: _string(json['description']),
      url: url,
      imageUrl: _string(json['imageUrl']),
      publishedAt: _dateTime(json['publishedAt']),
      fetchedAt: _dateTime(json['fetchedAt']),
      expiresAt: _dateTime(json['expiresAt']),
    );
  }

  /// Parses the normalized NewsAPI representation.
  static NewsArticle? fromJson(Map<String, dynamic> json) {
    final title = _string(json['title']) ?? '';
    final url = _string(json['url']) ?? '';
    final uri = Uri.tryParse(url);
    if (title.isEmpty || title == '[Removed]' || !_isWebUri(uri)) return null;
    final source = json['source'];
    final sourceName = source is Map<String, dynamic>
        ? _string(source['name'])
        : null;
    return NewsArticle(
      sourceName: sourceName ?? 'Fonte externa',
      sourceDomain: uri!.host.toLowerCase(),
      provider: 'newsapi',
      providers: const ['newsapi'],
      language: 'pt',
      country: 'br',
      author: _string(json['author']),
      title: title,
      description: _string(json['description']),
      url: url,
      imageUrl: _string(json['urlToImage']),
      publishedAt: DateTime.tryParse(
        _string(json['publishedAt']) ?? '',
      )?.toLocal(),
      content: _string(json['content']),
    );
  }

  /// Parses a NewsData.io result without leaking provider-specific field names
  /// to repositories or presentation code.
  static NewsArticle? fromNewsDataJson(Map<String, dynamic> json) {
    final title = _string(json['title']);
    final url = _string(json['link']);
    final uri = Uri.tryParse(url ?? '');
    if (title == null || url == null || !_isWebUri(uri)) return null;
    final creators = json['creator'];
    final author = creators is List
        ? creators
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .join(', ')
        : null;
    final rawCountry = json['country'];
    final countries = rawCountry is List
        ? rawCountry.whereType<String>().toList(growable: false)
        : const <String>[];
    return NewsArticle(
      id: _string(json['article_id']),
      sourceName:
          _string(json['source_name']) ??
          _string(json['source_id']) ??
          'Fonte externa',
      sourceDomain: uri!.host.toLowerCase(),
      provider: 'newsdata',
      providers: const ['newsdata'],
      language: _string(json['language']) ?? 'pt',
      country:
          (countries.isNotEmpty ? countries.first : _string(rawCountry)) ??
          'br',
      author: author?.isEmpty == true ? null : author,
      title: title,
      description: _string(json['description']),
      url: url,
      imageUrl: _string(json['image_url']),
      publishedAt: DateTime.tryParse(_string(json['pubDate']) ?? '')?.toLocal(),
      content: _string(json['content']),
    );
  }

  static DateTime? _dateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Firestore Timestamp is intentionally handled without importing the
    // plugin in this domain model, so admin CLI tooling stays pure Dart.
    try {
      final converted = (value as dynamic).toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Unsupported persisted value.
    }
    return null;
  }

  static String? _string(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static List<String> _strings(Object? value) => value is List
      ? value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
      : const [];

  static bool _isWebUri(Uri? uri) =>
      uri != null && uri.hasAuthority && {'http', 'https'}.contains(uri.scheme);
}
