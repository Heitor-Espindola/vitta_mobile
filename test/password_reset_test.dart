import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/validators/gmail_validator.dart';
import 'package:vitta_mobile/features/auth/presentation/auth_error_mapper.dart';
import 'package:vitta_mobile/features/auth/presentation/controllers/password_reset_controller.dart';
import 'package:vitta_mobile/features/auth/presentation/login_screen.dart';

void main() {
  group('Gmail validation and normalization', () {
    test('rejects empty Gmail', () {
      expect(validateGmail(''), 'Informe seu Gmail.');
    });

    test('rejects invalid Gmail', () {
      expect(validateGmail('sem-arroba'), 'Digite um Gmail válido.');
    });

    test('rejects a non-Gmail domain', () {
      expect(
        validateGmail('pessoa@example.com'),
        'Utilize um endereço terminado em @gmail.com.',
      );
    });

    test('accepts a valid Gmail', () {
      expect(validateGmail('pessoa@gmail.com'), isNull);
    });

    test('normalizes case and surrounding spaces', () {
      expect(normalizeEmail('  Pessoa@GMAIL.COM  '), 'pessoa@gmail.com');
    });
  });

  group('PasswordResetController', () {
    test('normalizes Gmail before sending', () async {
      final repository = FakeAuthRepository();
      final controller = PasswordResetController(repository);

      expect(
        await controller.sendPasswordReset('  Pessoa@GMAIL.COM  '),
        isTrue,
      );
      expect(repository.lastResetEmail, 'pessoa@gmail.com');
      expect(controller.isLoading, isFalse);
    });

    test('exposes loading and blocks simultaneous sends', () async {
      final completer = Completer<void>();
      final repository = FakeAuthRepository(onReset: (_) => completer.future);
      final controller = PasswordResetController(repository);

      final first = controller.sendPasswordReset('pessoa@gmail.com');
      expect(controller.isLoading, isTrue);
      expect(await controller.sendPasswordReset('pessoa@gmail.com'), isFalse);
      expect(repository.resetCalls, 1);

      completer.complete();
      expect(await first, isTrue);
      expect(controller.isLoading, isFalse);
    });

    for (final entry in <String, String>{
      'invalid-email': 'Digite um Gmail válido.',
      'too-many-requests':
          'Muitas solicitações. Aguarde alguns minutos e tente novamente.',
      'network-request-failed':
          'Não foi possível conectar. Verifique sua internet.',
    }.entries) {
      test('maps ${entry.key}', () async {
        final repository = FakeAuthRepository(
          onReset: (_) => throw FirebaseAuthException(code: entry.key),
        );
        final controller = PasswordResetController(repository);

        expect(await controller.sendPasswordReset('pessoa@gmail.com'), isFalse);
        expect(controller.lastError, entry.value);
      });
    }

    test('treats user-not-found as neutral success', () async {
      final repository = FakeAuthRepository(
        onReset: (_) => throw FirebaseAuthException(code: 'user-not-found'),
      );
      final controller = PasswordResetController(repository);

      expect(await controller.sendPasswordReset('pessoa@gmail.com'), isTrue);
      expect(controller.lastError, isNull);
    });
  });

  group('Password reset dialog', () {
    testWidgets('closes after success and shows neutral message', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(authRepository: FakeAuthRepository())),
      );

      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('password-reset-email')),
        'pessoa@gmail.com',
      );
      await tester.tap(find.byKey(const Key('password-reset-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Recuperar senha'), findsNothing);
      expect(find.text(passwordResetNeutralMessage), findsOneWidget);
    });

    testWidgets('keeps dialog open after remote error', (tester) async {
      final repository = FakeAuthRepository(
        onReset: (_) => throw FirebaseAuthException(code: 'too-many-requests'),
      );
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(authRepository: repository)),
      );

      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('password-reset-email')),
        'pessoa@gmail.com',
      );
      await tester.tap(find.byKey(const Key('password-reset-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Recuperar senha'), findsOneWidget);
      expect(
        find.text(
          'Muitas solicitações. Aguarde alguns minutos e tente novamente.',
        ),
        findsOneWidget,
      );
    });
  });
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.onReset});

  final Future<void> Function(String email)? onReset;
  String? lastResetEmail;
  int resetCalls = 0;

  @override
  Future<void> sendPasswordResetEmail(String email) {
    lastResetEmail = email;
    resetCalls++;
    return onReset?.call(email) ?? Future.value();
  }

  @override
  Stream<AppUser?> authStateChanges() => const Stream.empty();

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
  }) => throw UnimplementedError();

  @override
  Future<AppUser> updateProfile(AppUser user) async => user;
}
