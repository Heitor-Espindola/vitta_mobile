import 'package:flutter/services.dart';

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final formatted = formatCpf(limited);
    final digitsBeforeCursor = newValue.text
        .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, limited.length);
    final cursor = _cursorAfterDigits(formatted, digitsBeforeCursor);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

String cpfDigitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

String formatCpf(String digitsOrFormatted) {
  final source = cpfDigitsOnly(digitsOrFormatted);
  final digits = source.length > 11 ? source.substring(0, 11) : source;
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index == 3 || index == 6) buffer.write('.');
    if (index == 9) buffer.write('-');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

int _cursorAfterDigits(String formatted, int digitCount) {
  if (digitCount == 0) return 0;
  var seen = 0;
  for (var index = 0; index < formatted.length; index++) {
    if (RegExp(r'\d').hasMatch(formatted[index])) seen++;
    if (seen == digitCount) return index + 1;
  }
  return formatted.length;
}
