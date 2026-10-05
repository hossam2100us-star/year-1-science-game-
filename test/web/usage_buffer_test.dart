import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/core/usage_buffer.dart';

void main() {
  final t0 = DateTime(2026, 10, 5, 9);
  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

  group('UsageBuffer (AUD-004)', () {
    late List<(String, DateTime, DateTime)> writes;
    late UsageBuffer buffer;
    setUp(() {
      writes = [];
      buffer = UsageBuffer((owner, from, to) async {
        writes.add((owner, from, to));
      });
    });

    test('10-second ticks become one write per minute', () async {
      for (var s = 0; s < 120; s += 10) {
        await buffer.add(at(s), at(s + 10), 'nour');
      }
      expect(writes, [('nour', at(0), at(60)), ('nour', at(60), at(120))]);
      expect(buffer.pending, Duration.zero);
    });

    test('stopping play writes the partial minute', () async {
      await buffer.add(at(0), at(10), 'nour');
      await buffer.add(at(10), at(20), 'nour');
      expect(writes, isEmpty);
      await buffer.flush();
      expect(writes, [('nour', at(0), at(20))]);
      await buffer.flush();
      expect(writes, hasLength(1), reason: 'nothing is written twice');
    });

    test('a gap or another child starts a new span', () async {
      await buffer.add(at(0), at(10), 'nour');
      await buffer.add(at(30), at(40), 'nour'); // paused in between
      await buffer.add(at(40), at(50), 'adam'); // switched child
      await buffer.flush();
      expect(writes, [
        ('nour', at(0), at(10)),
        ('nour', at(30), at(40)),
        ('adam', at(40), at(50)),
      ]);
    });

    test('a failed write is reported to the caller', () async {
      final failing = UsageBuffer((_, _, _) async => throw StateError('full'));
      await failing.add(at(0), at(10), 'nour'); // First tick: no write yet.
      await expectLater(failing.flush(), throwsStateError);
    });
  });

  test('buffered time is credited to the child who played', () async {
    final data = const AppData(profile: ChildProfile(name: 'Nour'))
        .addChild('adam', const ChildProfile(name: 'Adam'));
    final store = MemoryProgressStore(data);
    final container = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final controller = container.read(appProvider.notifier);
    // Adam is active, but these 30 s were played by Nour.
    await controller.usageFor('local-child', at(0), at(30));
    expect(store.data.dailySeconds, isEmpty);
    expect(store.data.selectChild('local-child').dailySeconds, {
      '2026-10-05': 30,
    });
    await controller.usageFor('deleted', at(0), at(30));
    expect(
      store.data.childRecords.keys,
      unorderedEquals(['local-child', 'adam']),
    );
  });
}
