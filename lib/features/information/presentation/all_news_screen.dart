import 'package:flutter/material.dart';
import 'package:vitta_mobile/features/information/domain/models/news_category.dart';
import 'package:vitta_mobile/features/information/presentation/controllers/news_controller.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/news_article_card.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/news_category_selector.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/news_states.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class AllNewsScreen extends StatefulWidget {
  const AllNewsScreen({required this.controller, super.key});

  final NewsController controller;

  @override
  State<AllNewsScreen> createState() => _AllNewsScreenState();
}

class _AllNewsScreenState extends State<AllNewsScreen> {
  late final TextEditingController _searchController = TextEditingController(
    text: widget.controller.currentQuery,
  );

  Future<void> _search(String term) async {
    FocusScope.of(context).unfocus();
    await widget.controller.searchNews(term);
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    await widget.controller.clearSearch();
  }

  Future<void> _showAllNews() async {
    _searchController.clear();
    await widget.controller.showAllNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FAFC),
    appBar: AppBar(title: const Text('Notícias e atualizações')),
    body: AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => RefreshIndicator(
        onRefresh: widget.controller.refreshNews,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ExpandableSearch(
              controller: _searchController,
              hint: 'Pesquisar notícias',
              onSubmitted: _search,
              onClosed: _clearSearch,
            ),
            if (widget.controller.currentQuery.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.controller.isLoading ? null : _clearSearch,
                  icon: const Icon(Icons.close, size: 16),
                  label: Text('Limpar: ${widget.controller.currentQuery}'),
                ),
              ),
            const SizedBox(height: 8),
            NewsCategorySelector(
              selectedCategory: widget.controller.selectedCategory,
              enabled: !widget.controller.isLoading,
              onSelected: widget.controller.selectCategory,
            ),
            const SizedBox(height: 16),
            const Text(
              'Seleção editorial de notícias sobre vacinação. Consulte sempre os canais oficiais de saúde.',
              style: TextStyle(fontSize: 11, color: Color(0xFF566D7A)),
            ),
            const SizedBox(height: 14),
            _body(),
          ],
        ),
      ),
    ),
  );

  Widget _body() {
    final controller = widget.controller;
    if (controller.isLoading) return const NewsLoadingList();
    if (controller.state == NewsState.error && controller.articles.isEmpty) {
      return NewsErrorState(
        message:
            controller.errorMessage ??
            'Não foi possível carregar as notícias no momento.',
        onRetry: controller.retry,
      );
    }
    if (controller.state == NewsState.empty) {
      return NewsEmptyState(
        hasSearch: controller.currentQuery.isNotEmpty,
        onClearSearch: controller.currentQuery.isEmpty ? null : _clearSearch,
        onShowAllNews: controller.selectedCategory == NewsCategory.forYou
            ? null
            : _showAllNews,
      );
    }
    return Column(
      children: [
        ...controller.articles.map(
          (article) => NewsArticleCard(article: article),
        ),
        if (controller.hasMore || controller.state == NewsState.error)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              key: const Key('load-more-news'),
              onPressed: controller.isLoadingMore
                  ? null
                  : controller.state == NewsState.error
                  ? controller.retry
                  : controller.loadMore,
              icon: controller.isLoadingMore
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(
                controller.state == NewsState.error
                    ? 'Tentar novamente'
                    : 'Carregar mais',
              ),
            ),
          ),
      ],
    );
  }
}
