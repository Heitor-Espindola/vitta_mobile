import 'dart:async';

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

/// Alternates a single static Muuni pose between visible and hidden periods.
/// No sprite-frame, fade or movement animation is used.
class MuuniTimedPresence extends StatefulWidget {
  const MuuniTimedPresence({
    super.key,
    this.size = 124,
    this.frame = 11,
    this.visibleDuration = const Duration(seconds: 6),
    this.hiddenDuration = const Duration(seconds: 12),
  });

  final double size;
  final int frame;
  final Duration visibleDuration;
  final Duration hiddenDuration;

  @override
  State<MuuniTimedPresence> createState() => _MuuniTimedPresenceState();
}

class _MuuniTimedPresenceState extends State<MuuniTimedPresence> {
  Timer? _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(
      _visible ? widget.visibleDuration : widget.hiddenDuration,
      () {
        if (!mounted) return;
        setState(() => _visible = !_visible);
        _scheduleNext();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Visibility(
      key: const Key('muuni-timed-presence'),
      visible: _visible,
      maintainAnimation: true,
      maintainState: true,
      maintainSize: true,
      child: MuuniSpriteFrame(
        key: const Key('muuni-static-sprite'),
        frame: widget.frame,
        size: widget.size,
      ),
    ),
  );
}
