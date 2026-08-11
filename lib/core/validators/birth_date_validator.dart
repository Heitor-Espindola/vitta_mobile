DateTime? parseBirthDate(String value) {
  final parts = value.trim().split('/');
  if (parts.length != 3 ||
      parts[0].length != 2 ||
      parts[1].length != 2 ||
      parts[2].length != 4) {
    return null;
  }
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null || year < 1900) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

String? validateBirthDate(String? value, {DateTime? today}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Informe sua data de nascimento.';
  if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(text)) {
    return 'Digite a data no formato DD/MM/AAAA.';
  }
  final date = parseBirthDate(text);
  if (date == null) return 'Data de nascimento inválida.';
  final reference = today ?? DateTime.now();
  final currentDate = DateTime(reference.year, reference.month, reference.day);
  if (date.isAfter(currentDate)) return 'A data não pode estar no futuro.';
  return null;
}
