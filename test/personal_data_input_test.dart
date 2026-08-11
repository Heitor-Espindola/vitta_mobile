import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/core/input_formatters/cpf_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/date_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';
import 'package:vitta_mobile/core/validators/birth_date_validator.dart';
import 'package:vitta_mobile/core/validators/cpf_validator.dart';
import 'package:vitta_mobile/core/validators/full_name_validator.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';

void main() {
  group('full name', () {
    test('capitalizes letters and accents and collapses spaces', () {
      final result = NameInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '  alice    carvalho     libralon 123',
          selection: TextSelection.collapsed(offset: 37),
        ),
      );
      expect(result.text, 'Alice Carvalho Libralon ');
    });

    test('normalizes uppercase consistently', () {
      expect(formatPersonName('EDUARDO CARVALHO'), 'Eduardo Carvalho');
      expect(formatPersonName('joão da silva'), 'João Da Silva');
      expect(normalizedPersonName(' Alice  Carvalho '), 'alice carvalho');
    });

    test('requires name and surname', () {
      expect(validateFullName('Maria José'), isNull);
      expect(validateFullName('Maria'), 'Informe nome e sobrenome.');
    });
  });

  group('CPF', () {
    final formatter = CpfInputFormatter();

    TextEditingValue apply(String oldText, String newText) =>
        formatter.formatEditUpdate(
          TextEditingValue(
            text: oldText,
            selection: TextSelection.collapsed(offset: oldText.length),
          ),
          TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          ),
        );

    test('accepts only digits and applies the mask', () {
      expect(apply('', '529a982#24725').text, '529.982.247-25');
      expect(cpfDigitsOnly('529.982.247-25'), '52998224725');
    });

    test('limits input to eleven digits', () {
      expect(apply('', '52998224725123').text, '529.982.247-25');
    });

    test('allows deleting characters', () {
      expect(apply('529.982.247-25', '529.982.247-2').text, '529.982.247-2');
    });

    test('validates check digits and repeated sequences', () {
      expect(validateCpf('529.982.247-25'), isNull);
      expect(validateCpf('529.982.247-24'), 'CPF inválido.');
      expect(validateCpf('111.111.111-11'), 'CPF inválido.');
      expect(validateCpf('529.982'), 'CPF incompleto.');
    });
  });

  group('birth date', () {
    test('applies the DD/MM/YYYY mask', () {
      final result = DateInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '15082008',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );
      expect(result.text, '15/08/2008');
    });

    test('parses and validates a real date', () {
      expect(parseBirthDate('15/08/2008'), DateTime(2008, 8, 15));
      expect(
        validateBirthDate('15/08/2008', today: DateTime(2026, 8, 6)),
        isNull,
      );
    });

    test('rejects invalid days, months, old years and future dates', () {
      expect(validateBirthDate('31/02/2010'), 'Data de nascimento inválida.');
      expect(validateBirthDate('15/13/2010'), 'Data de nascimento inválida.');
      expect(validateBirthDate('01/01/1899'), 'Data de nascimento inválida.');
      expect(
        validateBirthDate('15/08/3000', today: DateTime(2026, 8, 6)),
        'A data não pode estar no futuro.',
      );
    });

    test('accepts a valid leap year and rejects an invalid one', () {
      expect(validateBirthDate('29/02/2024'), isNull);
      expect(validateBirthDate('29/02/2023'), 'Data de nascimento inválida.');
    });

    test('loads a document without birthDate as null', () {
      final user = AppUser.fromMap({
        'uid': 'uid',
        'name': 'Maria',
        'email': 'maria@gmail.com',
        'role': 'responsible',
      });
      expect(user.birthDate, isNull);
    });
  });
}
