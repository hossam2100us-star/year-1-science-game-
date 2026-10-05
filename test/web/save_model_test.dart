import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';

Map<String, dynamic> child(String name, {String gender = 'boy'}) => {
  'schemaVersion': 2,
  'profile': {
    'name': name,
    'gender': gender,
    'avatar': 1,
    'photo': null,
    'palette': 'automatic',
  },
  'settings': const AppSettings().toJson(),
  'dailySeconds': {'2026-10-01': 120},
  'pendingPhoto': false,
  'subjects': {
    'science': {
      'attempts': [
        {
          'unitId': 'unit_02',
          'completedAt': '2026-10-01T10:00:00.000',
          'objectives': {'unit02.roots': 'firstTry'},
          'completed': true,
          'effortStars': 3,
          'attemptId': 'unit_02-1',
          'contentVersion': 4,
        },
      ],
      'journeys': {
        'unit_03': {'version': 2, 'index': 1},
      },
    },
  },
};

Map<String, dynamic> family(Map<String, Object?> children, String active) => {
  'schemaVersion': 3,
  'activeChildId': active,
  'children': children,
};

void main() {
  group('Tolerant per-child parsing (AUD-006)', () {
    test('one damaged child no longer blocks the others', () {
      final damaged = child('Adam', gender: 'dragon');
      final data = AppData.fromJson(
        family({'a': child('Nour'), 'b': damaged}, 'a'),
      );
      expect(data.profile!.name, 'Nour');
      expect(data.attempts.single.attemptId, 'unit_02-1');
      expect(data.childRecords.keys, ['a']);
      expect(data.quarantinedChildren, {'b': damaged});
    });

    test('a damaged active child falls back to a readable one', () {
      final data = AppData.fromJson(
        family({'a': 'not a record', 'b': child('Adam')}, 'a'),
      );
      expect(data.activeChildId, 'b');
      expect(data.profile!.name, 'Adam');
      expect(data.quarantinedChildren['a'], 'not a record');
    });

    test(
      'when every child is damaged the game starts empty but keeps them',
      () {
        final data = AppData.fromJson(
          family({
            'a': {'schemaVersion': 99},
            'b': 42,
          }, 'a'),
        );
        expect(data.profile, isNull);
        expect(Ids.isUuid(data.activeChildId), isTrue);
        expect(data.quarantinedChildren.keys, unorderedEquals(['a', 'b']));
      },
    );

    test('quarantined records are written back verbatim', () {
      final damaged = {
        'schemaVersion': 2,
        'profile': 'garbled',
        'x': [1, 2],
      };
      final data = AppData.fromJson(
        family({'a': child('Nour'), 'b': damaged}, 'a'),
      );
      final reread = AppData.fromJson(
        jsonDecode(jsonEncode(data.toJson())) as Map<String, dynamic>,
      );
      expect(reread.quarantinedChildren['b'], damaged);
      expect(reread.profile!.name, 'Nour');
    });

    test('missing optional containers use defaults instead of failing', () {
      final record = child('Nour')
        ..remove('settings')
        ..remove('dailySeconds');
      final data = AppData.fromJson(family({'a': record}, 'a'));
      expect(data.quarantinedChildren, isEmpty);
      expect(data.settings.breakMinutes, const AppSettings().breakMinutes);
      expect(data.dailySeconds, isEmpty);
    });

    test('quarantine survives every family operation', () {
      final start = AppData.fromJson(
        family({'a': child('Nour'), 'b': child('Sara'), 'q': 7}, 'a'),
      );
      final steps = <AppData Function(AppData)>[
        (d) => d.selectChild('b'),
        (d) => d.addChild('c', const ChildProfile(name: 'Omar')),
        (d) => d.changeChild('a', (c) => c.resetProgress()),
        (d) => d.removeChild('a', emptyId: 'e'),
        (d) => d.resetProgress(),
        (d) => d.removeChild('b', emptyId: 'e'),
        (d) => d.removeChild('c', emptyId: 'e'),
      ];
      var data = start;
      for (final step in steps) {
        data = step(data);
        expect(data.quarantinedChildren, {'q': 7});
      }
    });

    test('the legacy single-child v1 save still reads', () {
      final v1 = {
        'schemaVersion': 1,
        'profile': child('Nour')['profile'],
        'settings': const AppSettings().toJson(),
        'dailySeconds': <String, int>{},
        'attempts': <Object>[],
        'journeys': <String, Object>{},
      };
      expect(AppData.fromJson(v1).profile!.name, 'Nour');
    });
  });
}
