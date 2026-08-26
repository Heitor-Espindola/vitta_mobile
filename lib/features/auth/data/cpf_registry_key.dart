import 'dart:convert';

import 'package:crypto/crypto.dart';

String cpfDigitsOnly(String cpf) => cpf.replaceAll(RegExp(r'\D'), '');

String cpfRegistryKey(String cpf) {
  return sha256.convert(utf8.encode(cpfDigitsOnly(cpf))).toString();
}
