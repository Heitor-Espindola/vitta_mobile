import 'package:flutter/material.dart';
import 'package:vitta_mobile/core/config/domain_repository_factory.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/auth/presentation/auth_error_mapper.dart';
import 'package:vitta_mobile/features/auth/presentation/login_screen.dart';
import 'package:vitta_mobile/features/home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.authRepository});
  final AuthRepository? authRepository;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthRepository _repository =
      widget.authRepository ?? DomainRepositoryFactory.auth();

  @override
  Widget build(BuildContext context) => StreamBuilder<AppUser?>(
    stream: _repository.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return LoginScreen(
          authRepository: _repository,
          initialErrorMessage: mapSignInError(snapshot.error!),
        );
      }
      final user = snapshot.data;
      if (user == null) return LoginScreen(authRepository: _repository);
      return HomeScreen(authRepository: _repository);
    },
  );
}
