import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/features/information/data/news_repository.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_repository.dart';
import 'package:vitta_mobile/features/information/domain/models/news_category.dart';
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
    final content = _educationalContents[index];
    final shouldSearch = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EducationalContentSheet(content: content),
    );
    if (mounted) setState(() => _selectedContentIndex = null);
    if (shouldSearch == true && mounted) {
      _searchController.text = content.searchTerm;
      await _search(content.searchTerm);
    }
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
          ExpandableSearch(
            hint: 'Pesquisar notícias',
            controller: _searchController,
            onSubmitted: _search,
            onClosed: _clearSearch,
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
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: NewsCategory.values
                  .map((category) {
                    final selected = _controller.selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        key: Key('news-category-${category.name}'),
                        label: Text(category.label),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: _controller.isLoading
                            ? null
                            : (_) => _controller.selectCategory(category),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle(
            title: 'Conteúdos educativos',
            action: 'Ver todos ›',
            compact: true,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_educationalContents.length, (index) {
                final content = _educationalContents[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _educationalContents.length - 1 ? 0 : 10,
                  ),
                  child: _ContentCard(
                    key: Key('educational-content-$index'),
                    title: content.title,
                    color: content.color,
                    icon: content.icon,
                    iconColor: content.iconColor,
                    selected: _selectedContentIndex == index,
                    onTap: () => _openEducationalContent(index),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Notícias recentes',
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
            'As notícias são fornecidas por fontes externas. Consulte sempre os canais oficiais de saúde.',
            style: AppTypography.caption,
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
        onClearSearch: _controller.currentQuery.isEmpty ? null : _clearSearch,
      );
    }
    return SizedBox(
      height: 250,
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
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 17, 16, 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFEAF6FC), Color(0xFFF9FBFD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFDCEBF4)),
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
  );
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
    this.iconColor = vittaBlue,
    this.selected = false,
    super.key,
  });

  final String title;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 108,
    child: Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: 108,
              height: 64,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? vittaDarkBlue : vittaLineBlue,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 108,
          height: selected ? 4 : 0,
          margin: const EdgeInsets.only(top: 3),
          color: vittaDarkBlue,
        ),
      ],
    ),
  );
}

class _EducationalContentSheet extends StatelessWidget {
  const _EducationalContentSheet({required this.content});

  final _EducationalContent content;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DDE2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: content.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(content.icon, color: content.iconColor, size: 31),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              content.introduction,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            ...content.topics.map(
              (topic) => Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: vittaBlue,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        topic,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F7FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Este conteúdo é educativo. Para orientações individuais, procure uma unidade de saúde.',
                style: TextStyle(fontSize: 11, color: Color(0xFF566D7A)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('search-related-news'),
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.search),
              label: const Text('Buscar notícias relacionadas'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EducationalContent {
  const _EducationalContent({
    required this.title,
    required this.searchTerm,
    required this.introduction,
    required this.topics,
    required this.color,
    required this.icon,
    this.iconColor = vittaBlue,
  });

  final String title;
  final String searchTerm;
  final String introduction;
  final List<String> topics;
  final Color color;
  final IconData icon;
  final Color iconColor;
}

const _educationalContents = [
  _EducationalContent(
    title: 'Vacinação Infantil',
    searchTerm: 'vacinação infantil',
    introduction:
        'A vacinação na infância ajuda a proteger a criança e toda a comunidade contra doenças que podem causar complicações graves.',
    topics: [
      'Mantenha a caderneta atualizada desde o nascimento.',
      'Respeite as datas das doses e dos reforços recomendados.',
      'Leve a carteira de vacinação em todas as consultas e campanhas.',
      'Em caso de atraso, procure uma unidade de saúde para atualizar as doses.',
    ],
    color: Color(0xFFF1C874),
    icon: Icons.family_restroom,
  ),
  _EducationalContent(
    title: 'Descobertas Recentes',
    searchTerm: 'novas vacinas imunização',
    introduction:
        'Pesquisas em imunização avaliam novas vacinas, formas de aplicação e estratégias para ampliar a proteção da população.',
    topics: [
      'Novos estudos precisam passar por etapas rigorosas de segurança.',
      'Recomendações oficiais podem mudar conforme novas evidências.',
      'Consulte Ministério da Saúde, Anvisa e sociedades científicas.',
      'Notícias externas devem ser confirmadas em canais oficiais.',
    ],
    color: Color(0xFFECF6FF),
    icon: Icons.lightbulb_outline,
  ),
  _EducationalContent(
    title: 'Dúvidas Frequentes',
    searchTerm: 'dúvidas sobre vacinação',
    introduction:
        'Informações confiáveis ajudam a tomar decisões seguras sobre vacinação. Veja orientações gerais para dúvidas comuns.',
    topics: [
      'Reações leves, como dor local, podem ocorrer após algumas vacinas.',
      'Atrasar uma dose não significa necessariamente reiniciar o esquema.',
      'Condições de saúde específicas devem ser avaliadas por profissional.',
      'A unidade de saúde pode conferir doses pendentes e contraindicações.',
    ],
    color: Color(0xFFFFF0F0),
    icon: Icons.question_mark,
    iconColor: Color(0xFFE43F3A),
  ),
];
