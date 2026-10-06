import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  late final Stream<AppUser?> _authStream;
  late final VideoPlayerController _videoController;

  Timer? _completionTimer;
  Timer? _failsafeTimer;
  bool _videoReady = false;
  bool _finishingIntro = false;
  bool _introCompleted = false;

  @override
  void initState() {
    super.initState();
    _authStream = _repository.authStateChanges();
    _videoController = VideoPlayerController.asset(
      'assets/videos/vitta_intro.mp4',
    );
    _failsafeTimer = Timer(
      const Duration(seconds: 4),
      () => unawaited(_finishIntro()),
    );
    unawaited(_startIntro());
  }

  Future<void> _startIntro() async {
    try {
      await _videoController.initialize();
      await _videoController.setLooping(false);
      await _videoController.setVolume(0);
      if (!mounted) return;
      setState(() => _videoReady = true);
      await _videoController.play();
      final duration = _videoController.value.duration;
      _completionTimer = Timer(
        duration > Duration.zero
            ? duration + const Duration(milliseconds: 120)
            : const Duration(milliseconds: 1200),
        () => unawaited(_finishIntro()),
      );
    } catch (_) {
      await _finishIntro();
    }
  }

  Future<void> _finishIntro() async {
    if (!mounted || _introCompleted || _finishingIntro) return;
    _finishingIntro = true;
    _completionTimer?.cancel();
    _failsafeTimer?.cancel();
    if (_videoController.value.isInitialized) {
      try {
        await _videoController.pause();
        await _videoController.seekTo(Duration.zero);
      } catch (_) {
        // The logo asset below remains the safe fallback if video seeking fails.
      }
    }
    if (!mounted) return;
    setState(() => _introCompleted = true);
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _failsafeTimer?.cancel();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<AppUser?>(
    stream: _authStream,
    builder: (context, snapshot) {
      if (!_introCompleted ||
          snapshot.connectionState == ConnectionState.waiting) {
        return _VittaIntro(
          controller: _videoController,
          videoReady: _videoReady,
          showProgress:
              _introCompleted &&
              snapshot.connectionState == ConnectionState.waiting,
        );
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

class _VittaIntro extends StatelessWidget {
  const _VittaIntro({
    required this.controller,
    required this.videoReady,
    required this.showProgress,
  });

  final VideoPlayerController controller;
  final bool videoReady;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FC),
      body: Semantics(
        label: 'Carregando o Vitta',
        image: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (videoReady)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            else
              Center(
                child: Image.asset(
                  'assets/images/vitta_logo.png',
                  width: 190,
                  fit: BoxFit.contain,
                ),
              ),
            if (showProgress)
              const Align(
                alignment: Alignment(0, 0.88),
                child: SizedBox.square(
                  dimension: 26,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
