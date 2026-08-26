import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitta_mobile/features/information/domain/models/news_article.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class NewsArticleCard extends StatelessWidget {
  const NewsArticleCard({
    required this.article,
    this.horizontal = false,
    super.key,
  });
  final NewsArticle article;
  final bool horizontal;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(article.url);
    final valid =
        uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    if (!valid || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir esta notícia.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => horizontal
      ? SizedBox(
          width: 238,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _open(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ArticleImage(url: article.imageUrl, width: 238, height: 104),
                  Padding(
                    padding: const EdgeInsets.all(11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${article.sourceName} · ${formatNewsDate(article.publishedAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: vittaDarkBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Ler notícia',
                          style: TextStyle(
                            color: vittaDarkBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      : Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: vittaLineBlue),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _open(context),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${article.sourceName} · ${formatNewsDate(article.publishedAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: vittaBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          article.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (article.description != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            article.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, height: 1.3),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Text(
                              'Ler notícia',
                              style: TextStyle(
                                color: vittaDarkBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new,
                              size: 13,
                              color: vittaDarkBlue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ArticleImage(url: article.imageUrl),
                ],
              ),
            ),
          ),
        );
}

class _ArticleImage extends StatelessWidget {
  const _ArticleImage({this.url, this.width = 92, this.height = 92});
  final String? url;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: const Color(0xFFE8F2F8),
      alignment: Alignment.center,
      child: const Icon(Icons.newspaper, color: vittaDarkBlue, size: 30),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : placeholder,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

String formatNewsDate(DateTime? date, {DateTime? now}) {
  if (date == null) return 'Data não informada';
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final value = DateTime(date.year, date.month, date.day);
  if (value == today) {
    return 'Hoje, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  if (value == today.subtract(const Duration(days: 1))) return 'Ontem';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
