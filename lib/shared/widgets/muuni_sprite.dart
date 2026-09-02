import 'dart:math' as math;

import 'package:flutter/material.dart';

const _muuniSpriteAsset = 'assets/images/muuni/muuni_notification_sprite.png';
const _muuniSeatedAsset = 'assets/images/muuni/muuni_seated_nav.png';
const _spriteColumns = 4;
const _spriteRows = 3;
const _spriteFrameCount = _spriteColumns * _spriteRows;

class MuuniSeatedNavMascot extends StatelessWidget {
  const MuuniSeatedNavMascot({super.key, this.height = 92});

  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Muuni lendo na barra de navegação',
    child: Image.asset(
      _muuniSeatedAsset,
      key: const Key('muuni-seated-nav'),
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    ),
  );
}

class MuuniSpriteFrame extends StatelessWidget {
  const MuuniSpriteFrame({
    super.key,
    required this.frame,
    this.size = 96,
    this.semanticLabel = 'Muuni, mascote do Vitta',
  });

  final int frame;
  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final safeFrame = frame.clamp(0, _spriteFrameCount - 1);
    final column = safeFrame % _spriteColumns;
    final row = safeFrame ~/ _spriteColumns;
    final alignment = Alignment(
      -1 + (2 * column / (_spriteColumns - 1)),
      -1 + (2 * row / (_spriteRows - 1)),
    );

    return Semantics(
      image: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: ClipRect(
          child: OverflowBox(
            alignment: alignment,
            minWidth: size * _spriteColumns,
            maxWidth: size * _spriteColumns,
            minHeight: size * _spriteRows,
            maxHeight: size * _spriteRows,
            child: Image.asset(
              _muuniSpriteAsset,
              width: size * _spriteColumns,
              height: size * _spriteRows,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}

class MuuniEntranceAnimation extends StatefulWidget {
  const MuuniEntranceAnimation({
    super.key,
    this.size = 124,
    this.fadeOut = true,
  });

  final double size;
  final bool fadeOut;

  @override
  State<MuuniEntranceAnimation> createState() => _MuuniEntranceAnimationState();
}

class _MuuniEntranceAnimationState extends State<MuuniEntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  bool _preparing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preparing) return;
    _preparing = true;
    _prepareAndStart();
  }

  Future<void> _prepareAndStart() async {
    try {
      await precacheImage(const AssetImage(_muuniSpriteAsset), context);
    } catch (_) {
      // A animação ainda pode tentar renderizar o asset normalmente.
    }
    if (mounted) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final motionProgress = (value / .78).clamp(0.0, 1.0);
        final slideProgress = Curves.easeOutCubic.transform(motionProgress);
        final frame = math.min(
          _spriteFrameCount - 1,
          (motionProgress * _spriteFrameCount).floor(),
        );
        final fadeOutProgress = ((value - .88) / .12).clamp(0.0, 1.0);
        final opacity = value < .08
            ? Curves.easeOut.transform(value / .08)
            : widget.fadeOut && value > .88
            ? 1 - Curves.easeIn.transform(fadeOutProgress)
            : 1.0;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(-10 * (1 - slideProgress), 0),
            child: MuuniSpriteFrame(
              key: const Key('muuni-animated-sprite'),
              frame: frame,
              size: widget.size,
            ),
          ),
        );
      },
    ),
  );
}
