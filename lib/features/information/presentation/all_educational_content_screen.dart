import 'package:flutter/material.dart';
import 'package:vitta_mobile/features/information/presentation/models/educational_content.dart';
import 'package:vitta_mobile/features/information/presentation/widgets/educational_content_widgets.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class AllEducationalContentScreen extends StatefulWidget {
  const AllEducationalContentScreen({super.key});

  @override
  State<AllEducationalContentScreen> createState() =>
      _AllEducationalContentScreenState();
}

class _AllEducationalContentScreenState
    extends State<AllEducationalContentScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';

  List<EducationalContent> get _filteredContents => educationalContents
      .where((content) => content.matches(_searchTerm))
      .toList(growable: false);

  Future<void> _openContent(EducationalContent content) async {
    final shouldSearch = await showEducationalContent(context, content);
    if (shouldSearch == true && mounted) {
      Navigator.of(context).pop(content.searchTerm);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FAFC),
    appBar: AppBar(title: const Text('Conteúdos educativos')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        ExpandableSearch(
          controller: _searchController,
          hint: 'Pesquisar conteúdo',
          onChanged: (value) => setState(() => _searchTerm = value),
          onClosed: () => setState(() => _searchTerm = ''),
        ),
        const SizedBox(height: 12),
        const Text(
          'Orientações gerais sobre vacinação, calendário e conservação da carteira.',
          style: TextStyle(fontSize: 12, color: Color(0xFF566D7A)),
        ),
        const SizedBox(height: 16),
        if (_filteredContents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Text(
              'Nenhum conteúdo educativo encontrado.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._filteredContents.map(
            (content) => EducationalContentCard(
              key: Key('all-educational-${content.searchTerm}'),
              content: content,
              compact: false,
              onTap: () => _openContent(content),
            ),
          ),
      ],
    ),
  );
}
