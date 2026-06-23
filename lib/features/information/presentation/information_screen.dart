import 'package:flutter/material.dart';
import 'package:vitta_mobile/features/information/data/repositories/firebase_information_repository.dart';
import 'package:vitta_mobile/features/information/domain/models/information_post.dart';
import 'package:vitta_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class InformationScreen extends StatefulWidget {
  const InformationScreen({super.key, this.informationRepository});

  final InformationRepository? informationRepository;

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  late final InformationRepository _informationRepository =
      widget.informationRepository ?? FirebaseInformationRepository();

  List<InformationPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _informationRepository.getPosts();
      if (!mounted) {
        return;
      }
      setState(() => _posts = posts);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _posts = _samplePosts);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = _posts.isEmpty ? _samplePosts : _posts;

    return VittaMobileShell(
      title: 'Conteudo',
      currentTab: VittaTab.content,
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 22),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: VittaSearchField(),
            ),
            const SizedBox(height: 22),
            const Text('Conteudos', style: TextStyle(fontSize: 11)),
            const SizedBox(height: 10),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ContentCard(
                    title: 'Vacinacao Infantil',
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
                    title: 'Duvidas Frequentes',
                    color: Color(0xFFFFF0F0),
                    icon: Icons.question_mark,
                    iconColor: Color(0xFFE43F3A),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Text('Artigos', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SizedBox(
                height: 106,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: posts.take(4).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) =>
                      _ArticleCard(post: posts[index]),
                ),
              ),
            const SizedBox(height: 26),
            const Text('Artigos', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) =>
                    _ArticleCard(post: posts[index], alternate: index.isOdd),
              ),
            ),
          ],
        ),
      ),
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
  Widget build(BuildContext context) {
    return SizedBox(
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
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.post, this.alternate = false});

  final InformationPost post;
  final bool alternate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: vittaLineBlue),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.category ?? 'Saude de A-Z',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3994E5),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E95E5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Detalhes em vacina',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _summarize(post.content),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: alternate
                  ? const Color(0xFFEDE7E0)
                  : const Color(0xFFD5B9A3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              alternate ? Icons.child_care : Icons.medication_liquid,
              color: alternate ? vittaDarkBlue : Colors.brown.shade700,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

String _summarize(String content) {
  if (content.length <= 90) {
    return content;
  }
  return '${content.substring(0, 90)}...';
}

const _samplePosts = [
  InformationPost(
    id: '1',
    title: 'Combate a desinformacao na area da saude: uma luta de todos',
    content:
        'Confira as dicas para identificar uma fake news e proteger sua familia.',
    category: 'Saude de A-Z',
  ),
  InformationPost(
    id: '2',
    title: 'A importancia das vacinas em todas as fases da vida',
    content: 'Veja a real importancia de manter a caderneta atualizada.',
    category: 'Saude de A-Z',
  ),
  InformationPost(
    id: '3',
    title: 'Quais sao os cuidados com o bebe pre-termo?',
    content: 'Conheca os cuidados com bebes que nascem antes de 37 semanas.',
    category: 'Caderneta da Crianca',
  ),
];
