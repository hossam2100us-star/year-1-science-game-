import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/design.dart';
import 'package:science_adventure/core/models.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (max(x, y) + .05) / (min(x, y) + .05);
}

double max(double a, double b) => a > b ? a : b;
double min(double a, double b) => a < b ? a : b;

void main() {
  test('disabled buttons stay readable on every palette (AUD-018)', () {
    for (final profile in [
      null,
      const ChildProfile(gender: ChildGender.girl),
      const ChildProfile(palette: PaletteChoice.forest),
    ]) {
      final style = adventureTheme(profile).filledButtonTheme.style!;
      const disabled = {WidgetState.disabled};
      final fill = style.backgroundColor!.resolve(disabled)!;
      final text = style.foregroundColor!.resolve(disabled)!;
      final edge = style.side!.resolve(disabled)!.color;
      expect(contrast(text, fill), greaterThanOrEqualTo(4.5));
      expect(contrast(edge, cream), greaterThanOrEqualTo(3));
      // Enabled buttons are unchanged and have no extra border.
      expect(style.side!.resolve(const {}), isNull);
    }
  });
}
