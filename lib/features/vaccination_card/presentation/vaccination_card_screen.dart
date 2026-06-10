import 'package:flutter/material.dart';
import 'package:vitta_mobile/shared/widgets/placeholder_page.dart';

class VaccinationCardScreen extends StatelessWidget {
  const VaccinationCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Carteira vacinal',
      message: 'Historico e status de vacinas serao exibidos nesta area.',
    );
  }
}
