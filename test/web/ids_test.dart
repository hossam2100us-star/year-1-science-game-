import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/ids.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';

void main() {
  group('Ids.uuidV7', () {
    test('produces canonical version-7 UUIDs', () {
      for (var i = 0; i < 200; i++) {
        final id = Ids.uuidV7();
        expect(Ids.isUuid(id), isTrue, reason: id);
        expect(id[14], '7');
        expect('89ab'.contains(id[19]), isTrue);
      }
    });

    test('encodes the millisecond timestamp in the first 48 bits', () {
      final at = DateTime.utc(2026, 10, 4, 12, 30, 15, 123);
      final id = Ids.uuidV7(now: at, random: Random(1));
      final millis = int.parse(
        id.replaceAll('-', '').substring(0, 12),
        radix: 16,
      );
      expect(millis, at.millisecondsSinceEpoch);
    });

    test('sorts by creation time', () {
      final earlier = Ids.uuidV7(now: DateTime.utc(2026, 1, 1));
      final later = Ids.uuidV7(now: DateTime.utc(2026, 1, 2));
      expect(earlier.compareTo(later), lessThan(0));
    });

    test('does not collide across many draws', () {
      final ids = {for (var i = 0; i < 5000; i++) Ids.uuidV7()};
      expect(ids.length, 5000);
    });
  });

  group('AppController child IDs (AUD-005 regression)', () {
    ProviderContainer containerFor(AppData data) {
      final container = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(MemoryProgressStore(data))],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('deleting the only, active child succeeds and starts empty', () async {
      final container = containerFor(
        const AppData(profile: ChildProfile(name: 'Nour')),
      );
      await container.read(appProvider.notifier).removeChild('local-child');
      final data = container.read(appProvider);
      expect(data.profile, isNull);
      expect(data.childRecords.containsKey('local-child'), isFalse);
      expect(Ids.isUuid(data.activeChildId), isTrue);
    });

    test('adding a child assigns a UUIDv7 and makes it active', () async {
      final container = containerFor(
        const AppData(profile: ChildProfile(name: 'Nour')),
      );
      await container
          .read(appProvider.notifier)
          .addChild(const ChildProfile(name: 'Adam'));
      final data = container.read(appProvider);
      expect(Ids.isUuid(data.activeChildId), isTrue);
      expect(data.profile!.name, 'Adam');
      expect(data.childRecords.containsKey('local-child'), isTrue);
    });
  });
}
