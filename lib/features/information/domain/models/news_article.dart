class NewsArticle {
  const NewsArticle({
    required this.sourceName,
    required this.title,
    required this.url,
    this.author,
    this.description,
    this.imageUrl,
    this.publishedAt,
    this.content,
  });

  final String sourceName;
  final String? author;
  final String title;
  final String? description;
  final String url;
  final String? imageUrl;
  final DateTime? publishedAt;
  final String? content;

  NewsArticle withSourceName(String name) => NewsArticle(
    sourceName: name,
    title: title,
    url: url,
    author: author,
    description: description,
    imageUrl: imageUrl,
    publishedAt: publishedAt,
    content: content,
  );

  static NewsArticle? fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String?)?.trim() ?? '';
    final url = (json['url'] as String?)?.trim() ?? '';
    final uri = Uri.tryParse(url);
    if (title.isEmpty || title == '[Removed]' || !_isWebUri(uri)) return null;

    final source = json['source'];
    final sourceName = source is Map<String, dynamic>
        ? (source['name'] as String?)?.trim()
        : null;
    String? optional(String key) {
      final value = (json[key] as String?)?.trim();
      return value == null || value.isEmpty ? null : value;
    }

    return NewsArticle(
      sourceName: sourceName?.isNotEmpty == true
          ? sourceName!
          : 'Fonte externa',
      author: optional('author'),
      title: title,
      description: optional('description'),
      url: url,
      imageUrl: optional('urlToImage'),
      publishedAt: DateTime.tryParse(optional('publishedAt') ?? '')?.toLocal(),
      content: optional('content'),
    );
  }

  static bool _isWebUri(Uri? uri) =>
      uri != null && uri.hasAuthority && {'http', 'https'}.contains(uri.scheme);
}
