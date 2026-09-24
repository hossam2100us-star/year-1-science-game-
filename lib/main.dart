import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content/catalog.dart';
import 'core/design.dart';
import 'core/models.dart';
import 'core/providers.dart';
import 'core/storage.dart';
import 'core/widgets.dart';
import 'features/onboarding/profile_editor.dart';
import 'features/world/world_map.dart';
import 'features/biology/lesson_player.dart';
import 'features/plants/bean_experiment.dart';
import 'features/plants/plant_lab_preview.dart';
import 'parent/parent_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await _launch();
}

Future<void> _launch() async {
  try {
    final store = await HiveProgressStore.open();
    store.read(); // Validate the saved data before entering the child UI.
    final catalog = await Catalog.load();
    runApp(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          catalogProvider.overrideWithValue(catalog),
        ],
        child: const ScienceAdventureApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: adventureTheme(null),
        home: const Scaffold(
          body: AdventurePage(
            maxWidth: 650,
            child: Column(
              children: [
                Text(
                  'مش قادرين نفتح البيانات دلوقتي. اقفل اللعبة وافتحها تاني، واتأكد إن فيه مساحة فاضية. بياناتك ماتمسحتش.',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 24),
                ),
                SizedBox(height: 24),
                FilledButton(
                  onPressed: _launch,
                  child: Text('جرّب تاني • Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScienceAdventureApp extends ConsumerWidget {
  const ScienceAdventureApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    ref
        .read(narrationProvider)
        .configure(data.settings, data.profile?.gender ?? ChildGender.boy);
    return MaterialApp(
      title: 'Science Adventure',
      debugShowCheckedModeBanner: false,
      theme: adventureTheme(data.profile),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: const AdventureHome(),
      initialRoute: kIsWeb && Uri.base.queryParameters['preview'] == 'garden-v2'
          ? '/garden-preview'
          : kIsWeb && Uri.base.queryParameters['preview'] == 'bean-v1'
          ? '/bean-preview'
          : kIsWeb && Uri.base.queryParameters['preview'] == 'plants-v2'
          ? '/plants-preview'
          : kIsWeb && Uri.base.queryParameters['preview'] == 'plants-v3'
          ? '/plants-review'
          : kIsWeb && Uri.base.queryParameters['preview'] == 'light-v1'
          ? '/light-review'
          : '/',
      routes: {
        '/garden-preview': (_) => const LessonRoute(id: 'unit_01'),
        '/light-review': (_) => const PlantLabPreview(initialStep: 10),
        '/plants-review': (_) => const PlantLabPreview(),
        '/plants-preview': (_) => const LessonRoute(id: 'unit_02'),
        '/bean-preview': (_) => const BeanPreview(),
      },
    );
  }
}

class AdventureHome extends ConsumerStatefulWidget {
  const AdventureHome({super.key});
  @override
  ConsumerState<AdventureHome> createState() => _AdventureHomeState();
}

class _AdventureHomeState extends ConsumerState<AdventureHome>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _last;
  int _sessionSeconds = 0;
  bool _parent = false, _resumed = true, _breakOpen = false, _exitOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(narrationProvider).initialize();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _tick());
  }

  void _parentChanged(bool value) {
    _tick();
    _parent = value;
    _last = null;
  }

  Future<void> _tick() async {
    final now = DateTime.now();
    final active =
        _resumed &&
        !_parent &&
        !_breakOpen &&
        ref.read(appProvider).profile != null;
    if (!active) {
      _last = null;
      return;
    }
    final last = _last;
    _last = now;
    if (last != null) {
      _sessionSeconds += now.difference(last).inSeconds;
      try {
        await ref.read(appProvider.notifier).usage(last, now);
      } catch (_) {
        if (mounted) showSaveError(context);
      }
    }
    if (mounted &&
        _sessionSeconds >= ref.read(appProvider).settings.breakMinutes * 60 &&
        !_breakOpen) {
      _breakOpen = true;
      _sessionSeconds = 0;
      _last = null;
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          scrollable: true,
          content: const StoryPanel(
            text: 'Great work! Time to rest your eyes. Come back later!',
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialog).pop(),
              child: const Text('Keep exploring'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialog).pop(),
              child: const Text('Okay, a little rest'),
            ),
          ],
        ),
      );
      _breakOpen = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _tick();
      ref.read(narrationProvider).stop();
    }
    _resumed = state == AppLifecycleState.resumed;
    _last = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _exit() async {
    if (_exitOpen) return;
    _exitOpen = true;
    await ref.read(narrationProvider).stop();
    if (mounted && await parentGate(context)) await SystemNavigator.pop();
    _exitOpen = false;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _exit();
    },
    child: ref.watch(appProvider).profile == null
        ? const ProfileEditor()
        : WorldMap(onParentChanged: _parentChanged),
  );
}
