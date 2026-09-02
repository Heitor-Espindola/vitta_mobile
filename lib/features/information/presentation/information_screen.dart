import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/features/information/data/news_repository.dart';
import 'package:vitta_mobile/features/information/domain/models/news_category.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_repository.dart';
import 'package:vitta_mobile/features/information/presentation/all_educational_content_screen.dart';
import 'package:vitta_mobile/features/information/presentation/all_news_screen.dart';
import 'package:vitta_mobile/features/information/presentation/controllers/news_controller.dart';
import 'package:vitta_mobile/features/information/presentation/models/educational_content.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/educational_content_widgets.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/news_article_card.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/news_category_selector.dart';
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
  int? _selectedContentIndex;

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

  Future<void> _openEducationalContent(int index) async {
    setState(() => _selectedContentIndex = index);
    final content = educationalContents[index];
    final shouldSearch = await showEducationalContent(context, content);
    if (mounted) setState(() => _selectedContentIndex = null);
    if (shouldSearch == true && mounted) {
      _searchController.text = content.searchTerm;
      await _search(content.searchTerm);
    }
  }

  Future<void> _openAllEducationalContents() async {
    final searchTerm = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const AllEducationalContentScreen()),
    );
    if (searchTerm != null && mounted) {
      _searchController.text = searchTerm;
      await _search(searchTerm);
    }
  }

  Future<void> _openAllNews() => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => AllNewsScreen(controller: _controller)),
  );

  Future<void> _showAllNews() async {
    _searchController.clear();
    await _controller.showAllNews();
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
    showTopBar: false,
    body: RefreshIndicator(
      onRefresh: _controller.refreshNews,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const _InformationHero(),
          const SizedBox(height: 14),
          NewsCategorySelector(
            selectedCategory: _controller.selectedCategory,
            enabled: !_controller.isLoading,
            onSelected: _controller.selectCategory,
          ),
          const SizedBox(height: 8),
          ExpandableSearch(
            hint: 'Pesquisar notícias',
            controller: _searchController,
            onSubmitted: _search,
            onClosed: _clearSearch,
          ),
          if (_controller.currentQuery.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _controller.isLoading ? null : _clearSearch,
                icon: const Icon(Icons.close, size: 16),
                label: Text('Limpar: ${_controller.currentQuery}'),
              ),
            ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Conteúdos educativos',
            actionLabel: 'Ver todos ›',
            actionKey: const Key('show-all-educational-content'),
            onAction: _openAllEducationalContents,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(educationalContents.length, (index) {
                final content = educationalContents[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == educationalContents.length - 1 ? 0 : 10,
                  ),
                  child: EducationalContentCard(
                    key: Key('educational-content-$index'),
                    content: content,
                    selected: _selectedContentIndex == index,
                    onTap: () => _openEducationalContent(index),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Notícias recentes',
            actionLabel: 'Ver todas ›',
            actionKey: const Key('show-all-news'),
            onAction: _openAllNews,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Seleção editorial sobre vacinação. Consulte sempre os canais oficiais de saúde.',
                  style: AppTypography.caption,
                ),
              ),
              IconButton(
                tooltip: 'Atualizar notícias',
                onPressed: _controller.isLoading
                    ? null
                    : _controller.refreshNews,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
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
    if (_controller.state == NewsState.empty) {
      return NewsEmptyState(
        hasSearch: _controller.currentQuery.isNotEmpty,
        onClearSearch: _controller.currentQuery.isEmpty ? null : _clearSearch,
        onShowAllNews:
            _controller.selectedCategory == NewsCategory.forYou ||
                _controller.currentQuery.isNotEmpty
            ? null
            : _showAllNews,
      );
    }
    return SizedBox(
      height: 278,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount:
            _controller.articles.length +
            (_controller.hasMore || _controller.state == NewsState.error
                ? 1
                : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index < _controller.articles.length) {
            return NewsArticleCard(
              article: _controller.articles[index],
              horizontal: true,
            );
          }
          return SizedBox(
            width: 180,
            child: Center(
              child: OutlinedButton.icon(
                onPressed: _controller.isLoadingMore
                    ? null
                    : _controller.state == NewsState.error
                    ? _controller.retry
                    : _controller.loadMore,
                icon: _controller.isLoadingMore
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _controller.state == NewsState.error
                      ? 'Tentar novamente'
                      : 'Mais notícias',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InformationHero extends StatelessWidget {
  const _InformationHero();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return OverflowBox(
      maxWidth: width,
      fit: OverflowBoxFit.deferToChild,
      child: Container(
        key: const Key('information-header-band'),
        width: width,
        padding: const EdgeInsets.fromLTRB(18, 17, 16, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF6FC), Color(0xFFF9FBFD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(bottom: BorderSide(color: Color(0xFFDCEBF4))),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conteúdo',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Informações confiáveis para cuidar da sua vacinação.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFF496273),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFDDEFFC),
              foregroundColor: AppColors.primaryDark,
              child: Icon(Icons.menu_book_outlined, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.actionKey,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      TextButton(
        key: actionKey,
        onPressed: onAction,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(
          actionLabel,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
