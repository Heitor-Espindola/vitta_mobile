import 'package:flutter/services.dart';

class NameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = formatPersonNameInput(newValue.text);
    final baseOffset = _formattedOffset(
      newValue.text,
      newValue.selection.baseOffset,
    );
    final extentOffset = _formattedOffset(
      newValue.text,
      newValue.selection.extentOffset,
    );
    return TextEditingValue(
      text: normalized,
      selection: TextSelection(
        baseOffset: baseOffset.clamp(0, normalized.length),
        extentOffset: extentOffset.clamp(0, normalized.length),
      ),
      composing: TextRange.empty,
    );
  }
}

String formatPersonNameInput(String value) {
  final buffer = StringBuffer();
  var previousWasSpace = true;
  var capitalizeNext = true;

  for (final rune in value.runes) {
    final character = String.fromCharCode(rune);
    if (character == ' ') {
      if (!previousWasSpace && buffer.isNotEmpty) {
        buffer.write(' ');
        previousWasSpace = true;
        capitalizeNext = true;
      }
      continue;
    }
    if (!_isNameCharacter(character)) continue;
    buffer.write(
      capitalizeNext ? character.toUpperCase() : character.toLowerCase(),
    );
    previousWasSpace = false;
    capitalizeNext = false;
  }
  return buffer.toString();
}

String formatPersonName(String value) => formatPersonNameInput(value).trim();

String normalizedPersonName(String value) =>
    formatPersonName(value).toLowerCase();

bool _isNameCharacter(String character) =>
    character == "'" || RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]').hasMatch(character);

int _formattedOffset(String source, int sourceOffset) {
  final safeOffset = sourceOffset.clamp(0, source.length);
  return formatPersonNameInput(source.substring(0, safeOffset)).length;
}
