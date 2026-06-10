import 'package:flutter/material.dart';
import 'package:vitta_mobile/shared/widgets/placeholder_page.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Vitta',
      message: 'Tela inicial do aplicativo.',
    );
  }
}
