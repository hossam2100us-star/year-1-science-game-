import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/main.dart';
import 'package:science_adventure/main_preview.dart';

void main() {
  group('Preview routes stay out of production (AUD-014)', () {
    test('the production app declares no extra routes', () {
      const app = ScienceAdventureApp();
      expect(app.routes, isEmpty);
      expect(app.initialRoute, isNull);
    });

    test('lib/main.dart does not read preview query parameters', () {
      final source = File('lib/main.dart').readAsStringSync();
      expect(source, isNot(contains('queryParameters')));
      expect(source, isNot(contains('PlantLabPreview')));
    });

    test('the review build maps every preview key', () {
      expect(previewInitialRoute({}), '/');
      expect(previewInitialRoute({'preview': 'nope'}), '/');
      for (final entry in {
        'garden-v2': '/garden-preview',
        'alive-three': '/garden-preview',
        'bean-v1': '/bean-preview',
        'plants-v2': '/plants-preview',
        'plants-v3': '/plants-review',
        'light-v1': '/light-review',
        'science-v1': '/science-review',
        'biology-v1': '/biology-review',
      }.entries) {
        final route = previewInitialRoute({'preview': entry.key});
        expect(route, entry.value);
        expect(previewRoutes({}).containsKey(route), isTrue);
      }
    });
  });
}
