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
    color: AppColors.text,
  );
  static const sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );
  static const body = TextStyle(
    fontSize: 14,
    height: 1.35,
    color: AppColors.text,
  );
  static const caption = TextStyle(
    fontSize: 11,
    height: 1.3,
    color: AppColors.textSecondary,
  );
}

abstract final class AppCardStyle {
  static BoxDecoration decoration({Color color = AppColors.surface}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A173B50),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );
}
