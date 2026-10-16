import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// UTF-8 text read once with the wrong encoding and saved again shows
/// children things like "Savingâ€¦" (found during teacher review 4). No
/// source, content or translation file may contain such sequences.
void main() {
  test('no mis-encoded UTF-8 in code, content or translations', () {
    final broken = RegExp('â€|Ã[ -¿]|Â[ -¿]');
    final offenders = <String>[];
    for (final root in ['lib', 'assets/content', 'web']) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File) continue;
        final path = entity.path.replaceAll('\\', '/');
        if (!RegExp(r'\.(dart|json|arb|html)$').hasMatch(path)) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (broken.hasMatch(lines[i])) offenders.add('$path:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
