import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/parent/parent_area.dart';
import 'package:science_adventure/parent/parent_gate.dart';
import 'package:science_adventure/startup/startup_problem.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    helpers.testCatalog = await Catalog.load();
  });

  Future<void> openSettings(WidgetTester tester, AppData data) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await helpers.mount(tester, const ParentArea(), MemoryProgressStore(data));
    await helpers.tapVisible(tester, find.text('الإعدادات'));
  }

  testWidgets('parents see damaged records and can export them', (
    tester,
  ) async {
    await openSettings(
      tester,
      const AppData(
        profile: ChildProfile(name: 'Nour'),
        quarantinedChildren: {'b': 'damaged'},
      ),
    );
    final summary = find.byKey(const ValueKey('recovery-summary'));
    expect(summary, findsOneWidget);
    expect(tester.widget<Text>(summary).data, contains(': 1.'));
    expect(find.byKey(const ValueKey('copy-rescue')), findsOneWidget);
    expect(find.byKey(const ValueKey('discard-damaged')), findsOneWidget);
  });

  testWidgets('no recovery section when everything was readable', (
    tester,
  ) async {
    await openSettings(tester, const AppData(profile: ChildProfile()));
    expect(find.byKey(const ValueKey('recovery-summary')), findsNothing);
    expect(find.byKey(const ValueKey('copy-diagnostics')), findsOneWidget);
  });

  testWidgets('startup screens name the real problem', (tester) async {
    await tester.pumpWidget(
      StartupProblemApp(problem: StartupProblem.storageFull, onRetry: () {}),
    );
    expect(find.textContaining('This device is full'), findsOneWidget);
    await tester.pumpWidget(
      StartupProblemApp(
        problem: StartupProblem.storageUnavailable,
        onRetry: () {},
      ),
    );
    expect(find.textContaining('Free some space'), findsNothing);
    expect(find.textContaining('could not be opened'), findsOneWidget);
  });

  testWidgets('rescue export and starting again sit behind the parent gate', (
    tester,
  ) async {
    late Directory dir;
    late HiveProgressStore store;
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('science_ui_');
      Hive.init(dir.path);
      store = HiveProgressStore(await Hive.openBox<String>('ui_test'));
      await store.box.put('data', 'garbage');
    });
    addTearDown(() async {
      await tester.runAsync(() async {
        await Hive.close();
        await dir.delete(recursive: true);
      });
    });
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(SaveRecoveryApp(store: store, onRetry: () {}));
    expect(find.byKey(const ValueKey('save-unreadable')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rescue-export')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ParentGateDialog), findsOneWidget);
    await tester.tap(find.text('رجوع • Back'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('start-again')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ParentGateDialog), findsOneWidget);
    expect(store.box.get('data'), 'garbage');
  });
}
