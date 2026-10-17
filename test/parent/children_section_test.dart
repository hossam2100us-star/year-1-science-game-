import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/onboarding/child_chooser.dart';
import 'package:science_adventure/l10n/parent_strings.dart';
import 'package:science_adventure/main.dart';
import 'package:science_adventure/parent/children_section.dart';
import 'package:science_adventure/parent/parent_gate.dart';

import '../setup_screen_test.dart' as helpers;

/// Teacher review 6, finding 3.5: deleting a child's profile moved from the
/// child's card in "Who is playing?" to the parent area.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Nour (local-child) and Adam (second); Adam is playing.
  AppData family() =>
      const AppData(profile: ChildProfile(name: 'Nour'))
          .addChild('second', const ChildProfile(name: 'Adam'));

  setUpAll(() async {
    helpers.testCatalog = await helpers.loadTestCatalog();
  });

  testWidgets('"Who is playing?" has no delete button', (t) async {
    await helpers.mount(
      t,
      ChildChooser(onSelected: () {}, onParentChanged: (_) {}),
      MemoryProgressStore(family()),
    );
    expect(find.text('Nour'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.textContaining('Delete'), findsNothing);
  });

  testWidgets('the parent area lists every child; cancel keeps the profile, '
      'confirm deletes it', (t) async {
    final store = MemoryProgressStore(family());
    await helpers.mount(
      t,
      const Scaffold(
        body: SingleChildScrollView(child: ChildrenOnDevice(arabic: false)),
      ),
      store,
    );
    expect(find.text('Children on this device'), findsOneWidget);
    expect(find.text('Nour'), findsOneWidget);
    expect(find.text('Adam'), findsOneWidget);

    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('delete-child-local-child')),
    );
    expect(find.text("Delete Nour's profile?"), findsOneWidget);
    await helpers.tapVisible(t, find.text('Cancel'));
    expect(store.data.childRecords.length, 2);

    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('delete-child-local-child')),
    );
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('confirm-delete-child')),
    );
    await t.pumpAndSettle();
    expect(store.data.childRecords.keys, ['second']);
    expect(store.data.profile!.name, 'Adam', reason: 'Adam keeps playing');
    expect(find.text('Nour'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('deleting the playing child goes back to "Who is playing?"', (
    t,
  ) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final store = MemoryProgressStore(family());
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          catalogProvider.overrideWithValue(helpers.testCatalog),
          narrationProvider.overrideWith((ref) => helpers.SilentNarration()),
        ],
        child: const MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: [Locale('en'), Locale('ar')],
          home: AdventureHome(),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Who is playing?'), findsOneWidget);
    await helpers.tapVisible(t, find.byKey(const ValueKey('child-second')));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Who is playing?'), findsNothing);

    // Into the parent area (behind the parent gate), Settings tab.
    await helpers.tapVisible(t, find.byIcon(Icons.lock_outline_rounded));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(ParentGateDialog), findsOneWidget);
    await t.enterText(
      find.descendant(
        of: find.byType(ParentGateDialog),
        matching: find.byType(TextField),
      ),
      helpers.gateAnswer(t),
    );
    await t.tap(find.text('كمّل • Continue'));
    await t.pump(const Duration(milliseconds: 600));
    final l = parentStrings(store.data.settings.arabic);
    await helpers.tapVisible(t, find.text(l.parentAreaSettings));
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('delete-child-second')),
    );
    await helpers.tapVisible(
      t,
      find.byKey(const ValueKey('confirm-delete-child')),
    );
    await t.pump(const Duration(milliseconds: 600));

    expect(store.data.childRecords.keys, ['local-child']);
    expect(find.text('Who is playing?'), findsOneWidget);
    expect(find.text('Nour'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
