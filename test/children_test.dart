import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/onboarding/child_chooser.dart';
import 'package:science_adventure/features/onboarding/profile_editor.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppData family() => const AppData(
    profile: ChildProfile(name: 'Nour'),
    journeys: {
      'unit_02': {'index': 4},
    },
    dailySeconds: {'2026-09-28': 90},
  ).addChild('second', const ChildProfile(name: 'Adam'));
  test('Children retain independent progress, settings and usage after restart and reset', () {
    final second = family().copyWith(
      journeys: {
        'unit_02': {'index': 1},
      },
      settings: const AppSettings(volume: .3),
    );
    final restored = AppData.fromJson(second.toJson());
    expect(restored.activeChildId, 'second');
    expect(restored.journeys['unit_02']!['index'], 1);
    expect(restored.dailySeconds, isEmpty);
    final first = restored.selectChild('local-child');
    expect(first.profile!.name, 'Nour');
    expect(first.journeys['unit_02']!['index'], 4);
    expect(first.dailySeconds['2026-09-28'], 90);
    expect(first.settings.volume, .85);
    final reset = first.resetProgress();
    expect(reset.journeys, isEmpty);
    expect(reset.selectChild('second').journeys['unit_02']!['index'], 1);
    expect(reset.selectChild('second').settings.volume, .3);
  });
  test(
    'Version two save becomes the existing child without losing other subjects',
    () {
      final old = {
        'schemaVersion': 2,
        'profile': const ChildProfile(name: 'Nour').toJson(),
        'settings': const AppSettings().toJson(),
        'dailySeconds': <String, int>{},
        'subjects': {
          'science': {
            'journeys': {
              'unit_02': {'index': 8},
            },
            'attempts': [],
          },
          'math': {'saved': true},
        },
      };
      final migrated = AppData.fromJson(AppData.fromJson(old).toJson());
      expect(migrated.childRecords.length, 1);
      expect(migrated.journeys['unit_02']!['index'], 8);
      expect(migrated.otherSubjects['math']!['saved'], isTrue);
    },
  );
  test(
    'Queued saves stay with the child who started them across a switch',
    () async {
      final store = MemoryProgressStore(family().selectChild('local-child'));
      final container = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final controller = container.read(appProvider.notifier);
      final switching = controller.selectChild('second');
      final oldSave = controller.saveJourney('unit_01', {'owner': 'Nour'});
      await Future.wait([switching, oldSave]);
      expect(store.data.activeChildId, 'second');
      expect(store.data.journeys['unit_01'], isNull);
      expect(
        store.data.selectChild('local-child').journeys['unit_01']!['owner'],
        'Nour',
      );
      await controller.saveJourney('unit_01', {'owner': 'Adam'});
      expect(store.data.journeys['unit_01']!['owner'], 'Adam');
    },
  );
  testWidgets('Creating a new child preserves the original profile', (t) async {
    helpers.testCatalog = (await t.runAsync(helpers.loadTestCatalog))!;
    final store = MemoryProgressStore(family().selectChild('local-child'));
    await helpers.mount(
      t,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProfileEditor(newChild: true),
              ),
            ),
            child: const Text('Create'),
          ),
        ),
      ),
      store,
    );
    await helpers.tapVisible(t, find.text('Create'));
    await t.pumpAndSettle();
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('childName')))
          .controller!
          .text,
      isEmpty,
    );
    await t.enterText(find.byKey(const ValueKey('childName')), 'Mona');
    await helpers.tapVisible(t, find.byKey(const ValueKey('profileNext')));
    await helpers.tapVisible(t, find.text('Girl'));
    await helpers.tapVisible(t, find.byKey(const ValueKey('profileNext')));
    await helpers.tapVisible(t, find.byKey(const ValueKey('profileNext')));
    expect(store.data.profile!.name, 'Mona');
    expect(store.data.journeys, isEmpty);
    expect(store.data.childRecords.length, 3);
    expect(store.data.selectChild('local-child').profile!.name, 'Nour');
    expect(
      store.data.selectChild('local-child').journeys['unit_02']!['index'],
      4,
    );
    expect(t.takeException(), isNull);
  });
  test(
    'Deleting active, inactive and last children preserves only survivors',
    () {
      final original = family();
      final inactive = original.removeChild('local-child', emptyId: 'fresh');
      expect(inactive.profile!.name, 'Adam');
      expect(inactive.childRecords.keys, ['second']);
      final active = original.removeChild('second', emptyId: 'fresh');
      expect(active.profile!.name, 'Nour');
      expect(active.journeys['unit_02']!['index'], 4);
      final empty = AppData.fromJson(
        active.removeChild('local-child', emptyId: 'fresh').toJson(),
      );
      expect(empty.profile, isNull);
      expect(empty.journeys, isEmpty);
      expect(empty.activeChildId, 'fresh');
      expect(empty.childRecords.containsKey('local-child'), isFalse);
      expect(
        () => empty.changeChild(
          'local-child',
          (s) => s.copyWith(profile: const ChildProfile(name: 'Old')),
        ),
        throwsStateError,
      );
    },
  );
  testWidgets(
    'Deleting requires parent gate and confirmation; cancel preserves data',
    (t) async {
      helpers.testCatalog = (await t.runAsync(helpers.loadTestCatalog))!;
      final store = MemoryProgressStore(family());
      await helpers.mount(
        t,
        ChildChooser(onSelected: () {}, onParentChanged: (_) {}),
        store,
      );
      Future<void> openDelete() async {
        await helpers.tapVisible(
          t,
          find.byKey(const ValueKey('delete-child-second')),
        );
        expect(
          find.byKey(const ValueKey('confirm-delete-child')),
          findsNothing,
        );
        await t.enterText(find.byType(TextField), helpers.gateAnswer(t));
        await helpers.tapVisible(t, find.text('كمّل • Continue'));
        await t.pumpAndSettle();
      }

      await openDelete();
      await helpers.tapVisible(t, find.text('إلغاء'));
      expect(store.data.childRecords.length, 2);
      await openDelete();
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('confirm-delete-child')),
      );
      await t.pumpAndSettle();
      expect(store.data.profile!.name, 'Nour');
      expect(store.data.childRecords.containsKey('second'), isFalse);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('Chooser selects the intended child and gates adding another', (
    t,
  ) async {
    helpers.testCatalog = (await t.runAsync(helpers.loadTestCatalog))!;
    final store = MemoryProgressStore(family());
    var selected = false;
    await helpers.mount(
      t,
      ChildChooser(onSelected: () => selected = true, onParentChanged: (_) {}),
      store,
    );
    expect(find.text('Nour'), findsOneWidget);
    expect(find.text('Adam'), findsOneWidget);
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('child-local-child')),
    );
    expect(selected, isTrue);
    expect(store.data.profile!.name, 'Nour');
    await helpers.tapVisible(t, find.byKey(const ValueKey('add-child')));
    expect(store.data.childRecords.length, 2);
    expect(find.byType(AlertDialog), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
