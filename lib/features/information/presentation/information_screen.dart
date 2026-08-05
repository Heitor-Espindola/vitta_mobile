import 'package:flutter/material.dart';
import 'package:vitta_mobile/features/information/data/news_repository.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_repository.dart';
import 'package:vitta_mobile/features/information/presentation/controllers/news_controller.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/news_article_card.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/news_states.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class InformationScreen extends StatefulWidget {
  const InformationScreen({super.key, this.newsRepository});
  final NewsRepository? newsRepository;

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  late final NewsController _controller = NewsController(
    repository: widget.newsRepository ?? ApiNewsRepository(),
  )..addListener(_onChanged);
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.loadInitialNews();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _search(String term) async {
    FocusScope.of(context).unfocus();
    await _controller.searchNews(term);
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    await _controller.clearSearch();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VittaMobileShell(
    title: 'Conteúdo',
    currentTab: VittaTab.content,
    body: RefreshIndicator(
      onRefresh: _controller.refreshNews,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 22, 14, 22),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: VittaSearchField(
              hint: 'Pesquisar notícias',
              controller: _searchController,
              onSubmitted: _search,
            ),
          ),
          if (_controller.currentQuery.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _controller.isLoading ? null : _clearSearch,
                icon: const Icon(Icons.close, size: 16),
                label: Text('Limpar: ${_controller.currentQuery}'),
              ),
            ),
          const SizedBox(height: 18),
          const Text('Conteúdos educativos', style: TextStyle(fontSize: 11)),
          const SizedBox(height: 10),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ContentCard(
                  title: 'Vacinação Infantil',
                  color: Color(0xFFF1C874),
                  icon: Icons.family_restroom,
                  selected: true,
                ),
                SizedBox(width: 18),
                _ContentCard(
                  title: 'Descobertas Recentes',
                  color: Color(0xFFECF6FF),
                  icon: Icons.lightbulb_outline,
                ),
                SizedBox(width: 18),
                _ContentCard(
                  title: 'Dúvidas Frequentes',
                  color: Color(0xFFFFF0F0),
                  icon: Icons.question_mark,
                  iconColor: Color(0xFFE43F3A),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Notícias externas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar notícias',
                onPressed: _controller.isLoading
                    ? null
                    : _controller.refreshNews,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const Text(
            'As notícias são fornecidas por fontes externas. Consulte sempre canais oficiais de saúde.',
            style: TextStyle(fontSize: 10, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          _newsBody(),
        ],
      ),
    ),
  );

  Widget _newsBody() {
    if (_controller.isLoading) return const NewsLoadingList();
    if (_controller.state == NewsState.error && _controller.articles.isEmpty) {
      return NewsErrorState(
        message:
            _controller.errorMessage ??
            'Não foi possível carregar as notícias no momento.',
        onRetry: _controller.retry,
      );
    }
    if (_controller.state == NewsState.empty) return const NewsEmptyState();
    return Column(
      children: [
        ..._controller.articles.map(
          (article) => NewsArticleCard(article: article),
        ),
        if (_controller.state == NewsState.error) ...[
          Text(
            _controller.errorMessage ??
                'Não foi possível carregar mais notícias.',
          ),
          TextButton(
            onPressed: _controller.retry,
            child: const Text('Tentar novamente'),
          ),
        ] else if (_controller.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              onPressed: _controller.isLoadingMore
                  ? null
                  : _controller.loadMore,
              icon: _controller.isLoadingMore
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: Text(
                _controller.isLoadingMore ? 'Carregando...' : 'Carregar mais',
              ),
            ),
          ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.title,
    required this.color,
    required this.icon,
    this.iconColor = vittaBlue,
    this.selected = false,
  });
  final String title;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final bool selected;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 88,
    child: Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: vittaLineBlue),
          ),
          child: Icon(icon, size: 44, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700),
        ),
        if (selected)
          Container(
            width: 82,
            height: 4,
            margin: const EdgeInsets.only(top: 3),
            color: vittaDarkBlue,
          ),
      ],
    ),
  );
}
