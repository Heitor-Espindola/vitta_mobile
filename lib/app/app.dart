import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/app/theme.dart';
import 'package:vitta_mobile/features/auth/presentation/login_screen.dart';
import 'package:vitta_mobile/features/auth/presentation/register_screen.dart';
import 'package:vitta_mobile/features/auth/presentation/splash_screen.dart';
import 'package:vitta_mobile/features/children/presentation/children_screen.dart';
import 'package:vitta_mobile/features/home/presentation/home_screen.dart';
import 'package:vitta_mobile/features/information/presentation/information_screen.dart';
import 'package:vitta_mobile/features/vaccination_card/presentation/vaccination_card_screen.dart';

class VittaApp extends StatelessWidget {
  const VittaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vitta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.children: (_) => const ChildrenScreen(),
        AppRoutes.vaccinationCard: (_) => const VaccinationCardScreen(),
        AppRoutes.information: (_) => const InformationScreen(),
      },
    );
  }
}
