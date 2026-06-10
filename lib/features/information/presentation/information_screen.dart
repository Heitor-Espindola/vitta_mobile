import 'package:flutter/material.dart';
import 'package:vitta_mobile/shared/widgets/placeholder_page.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Informacoes',
      message: 'Conteudos informativos sobre vacinacao serao adicionados aqui.',
    );
  }
}
