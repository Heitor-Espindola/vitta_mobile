import 'package:vitta_mobile/core/input_formatters/cpf_input_formatter.dart';

String? validateCpf(String? value) {
  final digits = cpfDigitsOnly(value ?? '');
  if (digits.isEmpty) return 'Informe seu CPF.';
  if (digits.length != 11) return 'CPF incompleto.';
  if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return 'CPF inválido.';

  int checkDigit(int length) {
    var sum = 0;
    for (var index = 0; index < length; index++) {
      sum += int.parse(digits[index]) * (length + 1 - index);
    }
    final remainder = (sum * 10) % 11;
    return remainder == 10 ? 0 : remainder;
  }

  if (checkDigit(9) != int.parse(digits[9]) ||
      checkDigit(10) != int.parse(digits[10])) {
    return 'CPF inválido.';
  }
  return null;
}
