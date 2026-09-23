import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  UnitAttempt attempt(String id, {int stars = 3}) => UnitAttempt(
    unitId: id,
    completedAt: DateTime(2026, 9, 23),
    objectives: {
      'a': DecisionOutcome.firstTry,
      'b': DecisionOutcome.afterHint,
      'c': DecisionOutcome.explained,
    },
    completed: true,
    effortStars: stars,
  );
  test(
    'First decision cannot be inflated by retries; predictions are excluded',
    () {
      final record = AttemptRecorder();
      record.record('tree', DecisionOutcome.afterHint);
      record.record('tree', DecisionOutcome.firstTry);
      record.record('prediction', DecisionOutcome.explained, assessed: false);
      expect(record.outcomes, {'tree': DecisionOutcome.afterHint});
    },
  );
  test('Effort stars and understanding are independent', () {
    final a = attempt('unit_01');
    expect(a.effortStars, 3);
    expect(a.accuracy, 1 / 3);
    expect(a.afterHint, 1);
    expect(a.explained, 1);
  });
  test('Islands and units unlock only after their prerequisite', () async {
    final catalog = await Catalog.load();
    var data = const AppData();
    expect(catalog.islandUnlocked(0, data), isTrue);
    expect(catalog.islandUnlocked(1, data), isFalse);
    expect(catalog.levelUnlocked(0, 1, data), isFalse);
    data = data.copyWith(attempts: [attempt('unit_01')]);
    expect(catalog.levelUnlocked(0, 1, data), isTrue);
    expect(catalog.islandUnlocked(1, data), isFalse);
    data = data.copyWith(attempts: [...data.attempts, attempt('quiz_01')]);
    expect(catalog.islandUnlocked(1, data), isTrue);
  });
  test('Usage splits at midnight', () {
    expect(
      addUsage(
        {},
        DateTime(2026, 9, 23, 23, 59, 50),
        DateTime(2026, 9, 24, 0, 0, 15),
      ),
      {'2026-09-23': 10, '2026-09-24': 15},
    );
  });
  test('Concurrent writes preserve profile, usage, and assessment', () async {
    final store = MemoryProgressStore();
    final container = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final controller = container.read(appProvider.notifier);
    await Future.wait([
      controller.saveProfile(
        const ChildProfile(name: 'نور', gender: ChildGender.girl),
      ),
      controller.recordAttempt(attempt('unit_01')),
      controller.usage(
        DateTime(2026, 9, 23, 12),
        DateTime(2026, 9, 23, 12, 0, 30),
      ),
    ]);
    expect(store.data.profile!.guideName, 'Zizi');
    expect(store.data.attempts.length, 1);
    expect(store.data.dailySeconds.values.single, 30);
    await controller.resetProgress();
    expect(store.data.profile!.name, 'نور');
    expect(store.data.attempts, isEmpty);
    expect(store.data.dailySeconds, isEmpty);
  });
  test(
    'Hive survives close and reopen without a name or gender reset',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'science_progress_test_',
      );
      Hive.init(directory.path);
      final box = await Hive.openBox<String>('test_profile');
      final store = HiveProgressStore(box);
      await store.write(
        AppData(
          profile: const ChildProfile(
            name: 'Nour',
            gender: ChildGender.girl,
            avatar: 2,
          ),
          attempts: [attempt('unit_01')],
        ),
      );
      await box.close();
      final reopened = await Hive.openBox<String>('test_profile');
      final data = HiveProgressStore(reopened).read();
      expect(data.profile!.name, 'Nour');
      expect(data.profile!.gender, ChildGender.girl);
      expect(data.isComplete('unit_01'), isTrue);
      await reopened.close();
      await directory.delete(recursive: true);
    },
  );
  test('Unknown save version is rejected instead of silently erasing data', () {
    expect(
      () => AppData.fromJson({'schemaVersion': 99}),
      throwsFormatException,
    );
  });
}
