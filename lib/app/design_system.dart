import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF3A92D3);
  static const primaryDark = Color(0xFF2B6D9D);
  static const primarySoft = Color(0xFFE7F3FA);
  static const background = Color(0xFFF7FAFC);
  static const surface = Colors.white;
  static const text = Color(0xFF172B38);
  static const textSecondary = Color(0xFF617481);
  static const border = Color(0xFFE4EBF0);
  static const danger = Color(0xFFC9474E);
  static const success = Color(0xFF268A5B);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const normal = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
}

abstract final class AppRadius {
  static const small = 10.0;
  static const card = 16.0;
  static const large = 18.0;
  static const pill = 999.0;
}

abstract final class AppTypography {
  static const pageTitle = TextStyle(
    fontSize: 23,
    height: 1.15,
    fontWeight: FontWeight.w800,
  );
  static const sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );
  static const body = TextStyle(fontSize: 14, height: 1.35);
  static const caption = TextStyle(fontSize: 11, height: 1.3);
}

abstract final class AppCardStyle {
  static BoxDecoration decoration(BuildContext context, {Color? color}) =>
      BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: .18)
                : const Color(0x0A173B50),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

extension VittaThemeColors on BuildContext {
  ThemeData get appTheme => Theme.of(this);
  bool get isDarkMode => appTheme.brightness == Brightness.dark;
  ColorScheme get appColorScheme => appTheme.colorScheme;
  Color get appBackground => appTheme.scaffoldBackgroundColor;
  Color get appSurface => appColorScheme.surface;
  Color get appText => appColorScheme.onSurface;
  Color get appTextSecondary => appColorScheme.onSurface.withValues(alpha: .7);
  Color get appBorder =>
      appColorScheme.outline.withValues(alpha: isDarkMode ? .72 : .28);
  Color get appPrimarySoft => isDarkMode
      ? appColorScheme.primary.withValues(alpha: .14)
      : AppColors.primarySoft;
  Color get appPrimaryInk =>
      isDarkMode ? appColorScheme.primary : AppColors.primaryDark;
}
