const passwordRequirements =
    'Use pelo menos 8 caracteres, incluindo letra maiúscula, letra minúscula, número e símbolo.';

enum PasswordStrength { empty, weak, medium, strong }

PasswordStrength passwordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.empty;

  var score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[a-z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\;\[\]`~]').hasMatch(password)) {
    score++;
  }

  if (score == 5 && !RegExp(r'\s').hasMatch(password)) {
    return PasswordStrength.strong;
  }
  if (score >= 3) return PasswordStrength.medium;
  return PasswordStrength.weak;
}

String? validateStrongPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Informe a senha.';
  if (password.length < 8) {
    return 'A senha deve ter pelo menos 8 caracteres.';
  }
  if (RegExp(r'\s').hasMatch(password)) {
    return 'A senha não pode conter espaços.';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Inclua pelo menos uma letra maiúscula.';
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Inclua pelo menos uma letra minúscula.';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return 'Inclua pelo menos um número.';
  }
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\;\[\]`~]').hasMatch(password)) {
    return 'Inclua pelo menos um símbolo.';
  }
  return null;
}

String? validatePasswordConfirmation(String? value, String password) {
  if ((value ?? '').isEmpty) return 'Confirme a senha.';
  if (value != password) return 'As senhas não coincidem.';
  return null;
}
