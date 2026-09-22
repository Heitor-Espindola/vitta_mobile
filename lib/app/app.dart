import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/app/theme.dart';
import 'package:vitta_mobile/core/config/app_preferences.dart';
import 'package:vitta_mobile/features/auth/presentation/login_screen.dart';
import 'package:vitta_mobile/features/auth/presentation/register_screen.dart';
import 'package:vitta_mobile/features/auth/presentation/splash_screen.dart';
import 'package:vitta_mobile/features/home/presentation/home_screen.dart';
import 'package:vitta_mobile/features/information/presentation/information_screen.dart';
import 'package:vitta_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:vitta_mobile/features/people/presentation/family_screen.dart';
import 'package:vitta_mobile/features/profile/presentation/profile_screen.dart';
import 'package:vitta_mobile/features/vaccination_card/presentation/vaccination_card_screen.dart';
import 'package:vitta_mobile/features/vaccines/presentation/vaccines_screen.dart';

class VittaApp extends StatelessWidget {
  const VittaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppPreferences.instance,
      builder: (context, _) => MaterialApp(
        title: 'Vitta',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: AppPreferences.instance.darkModeEnabled
            ? ThemeMode.dark
            : ThemeMode.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(AppPreferences.instance.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
          AppRoutes.vaccinationCard: (_) => const VaccinationCardScreen(),
          AppRoutes.information: (_) => const InformationScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.vaccines: (_) => const VaccinesScreen(),
          AppRoutes.notifications: (_) => const NotificationsScreen(),
          AppRoutes.family: (_) => const FamilyScreen(),
        },
      ),
    );
  }
}
