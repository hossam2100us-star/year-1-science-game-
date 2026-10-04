import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/content/catalog.dart';
import 'package:science_adventure/core/game_image.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/providers.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/features/onboarding/profile_editor.dart';
import 'package:science_adventure/main.dart';

import 'setup_screen_test.dart' show SilentNarration;

class RecordingNarration extends SilentNarration {
  final calls = <(AppSettings, ChildGender)>[];
  @override
  void configure(AppSettings settings, ChildGender gender) {
    calls.add((settings, gender));
    super.configure(settings, gender);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Narration is configured on change, not on rebuild (AUD-016)', () {
    late RecordingNarration voice;
    late MemoryProgressStore store;
    late ProviderContainer container;

    Future<void> pumpApp(WidgetTester tester) async {
      voice = RecordingNarration();
      final catalog = (await tester.runAsync(Catalog.load))!;
      container = ProviderContainer(
        overrides: [
          storeProvider.overrideWithValue(store),
          catalogProvider.overrideWithValue(catalog),
          narrationProvider.overrideWithValue(voice),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ScienceAdventureApp(),
        ),
      );
      await tester.pump();
    }

    testWidgets('app root', (tester) async {
      store = MemoryProgressStore(
        const AppData(profile: ChildProfile(gender: ChildGender.girl)),
      );
      await pumpApp(tester);
      expect(voice.calls.single.$2, ChildGender.girl);

      // A state change unrelated to narration rebuilds without configuring.
      await container
          .read(appProvider.notifier)
          .usage(DateTime(2026, 10, 4, 9), DateTime(2026, 10, 4, 9, 1));
      await tester.pump();
      expect(voice.calls, hasLength(1));

      await container
          .read(appProvider.notifier)
          .settings(const AppSettings(volume: .4));
      await tester.pump();
      expect(voice.calls, hasLength(2));
      expect(voice.calls.last.$1.volume, .4);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('profile editor previews and then restores the voice', (
      tester,
    ) async {
      store = MemoryProgressStore(
        const AppData(profile: ChildProfile(gender: ChildGender.boy)),
      );
      voice = RecordingNarration();
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            narrationProvider.overrideWithValue(voice),
          ],
          child: const MaterialApp(home: ProfileEditor(editing: true)),
        ),
      );
      await tester.pump();
      expect(voice.calls.single.$2, ChildGender.boy);
      await tester.tap(find.byKey(const ValueKey('profileNext')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Girl'));
      await tester.pump();
      expect(voice.calls.last.$2, ChildGender.girl);

      final before = voice.calls.length;
      await tester.pump();
      expect(voice.calls.length, before, reason: 'rebuild must not configure');

      await tester.pumpWidget(const SizedBox());
      expect(voice.calls.last.$2, ChildGender.boy, reason: 'restored');
    });
  });

  testWidgets('GameImage keeps one load future across rebuilds', (
    tester,
  ) async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
        .drawRect(const Rect.fromLTWH(0, 0, 4, 4), Paint()..color = Colors.red);
    final image = await tester.runAsync(
      () => recorder.endRecording().toImage(4, 4),
    );
    Flame.images.add('test-a.png', image!);
    Flame.images.add('test-b.png', image.clone());
    addTearDown(() {
      Flame.images.clear('test-a.png');
      Flame.images.clear('test-b.png');
    });

    Widget app(String asset, int generation) => Directionality(
      textDirection: TextDirection.ltr,
      child: GameImage(
        asset: asset,
        builder: (_, img) => Text('ready $generation'),
        placeholder: const Text('loading'),
      ),
    );

    await tester.pumpWidget(app('test-a.png', 1));
    final first = tester.state<GameImageState>(find.byType(GameImage)).image;
    await tester.pump();
    expect(find.text('ready 1'), findsOneWidget);

    await tester.pumpWidget(app('test-a.png', 2));
    expect(
      tester.state<GameImageState>(find.byType(GameImage)).image,
      same(first),
    );
    expect(find.text('ready 2'), findsOneWidget);

    await tester.pumpWidget(app('test-b.png', 3));
    expect(
      tester.state<GameImageState>(find.byType(GameImage)).image,
      isNot(same(first)),
    );
  });
}
