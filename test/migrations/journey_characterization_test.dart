import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/lesson.dart';
import 'package:science_adventure/features/biology/session.dart';

import 'journey_corpus.dart';

/// Records what LessonSession.restore produced before the refactor for every
/// case in the corpus (4,000+ saved journeys), so the migration registry
/// (AUD-007) can be proven to give identical results.
///
/// The fixture stores a fingerprint of each restored journey (canonical JSON
/// with sorted keys, FNV-1a 64-bit), not the full JSON, to stay small.
/// Regenerate only on purpose, before changing restore behaviour:
///     flutter test test/migrations --dart-define=UPDATE_MIGRATION_FIXTURES=true
const _update = bool.fromEnvironment('UPDATE_MIGRATION_FIXTURES');
const fixturePath = 'test/fixtures/journey_migrations.json';

Map<String, dynamic> restoredJson(Lesson lesson, Map<String, dynamic> saved) {
  // Deep copy: restore mutates the maps it is given.
  final input = jsonDecode(jsonEncode(saved)) as Map<String, dynamic>;
  if (!LessonSession.canRestore(lesson, input)) return {'canRestore': false};
  final session = LessonSession.restore(lesson, input);
  return jsonDecode(jsonEncode(session.toJson())) as Map<String, dynamic>;
}

Object? _canonical(Object? value) => switch (value) {
  final Map<dynamic, dynamic> map => {
    for (final key in map.keys.map((k) => '$k').toList()..sort())
      key: _canonical(map[key]),
  },
  final List<dynamic> list => [for (final v in list) _canonical(v)],
  _ => value,
};

String fingerprint(Object? value) {
  final bytes = utf8.encode(jsonEncode(_canonical(value)));
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final b in bytes) {
    hash = ((hash ^ BigInt.from(b)) * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('journey restore matches the recorded characterization', () async {
    final library = await LessonLibrary.load();
    final corpus = journeyCorpus(library);
    final actual = {
      for (final c in corpus)
        c.name: fingerprint(
          restoredJson(library.lessons[c.lessonId]!, c.saved),
        ),
    };
    final file = File(fixturePath);
    if (_update) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        '${const JsonEncoder.withIndent(' ').convert(actual)}\n',
      );
    }
    final expected =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(actual.keys.toSet(), expected.keys.toSet());
    final mismatches = [
      for (final name in expected.keys)
        if (actual[name] != expected[name]) name,
    ];
    expect(mismatches, isEmpty);
    expect(corpus.length, greaterThan(4000));
  });
}
