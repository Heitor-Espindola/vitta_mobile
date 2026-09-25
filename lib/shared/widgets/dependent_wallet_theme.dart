import 'package:flutter/material.dart';

abstract final class DependentWalletColors {
  static const background = Color(0xFFF2FAFF);
  static const sky = Color(0xFFDDF3FC);
  static const mint = Color(0xFFDDF4EA);
  static const peach = Color(0xFFE3F4FE);
  static const lavender = Color(0xFFE9E2F7);
  static const ink = Color(0xFF173B52);
  static const spot = Color(0xFF2E607E);
  static const border = Color(0xFFCDE7F5);
}

class DependentWalletPalette {
  const DependentWalletPalette({
    required this.background,
    required this.sky,
    required this.mint,
    required this.peach,
    required this.lavender,
    required this.ink,
    required this.spot,
    required this.border,
  });

  factory DependentWalletPalette.of(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) {
      return const DependentWalletPalette(
        background: DependentWalletColors.background,
        sky: DependentWalletColors.sky,
        mint: DependentWalletColors.mint,
        peach: DependentWalletColors.peach,
        lavender: DependentWalletColors.lavender,
        ink: DependentWalletColors.ink,
        spot: DependentWalletColors.spot,
        border: DependentWalletColors.border,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return DependentWalletPalette(
      background: const Color(0xFF10232D),
      sky: const Color(0xFF173442),
      mint: const Color(0xFF183A34),
      peach: const Color(0xFF1A3545),
      lavender: const Color(0xFF302B42),
      ink: scheme.onSurface,
      spot: scheme.primary,
      border: const Color(0xFF31566A),
    );
  }

  final Color background;
  final Color sky;
  final Color mint;
  final Color peach;
  final Color lavender;
  final Color ink;
  final Color spot;
  final Color border;
}

class DependentWalletBackground extends StatelessWidget {
  const DependentWalletBackground({
    super.key,
    required this.child,
    required this.enabled,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final palette = DependentWalletPalette.of(context);
    return ColoredBox(
      color: palette.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(painter: _CowSpotsPainter(palette.spot)),
          ),
          child,
        ],
      ),
    );
  }
}

class _CowSpotsPainter extends CustomPainter {
  const _CowSpotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: .055);
    canvas.drawOval(
      Rect.fromLTWH(-size.width * .12, size.height * .08, 118, 72),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .78, size.height * .20, 94, 126),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .04, size.height * .55, 62, 46),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .70, size.height * .78, 142, 76),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CowSpotsPainter oldDelegate) =>
      color != oldDelegate.color;
}
