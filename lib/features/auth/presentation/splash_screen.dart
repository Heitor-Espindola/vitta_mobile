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
  late final VideoPlayerController _videoController;

  StreamSubscription<AppUser?>? _authSubscription;
  Timer? _failsafeTimer;
  AppUser? _user;
  Object? _authError;
  bool _authResolved = false;
  bool _videoReady = false;
  bool _startingIntro = false;
  bool _finishingIntro = false;
  bool _introCompleted = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(
      'assets/videos/vitta_intro.mp4',
    )..addListener(_handleVideoState);
    _authSubscription = _repository.authStateChanges().listen(
      _handleAuthChanged,
      onError: _handleAuthError,
    );
    unawaited(_startIntro());
  }

  void _handleAuthChanged(AppUser? user) {
    if (!mounted) return;
    final enteringAccount = _authResolved && _user == null && user != null;
    setState(() {
      _user = user;
      _authError = null;
      _authResolved = true;
    });
    if (enteringAccount) unawaited(_startIntro());
  }

  void _handleAuthError(Object error) {
    if (!mounted) return;
    setState(() {
      _authError = error;
      _authResolved = true;
    });
  }

  void _handleVideoState() {
    if (_videoController.value.isCompleted) {
      unawaited(_finishIntro());
    }
  }

  Future<void> _startIntro() async {
    if (_startingIntro || _finishingIntro) return;
    _startingIntro = true;
    _failsafeTimer?.cancel();
    _failsafeTimer = Timer(
      const Duration(seconds: 4),
      () => unawaited(_finishIntro()),
    );
    if (mounted) {
      setState(() => _introCompleted = false);
    }
    try {
      if (!_videoController.value.isInitialized) {
        await _videoController.initialize();
      }
      await _videoController.setLooping(false);
      await _videoController.setVolume(0);
      await _videoController.seekTo(Duration.zero);
      if (!mounted) return;
      setState(() => _videoReady = true);
      await _videoController.play();
    } catch (_) {
      await _finishIntro();
    } finally {
      _startingIntro = false;
    }
  }

  Future<void> _finishIntro() async {
    if (!mounted || _introCompleted || _finishingIntro) return;
    _finishingIntro = true;
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
    setState(() {
      _introCompleted = true;
      _finishingIntro = false;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _failsafeTimer?.cancel();
    _videoController.removeListener(_handleVideoState);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_introCompleted || !_authResolved) {
      return _VittaIntro(
        controller: _videoController,
        videoReady: _videoReady,
        showProgress: _introCompleted && !_authResolved,
      );
    }
    if (_authError != null) {
      return LoginScreen(
        authRepository: _repository,
        initialErrorMessage: mapSignInError(_authError!),
        navigateAfterSignIn: false,
      );
    }
    if (_user == null) {
      return LoginScreen(
        authRepository: _repository,
        navigateAfterSignIn: false,
      );
    }
    return HomeScreen(authRepository: _repository);
  }
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
