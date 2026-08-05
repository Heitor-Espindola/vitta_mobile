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
  const NewsEmptyState({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 36),
    child: Center(
      child: Text(
        'Nenhuma notícia relacionada foi encontrada.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
