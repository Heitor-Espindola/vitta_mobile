import 'package:flutter/material.dart';

abstract final class DependentWalletColors {
  static const background = Color(0xFFFFFAF0);
  static const sky = Color(0xFFDDF3FC);
  static const mint = Color(0xFFDDF4EA);
  static const peach = Color(0xFFFFE5C7);
  static const lavender = Color(0xFFE9E2F7);
  static const ink = Color(0xFF3F302B);
  static const spot = Color(0xFF4A342B);
  static const border = Color(0xFFE8D7C4);
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
    return ColoredBox(
      color: DependentWalletColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(child: CustomPaint(painter: _CowSpotsPainter())),
          child,
        ],
      ),
    );
  }
}

class _CowSpotsPainter extends CustomPainter {
  const _CowSpotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DependentWalletColors.spot.withValues(alpha: .075);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
