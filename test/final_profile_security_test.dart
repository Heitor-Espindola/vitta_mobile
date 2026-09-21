import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/profile/presentation/profile_detail_screens.dart';
import 'package:vitta_mobile/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets(
    'profile has no redundant Editar or Muuni and protected identity',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ProfileScreen(authRepository: _AuthFake())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Editar'), findsNothing);
      expect(find.text('Muuni'), findsNothing);
      await tester.tap(
        find.textContaining('Dados pessoais', findRichText: true).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('CPF'), findsWidgets);
      expect(find.text('Data de nascimento'), findsWidgets);
      expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'CPF'), findsNothing);
      expect(
        find.widgetWithText(TextFormField, 'Data de nascimento'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('real email verification state can be resent and refreshed', (
    tester,
  ) async {
    var resends = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AccountSecurityScreen(
          email: 'pessoa@example.com',
          authRepository: _AuthFake(),
          emailVerified: false,
          sendVerificationEmail: () async {
            resends++;
          },
          reloadEmailVerified: () async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('E-mail não verificado'), findsOneWidget);
    expect(find.text('Autenticação'), findsNothing);
    expect(find.text('Sessão protegida pelo Firebase'), findsNothing);
    await tester.tap(find.text('Reenviar e-mail de verificação'));
    await tester.pump();
    expect(resends, 1);
    expect(
      find.textContaining('E-mail de verificação enviado'),
      findsOneWidget,
    );
    await tester.tap(find.text('Já confirmei meu e-mail'));
    await tester.pumpAndSettle();
    expect(find.text('E-mail verificado'), findsOneWidget);
    expect(find.text('Reenviar e-mail de verificação'), findsNothing);
  });

  testWidgets(
    'password reset uses authenticated email with friendly feedback',
    (tester) async {
      final repository = _AuthFake();
      await tester.pumpWidget(
        MaterialApp(
          home: AccountSecurityScreen(
            email: 'pessoa@example.com',
            authRepository: repository,
            emailVerified: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Redefinir senha'));
      await tester.pump();
      expect(repository.resetEmail, 'pessoa@example.com');
      expect(
        find.text(
          'Instruções para redefinir sua senha foram enviadas para seu e-mail.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'help, terms and security remain scrollable with Android system bar',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 30);
      tester.view.viewPadding = const FakeViewPadding(bottom: 30);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      for (final page in [
        const HelpCenterScreen(),
        const TermsPrivacyScreen(),
        AccountSecurityScreen(
          email: 'pessoa@example.com',
          authRepository: _AuthFake(),
          emailVerified: true,
        ),
      ]) {
        await tester.pumpWidget(MaterialApp(home: page));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getBottomRight(find.byType(ListView).first).dy,
          lessThanOrEqualTo(538),
        );
      }
    },
  );
}

class _AuthFake implements AuthRepository {
  String? resetEmail;
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetEmail = email;
  }

  @override
  Future<AppUser?> getCurrentUser() async => const AppUser(
    uid: 'owner',
    name: 'Pessoa Teste',
    email: 'pessoa@example.com',
    cpf: '12345678909',
    birthDate: null,
    role: 'responsible',
  );
  @override
  Stream<AppUser?> authStateChanges() => Stream.value(null);
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
