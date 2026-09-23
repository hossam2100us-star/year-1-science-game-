import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/core/design.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/narration.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/onboarding/profile_editor.dart';
import 'package:science_adventure/features/world/world_map.dart';
import 'package:science_adventure/parent/parent_area.dart';
import 'package:science_adventure/parent/parent_gate.dart';

late Catalog testCatalog;

class SilentNarration extends NarrationService {
  @override
  Future<void> initialize() async {
    status = VoiceStatus.unavailable;
  }

  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> stop() async {}
}

Future<void> mount(
  WidgetTester tester,
  Widget child,
  MemoryProgressStore store, {
  double scale = 1,
}) async {
  final catalog = testCatalog;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
        catalogProvider.overrideWithValue(catalog),
        narrationProvider.overrideWith((ref) => SilentNarration()),
      ],
      child: MaterialApp(
        theme: adventureTheme(store.data.profile),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: child,
      ),
    ),
  );
  await tester.pump();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    testCatalog = await Catalog.load();
  });
  for (final size in [const Size(800, 360), const Size(1280, 800)]) {
    testWidgets('Personalization persists at $size with 2x text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryProgressStore();
      await mount(tester, const ProfileEditor(), store, scale: 2);
      await tester.enterText(find.byKey(const ValueKey('childName')), 'نور');
      await tapVisible(tester, find.byKey(const ValueKey('profileNext')));
      await tapVisible(tester, find.text('Girl • بنت'));
      expect(find.text('Meet Zizi'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('profileNext')));
      await tapVisible(tester, find.text('Bunny'));
      await tapVisible(tester, find.byKey(const ValueKey('profileNext')));
      expect(store.data.profile!.name, 'نور');
      expect(store.data.profile!.gender, ChildGender.girl);
      expect(store.data.profile!.avatar, 1);
      expect(tester.takeException(), isNull);
    });
    testWidgets('World and RTL parent screen fit $size at 2x', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryProgressStore(
        const AppData(
          profile: ChildProfile(name: 'Alexandria', gender: ChildGender.girl),
        ),
      );
      await mount(tester, WorldMap(onParentChanged: (_) {}), store, scale: 2);
      expect(find.text('Biology Island'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await mount(tester, const ParentArea(), store, scale: 2);
      expect(
        Directionality.of(tester.element(find.text('ركن الأهل'))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('الإعدادات'));
      expect(find.text('بيانات الطفل وشكل اللعبة'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('English'));
      expect(
        Directionality.of(tester.element(find.text('Grown-ups'))),
        TextDirection.ltr,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Photo selection is behind an adult gate', (tester) async {
    final store = MemoryProgressStore();
    await mount(tester, const ProfileEditor(), store);
    await tapVisible(tester, find.byKey(const ValueKey('profileNext')));
    await tapVisible(tester, find.byKey(const ValueKey('profileNext')));
    await tapVisible(tester, find.text('My photo'));
    expect(find.byType(ParentGateDialog), findsOneWidget);
    expect(store.data.pendingPhoto, isFalse);
    await tester.enterText(find.byType(TextField), '12');
    await tapVisible(tester, find.text('كمّل • Continue'));
    expect(find.byType(ParentGateDialog), findsOneWidget);
    await tapVisible(tester, find.text('رجوع • Back'));
    expect(store.data.pendingPhoto, isFalse);
  });
  testWidgets('Adult gate accepts Arabic digits', (tester) async {
    var passed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              passed = await parentGate(context);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), '٥٦');
    await tester.tap(find.text('كمّل • Continue'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(passed, isTrue);
  });
}
