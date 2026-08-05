import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/core/constants/app_roles.dart';
import 'package:vitta_mobile/features/auth/data/cpf_registry_key.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';

void main() {
  test('CPF registry uses a stable 64-character SHA-256 key', () {
    final formatted = cpfRegistryKey('123.456.789-00');
    final digits = cpfRegistryKey('12345678900');

    expect(formatted, digits);
    expect(formatted.length, 64);
    expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(formatted), isTrue);
  });

  test('AppUser writes the unified user document fields', () {
    final user = AppUser(
      uid: 'auth-uid',
      name: 'Maria da Silva',
      email: 'maria@gmail.com',
      role: AppRoles.responsible,
      cpf: '123.456.789-00',
      birthDate: DateTime(1990, 1, 2),
      createdAt: DateTime(2026, 8, 5),
      updatedAt: DateTime(2026, 8, 5),
    );

    final map = user.toMap();
    expect(map['id'], 'auth-uid');
    expect(map['authUid'], 'auth-uid');
    expect(map['cpf'], '12345678900');
    expect(map['cpfDigits'], '12345678900');
    expect(map['cpfFormatted'], '123.456.789-00');
    expect(map['roles'], ['user']);
    expect(map['guardianIds'], isEmpty);
    expect(map['dependentIds'], isEmpty);
    expect(map['managedByUserIds'], isEmpty);
    expect(map.containsKey('lastLoginAt'), isTrue);
    expect(map.containsKey('photoUrl'), isTrue);
  });
}
