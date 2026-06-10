import 'package:flutter/material.dart';
import 'package:vitta_mobile/shared/widgets/placeholder_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Home',
      message: 'Resumo principal da carteira de vacinacao digital.',
    );
  }
}
