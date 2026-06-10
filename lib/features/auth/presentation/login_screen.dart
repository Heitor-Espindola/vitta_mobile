import 'package:flutter/material.dart';
import 'package:vitta_mobile/shared/widgets/placeholder_page.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Login',
      message: 'Autenticacao sera implementada com Firebase Authentication.',
    );
  }
}
