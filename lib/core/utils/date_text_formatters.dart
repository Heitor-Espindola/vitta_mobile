import 'package:vitta_mobile/core/validators/birth_date_validator.dart';

DateTime? parseBrazilianDate(String value) => parseBirthDate(value);

String formatBrazilianDate(DateTime? date) {
  if (date == null) {
    return '';
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
