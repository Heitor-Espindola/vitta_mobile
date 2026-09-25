import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/features/information/domain/models/news_article.dart';

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
                          style: TextStyle(
                            color: context.appPrimaryInk,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (article.description != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            article.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, height: 1.25),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          'Ler notícia',
                          style: TextStyle(
                            color: context.appPrimaryInk,
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
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.appBorder),
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
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
                        Row(
                          children: [
                            Text(
                              'Ler notícia',
                              style: TextStyle(
                                color: context.appPrimaryInk,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new,
                              size: 13,
                              color: context.appPrimaryInk,
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
    final placeholder = Semantics(
      image: true,
      label: 'Imagem ilustrativa da notícia',
      child: Container(
        color: context.appPrimarySoft,
        alignment: Alignment.center,
        child: Icon(Icons.newspaper, color: context.appPrimaryInk, size: 30),
      ),
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
                semanticLabel: 'Imagem da notícia',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : placeholder,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

String formatNewsDate(DateTime? date) {
  if (date == null) return 'Data não informada';
  const months = [
    'jan.',
    'fev.',
    'mar.',
    'abr.',
    'mai.',
    'jun.',
    'jul.',
    'ago.',
    'set.',
    'out.',
    'nov.',
    'dez.',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
