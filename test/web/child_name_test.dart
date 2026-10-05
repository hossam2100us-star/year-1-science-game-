import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/validation.dart';

String typed(String input) {
  var value = const TextEditingValue();
  for (final formatter in ChildName.inputFormatters) {
    value = formatter.formatEditUpdate(
      const TextEditingValue(),
      value.copyWith(
        text: value.text.isEmpty ? input : value.text,
        selection: TextSelection.collapsed(offset: input.length),
      ),
    );
  }
  return value.text;
}

void main() {
  group('Child name validation (SEC-05)', () {
    test('accepts Arabic and English first names', () {
      for (final name in [
        'Nour',
        'نور',
        'سَلْمَى',
        'Anne-Marie',
        "O'Neil",
        'Mary Jane',
        '',
      ]) {
        expect(ChildName.isValid(name), isTrue, reason: name);
        expect(typed(name), name, reason: name);
      }
    });

    test('rejects markup, digits, control characters and emoji', () {
      for (final name in ['<script>', 'Nour1', 'a\nb', 'Nour 😀', 'x' * 25]) {
        expect(ChildName.isValid(name), isFalse, reason: name);
      }
    });

    test('typing strips characters that are not allowed', () {
      expect(typed('<b>Nour</b>'), 'bNourb');
      expect(typed('Nour2026'), 'Nour');
      expect(typed('x' * 30).length, ChildName.maxLength);
    });
  });
}
