import 'package:flutter/services.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final source = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digits = source.length > 8 ? source.substring(0, 8) : source;
    final formatted = formatDateDigits(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String formatDateDigits(String digitsOrFormatted) {
  final source = digitsOrFormatted.replaceAll(RegExp(r'\D'), '');
  final digits = source.length > 8 ? source.substring(0, 8) : source;
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index == 2 || index == 4) buffer.write('/');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
