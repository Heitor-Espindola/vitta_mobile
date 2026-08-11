import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';

String? validateFullName(String? value) {
  final original = value ?? '';
  final name = formatPersonName(original);
  if (name.isEmpty) return 'Informe seu nome completo.';
  if (original != original.trim() || RegExp(r'\s{2,}').hasMatch(original)) {
    return 'Remova espaços extras do nome.';
  }
  final parts = name.split(' ');
  if (parts.length < 2 || parts.any((part) => part.length < 2)) {
    return 'Informe nome e sobrenome.';
  }
  if (!RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ' ]+$").hasMatch(name)) {
    return 'Use apenas letras no nome.';
  }
  return null;
}
