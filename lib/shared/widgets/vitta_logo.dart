import 'package:flutter/material.dart';

class VittaLogo extends StatelessWidget {
  const VittaLogo({super.key, this.size = 44, this.semanticLabel = 'Vitta'});

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/vitta_logo.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: semanticLabel,
  );
}
