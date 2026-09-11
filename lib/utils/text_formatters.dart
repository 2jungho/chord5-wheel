import 'package:flutter/services.dart';

/// 첫 글자를 영문 대문자로 강제 변환하는 포매터
class FirstLetterUppercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      if (newValue.composing.isValid) {
        return newValue.copyWith(composing: TextRange.empty);
      }
      return newValue;
    }

    final text = newValue.text;
    final uppercaseText = text[0].toUpperCase() + text.substring(1);

    if (text == uppercaseText &&
        newValue.selection.end <= text.length &&
        newValue.composing.end <= text.length) {
      return newValue;
    }

    return newValue.copyWith(
      text: uppercaseText,
      selection: newValue.selection.copyWith(
        baseOffset:
            newValue.selection.baseOffset.clamp(0, uppercaseText.length),
        extentOffset:
            newValue.selection.extentOffset.clamp(0, uppercaseText.length),
      ),
      composing: TextRange.empty,
    );
  }
}
