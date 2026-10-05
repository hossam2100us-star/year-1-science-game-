import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against repository bloat (AUD-012): every image in assets/images is
/// bundled, and every bundled image exists.
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final listed = RegExp(
    r'^\s*-\s*(assets/images/\S+)\s*$',
    multiLine: true,
  ).allMatches(pubspec).map((m) => m.group(1)!).toSet();

  test('every image file in assets/images is bundled', () {
    final files = Directory('assets/images')
        .listSync()
        .whereType<File>()
        .map((f) => 'assets/images/${f.uri.pathSegments.last}')
        .toSet();
    expect(files.difference(listed), isEmpty);
  });

  test('every bundled image exists', () {
    for (final path in listed) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('no Dart file is left unreachable from an entry point', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    final text = {
      for (final f in sources)
        f.path.replaceAll('\\', '/'): f.readAsStringSync(),
    };
    // A directive may name several files (conditional imports), so collect
    // every quoted path up to its semicolon.
    final directive = RegExp(
      r'^(?:import|export|part)\s[^;]*;',
      multiLine: true,
    );
    final quoted = RegExp(r"'([^']+)'");
    final reached = <String>{};
    void visit(String path) {
      if (!reached.add(path) || !text.containsKey(path)) return;
      final targets = [
        for (final d in directive.allMatches(text[path]!))
          for (final q in quoted.allMatches(d.group(0)!)) q.group(1)!,
      ];
      for (final target in targets) {
        if (!target.endsWith('.dart') ||
            target.startsWith('dart:') ||
            (target.startsWith('package:') &&
                !target.startsWith('package:science_adventure/'))) {
          continue;
        }
        final resolved = target.startsWith('package:science_adventure/')
            ? 'lib/${target.substring('package:science_adventure/'.length)}'
            : Uri.parse(path).resolve(target).path;
        visit(resolved);
      }
    }

    visit('lib/main.dart');
    visit('lib/main_preview.dart');
    final unreachable = text.keys.where((p) => !reached.contains(p)).toList();
    expect(unreachable, isEmpty);
  });
}
