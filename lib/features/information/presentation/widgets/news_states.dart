import 'package:flutter/material.dart';

class NewsLoadingList extends StatelessWidget {
  const NewsLoadingList({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 42),
    child: Center(child: CircularProgressIndicator()),
  );
}

class NewsErrorState extends StatelessWidget {
  const NewsErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 40),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ],
    ),
  );
}

class NewsEmptyState extends StatelessWidget {
  const NewsEmptyState({
    required this.hasSearch,
    this.onClearSearch,
    this.onShowAllNews,
    super.key,
  });

  final bool hasSearch;
  final VoidCallback? onClearSearch;
  final VoidCallback? onShowAllNews;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Center(
      child: Column(
        children: [
          Text(
            hasSearch
                ? 'Nenhum resultado encontrado'
                : 'Sem novidades por aqui',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            hasSearch
                ? 'Tente outro termo ou limpe a pesquisa.'
                : 'Não encontramos notícias recentes sobre este tema.',
            textAlign: TextAlign.center,
          ),
          if (hasSearch && onClearSearch != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onClearSearch,
              icon: const Icon(Icons.close),
              label: const Text('Limpar busca'),
            ),
          ] else if (onShowAllNews != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              key: const Key('empty-show-all-news'),
              onPressed: onShowAllNews,
              icon: const Icon(Icons.article_outlined),
              label: const Text('Ver todas as notícias'),
            ),
          ],
        ],
      ),
    ),
  );
}
