import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/features/information/data/firestore_news_repository.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_repository.dart';
import 'package:vitta_mobile/features/information/presentation/all_educational_content_screen.dart';
import 'package:vitta_mobile/features/information/presentation/all_news_screen.dart';
import 'package:vitta_mobile/features/information/presentation/controllers/news_controller.dart';
import 'package:vitta_mobile/features/information/presentation/models/educational_content.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/educational_content_widgets.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/news_article_card.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/news_states.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/shared/widgets/dependent_wallet_theme.dart';
import 'package:vitta_mobile/shared/widgets/muuni_sprite.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

const _primaryEducationalContentCount = 9;

class InformationScreen extends StatefulWidget {
  const InformationScreen({
    super.key,
    this.newsRepository,
    this.walletController,
  });

  final NewsRepository? newsRepository;
  final WalletSelectionController? walletController;

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  late final WalletSelectionController _wallet =
      widget.walletController ?? WalletSelectionController.instance;
  late final NewsController _controller = NewsController(
    repository: widget.newsRepository ?? FirestoreNewsRepository(),
  )..addListener(_onChanged);
  final _searchController = TextEditingController();
  int? _selectedContentIndex;

  @override
  void initState() {
    super.initState();
    _wallet.addListener(_onWalletChanged);
    _controller.loadInitialNews();
  }

  void _onWalletChanged() {
    if (mounted) setState(() {});
  }

  bool get _isViewingDependent =>
      _wallet.currentPersonId != null && !_wallet.isViewingCurrent;

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

  @override
  void dispose() {
    _wallet.removeListener(_onWalletChanged);
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
    body: DependentWalletBackground(
      key: Key(
        _isViewingDependent
            ? 'information-dependent-theme'
            : 'information-standard-theme',
      ),
      enabled: _isViewingDependent,
      child: RefreshIndicator(
        onRefresh: _controller.refreshNews,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _InformationHero(dependent: _isViewingDependent),
            const SizedBox(height: 14),
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
                children: List.generate(_primaryEducationalContentCount, (
                  index,
                ) {
                  final content = educationalContents[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == _primaryEducationalContentCount - 1
                          ? 0
                          : 10,
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
              title: 'Notícias e atualizações',
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
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Guias para cada fase',
              actionLabel: 'Ver todos ›',
              onAction: _openAllEducationalContents,
            ),
            const SizedBox(height: 8),
            ...List.generate(
              educationalContents.length - _primaryEducationalContentCount,
              (offset) {
                final index = offset + _primaryEducationalContentCount;
                return EducationalContentCard(
                  key: Key('life-stage-content-$offset'),
                  content: educationalContents[index],
                  compact: false,
                  onTap: () => _openEducationalContent(index),
                );
              },
            ),
          ],
        ),
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
        onLoadMore: _controller.hasMore && _controller.currentQuery.isEmpty
            ? _controller.loadMore
            : null,
      );
    }
    final featured = _controller.articles.take(5).toList(growable: false);
    if (featured.length == 1) {
      return NewsArticleCard(article: featured.single);
    }
    return SizedBox(
      height: 278,
      child: ListView.separated(
        key: const Key('featured-news-list'),
        scrollDirection: Axis.horizontal,
        itemCount: featured.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) =>
            NewsArticleCard(article: featured[index], horizontal: true),
      ),
    );
  }
}

class _InformationHero extends StatelessWidget {
  const _InformationHero({required this.dependent});

  final bool dependent;

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
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEAF6FC), Color(0xFFF9FBFD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            const Expanded(
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
            const SizedBox(width: 12),
            if (dependent)
              const SizedBox(
                width: 70,
                height: 78,
                child: MuuniTimedPresence(frame: 9, size: 70),
              )
            else
              const CircleAvatar(
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
