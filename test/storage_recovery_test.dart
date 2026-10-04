import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';

import 'web/save_model_test.dart' show child, family;

void main() {
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
