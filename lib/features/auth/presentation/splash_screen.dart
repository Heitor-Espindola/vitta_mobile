import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AuthRepository get _authRepository =>
      widget.authRepository ?? FirebaseAuthRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    final navigator = Navigator.of(context);
    try {
      final user = await _authRepository.getCurrentUser();
      if (!mounted) {
        return;
      }
      navigator.pushReplacementNamed(
        user == null ? AppRoutes.login : AppRoutes.home,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      navigator.pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
