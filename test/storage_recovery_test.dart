import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';

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

  group('HiveProgressStore recovery (AUD-006)', () {
    late Directory dir;
    late Box<String> box;
    var now = DateTime.utc(2026, 10, 4, 9);

    Future<HiveProgressStore> openStore() async {
      box = await Hive.openBox<String>('recovery_test');
      return HiveProgressStore(box, clock: () => now);
    }

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('science_store_');
      Hive.init(dir.path);
      now = DateTime.utc(2026, 10, 4, 9);
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('a round trip writes the data and a last good copy', () async {
      final store = await openStore();
      final data = AppData.fromJson(family({'a': child('Nour')}, 'a'));
      await store.write(data);
      expect(store.read().profile!.name, 'Nour');
      expect(box.get(HiveProgressStore.backupKey), box.get('data'));
      expect(store.recovery, StorageRecovery.none);
    });

    test('an unreadable main copy falls back to the last good copy and is '
        'preserved before the next save', () async {
      final store = await openStore();
      await store.write(AppData.fromJson(family({'a': child('Nour')}, 'a')));
      await box.put('data', '{"schemaVersion": 3, "children": tru');

      final restored = store.read();
      expect(restored.profile!.name, 'Nour');
      expect(store.recovery, StorageRecovery.restoredFromBackup);
      expect(store.hasUnreadableCopies, isTrue);

      await store.write(restored.copyWith(pendingPhoto: true));
      expect(
        box.get(HiveProgressStore.unreadableKey),
        '{"schemaVersion": 3, "children": tru',
      );
      final export = jsonDecode(store.rescueExport()) as Map;
      expect(export['unreadableCopy'], contains('children'));
      expect(export['format'], 'science-adventure-rescue-v1');
    });

    test('when both copies are unreadable nothing is deleted', () async {
      final store = await openStore();
      await box.put('data', 'garbage');
      await box.put(HiveProgressStore.backupKey, 'also garbage');
      expect(store.read, throwsA(isA<SaveDataUnreadable>()));
      expect(box.get('data'), 'garbage');

      await store.startAgainKeepingCopy();
      expect(store.read().profile, isNull);
      final export = jsonDecode(store.rescueExport()) as Map;
      expect(export['unreadableCopy'], 'garbage');
      expect(export['unreadableLastGoodCopy'], 'also garbage');

      await store.discardUnreadableCopies();
      expect(store.hasUnreadableCopies, isFalse);
    });

    test('saving over an unreadable previous copy does not fail', () async {
      final store = await openStore();
      await box.put('data', 'garbage');
      await store.write(AppData.fromJson(family({'a': child('Nour')}, 'a')));
      expect(store.read().profile!.name, 'Nour');
    });

    test('the last good copy is refreshed at most every 10 minutes', () async {
      final store = await openStore();
      final data = AppData.fromJson(family({'a': child('Nour')}, 'a'));
      await store.write(data);
      final first = box.get(HiveProgressStore.backupKey);

      now = now.add(const Duration(minutes: 1));
      await store.write(data.copyWith(pendingPhoto: true));
      expect(box.get(HiveProgressStore.backupKey), first);

      now = now.add(const Duration(minutes: 10));
      await store.write(data.copyWith(pendingPhoto: true));
      expect(box.get(HiveProgressStore.backupKey), box.get('data'));
    });

    test('deleting a child also removes it from the last good copy', () async {
      final store = await openStore();
      final data = AppData.fromJson(
        family({'a': child('Nour'), 'b': child('Adam')}, 'a'),
      );
      await store.write(data);
      now = now.add(const Duration(minutes: 1));
      await store.write(data.removeChild('b', emptyId: 'e'));
      expect(box.get(HiveProgressStore.backupKey), isNot(contains('Adam')));
      expect(box.get('data'), isNot(contains('Adam')));
    });
  });
}
