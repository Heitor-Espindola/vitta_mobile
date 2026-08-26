import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/core/validators/password_validator.dart';
import 'package:vitta_mobile/features/auth/presentation/login_screen.dart';
import 'package:vitta_mobile/features/auth/presentation/register_screen.dart';

void main() {
  group('strong password validation', () {
    test('requires every password strength component', () {
      expect(validateStrongPassword(''), 'Informe a senha.');
      expect(
        validateStrongPassword('Ab1!'),
        'A senha deve ter pelo menos 8 caracteres.',
      );
      expect(
        validateStrongPassword('senha@123'),
        'Inclua pelo menos uma letra maiúscula.',
      );
      expect(
        validateStrongPassword('SENHA@123'),
        'Inclua pelo menos uma letra minúscula.',
      );
      expect(
        validateStrongPassword('Senha@forte'),
        'Inclua pelo menos um número.',
      );
      expect(
        validateStrongPassword('Senha123'),
        'Inclua pelo menos um símbolo.',
      );
      expect(validateStrongPassword('Senha@123'), isNull);
    });

    test('requires matching password confirmation', () {
      expect(
        validatePasswordConfirmation('', 'Senha@123'),
        'Confirme a senha.',
      );
      expect(
        validatePasswordConfirmation('Senha@124', 'Senha@123'),
        'As senhas não coincidem.',
      );
      expect(validatePasswordConfirmation('Senha@123', 'Senha@123'), isNull);
    });

    test('classifies visual strength levels', () {
      expect(passwordStrength(''), PasswordStrength.empty);
      expect(passwordStrength('abc'), PasswordStrength.weak);
      expect(passwordStrength('Senha123'), PasswordStrength.medium);
      expect(passwordStrength('Senha@123'), PasswordStrength.strong);
    });
  });

  testWidgets('login password visibility can be toggled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    final passwordField = find.widgetWithText(TextFormField, 'Senha');
    bool isObscured() => tester
        .widget<EditableText>(
          find.descendant(
            of: passwordField,
            matching: find.byType(EditableText),
          ),
        )
        .obscureText;

    expect(isObscured(), isTrue);
    await tester.tap(find.byKey(const Key('login-password-visibility')));
    await tester.pump();
    expect(isObscured(), isFalse);
    expect(find.byTooltip('Ocultar senha'), findsOneWidget);
  });

  testWidgets('registration password fields can be toggled independently', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    final passwordField = find.widgetWithText(TextFormField, 'Senha');
    final confirmationField = find.widgetWithText(
      TextFormField,
      'Confirmar senha',
    );
    bool isObscured(Finder field) => tester
        .widget<EditableText>(
          find.descendant(of: field, matching: find.byType(EditableText)),
        )
        .obscureText;

    expect(isObscured(passwordField), isTrue);
    expect(isObscured(confirmationField), isTrue);

    await tester.enterText(passwordField, 'abc');
    await tester.pump();
    expect(find.text('Senha fraca'), findsOneWidget);

    await tester.enterText(passwordField, 'Senha123');
    await tester.pump();
    expect(find.text('Senha média'), findsOneWidget);

    await tester.enterText(passwordField, 'Senha@123');
    await tester.pump();
    expect(find.text('Senha forte'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('register-password-visibility')),
    );
    await tester.tap(find.byKey(const Key('register-password-visibility')));
    await tester.pump();
    expect(isObscured(passwordField), isFalse);
    expect(isObscured(confirmationField), isTrue);

    await tester.ensureVisible(
      find.byKey(const Key('register-password-confirmation-visibility')),
    );
    await tester.tap(
      find.byKey(const Key('register-password-confirmation-visibility')),
    );
    await tester.pump();
    expect(isObscured(confirmationField), isFalse);
  });
}
