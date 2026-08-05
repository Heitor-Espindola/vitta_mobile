String normalizeEmail(String email) => email.trim().toLowerCase();

String? validateGmail(String? value) {
  final rawEmail = value ?? '';
  final email = normalizeEmail(rawEmail);
  final trimmedEmail = rawEmail.trim();

  if (email.isEmpty) return 'Informe seu Gmail.';
  if (trimmedEmail.contains(RegExp(r'\s')) ||
      '@'.allMatches(email).length != 1 ||
      email.startsWith('@')) {
    return 'Digite um Gmail válido.';
  }
  if (!email.endsWith('@gmail.com')) {
    return 'Utilize um endereço terminado em @gmail.com.';
  }

  final localPart = email.substring(0, email.length - '@gmail.com'.length);
  if (localPart.isEmpty ||
      localPart.startsWith('.') ||
      localPart.endsWith('.') ||
      localPart.contains('..') ||
      !RegExp(r'^[a-z0-9._%+-]+$').hasMatch(localPart)) {
    return 'Digite um Gmail válido.';
  }
  return null;
}
