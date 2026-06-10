import 'package:flutter/material.dart';
import 'package:vitta_mobile/features/information/data/repositories/firebase_information_repository.dart';
import 'package:vitta_mobile/features/information/domain/models/information_post.dart';
import 'package:vitta_mobile/features/information/domain/repositories/information_repository.dart';

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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
      setState(() => _errorMessage = 'Erro ao buscar informacoes.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informacoes')),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_posts.isEmpty)
              const Text('Nenhuma informacao cadastrada ainda.')
            else
              ..._posts.map(
                (post) => Card(
                  child: ListTile(
                    title: Text(post.title),
                    subtitle: Text(
                      [
                        if ((post.category ?? '').isNotEmpty)
                          'Categoria: ${post.category}',
                        if ((post.source ?? '').isNotEmpty)
                          'Fonte: ${post.source}',
                        _summarize(post.content),
                      ].join('\n'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _summarize(String content) {
  if (content.length <= 140) {
    return content;
  }
  return '${content.substring(0, 140)}...';
}
