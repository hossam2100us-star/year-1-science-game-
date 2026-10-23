import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content/catalog.dart';
import 'core/design.dart';
import 'core/diagnostics/app_log.dart';
import 'core/ids.dart';
import 'core/image_budget.dart';
import 'core/models.dart';
import 'core/providers.dart';
import 'core/storage.dart';
import 'core/usage_buffer.dart';
import 'core/widgets.dart';
import 'data/account/account_controller.dart';
import 'data/db/app_database.dart';
import 'data/db/connection.dart';
import 'data/drift_progress_store.dart';
import 'data/sync/sync_controller.dart';
import 'data/sync/sync_store.dart';
import 'data/update/app_update.dart';
import 'features/onboarding/profile_editor.dart';
import 'features/world/subject_hub.dart';
import 'features/onboarding/child_chooser.dart';
import 'parent/account_choice.dart';
import 'parent/login_page.dart';
import 'parent/parent_gate.dart';
import 'startup/startup_problem.dart';
import 'startup/storage_bootstrap.dart';

Future<void> main() => launchScienceAdventure();

/// Starts the game. [app] lets the review build add its preview routes; the
/// production entry point always uses the plain [ScienceAdventureApp].
Future<void> launchScienceAdventure({
  Widget app = const ScienceAdventureApp(),
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  ImageBudget.configure();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await _launch(app);
}

Future<void> _launch(Widget app) async {
  void onRetry() => unawaited(_launch(app));
  final ProgressStore store;
  switch (await openProgressStore(
    openHive: HiveProgressStore.open,
    // The web runs the same SQLite database in the browser (web/sqlite3.wasm
    // and web/drift_worker.js), so a parent account and sync work there too.
    openDatabase: () => AppDatabase(appDatabaseConnection()),
    openFallbackDatabase: kIsWeb
        ? () => AppDatabase(appDatabaseConnection(fallback: true))
        : null,
  )) {
    case StorageReady(store: final ready):
      store = ready;
    case StorageUnreadable(:final hive):
      runApp(SaveRecoveryApp(store: hive, onRetry: onRetry));
      return;
    case StorageFailed(:final error):
      runApp(
        StartupProblemApp(problem: startupProblemFor(error), onRetry: onRetry),
      );
      return;
  }
  final Catalog catalog;
  try {
    catalog = await Catalog.load();
  } catch (error, stack) {
    AppLog.error('startup', 'Loading the lesson catalog failed', error, stack);
    runApp(
      StartupProblemApp(
        problem: StartupProblem.contentMissing,
        onRetry: onRetry,
      ),
    );
    return;
  }
  final AccountSetup account;
  if (store case DriftProgressStore(:final db, :final deviceId)) {
    account = await AccountSetup.load(DatabaseAccountPrefs(db), deviceId);
  } else {
    // The Hive fallback (the database could not open): nothing is kept.
    account = await AccountSetup.load(MemoryAccountPrefs(), Ids.uuidV7());
  }
  runApp(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
        catalogProvider.overrideWithValue(catalog),
        accountSetupProvider.overrideWithValue(account),
      ],
      child: app,
    ),
  );
}

class ScienceAdventureApp extends ConsumerStatefulWidget {
  const ScienceAdventureApp({
    super.key,
    this.initialRoute,
    this.routes = const {},
  });

  /// Only the review build (lib/main_preview.dart) passes these.
  final String? initialRoute;
  final Map<String, WidgetBuilder> routes;
  @override
  ConsumerState<ScienceAdventureApp> createState() =>
      _ScienceAdventureAppState();
}

class _ScienceAdventureAppState extends ConsumerState<ScienceAdventureApp> {
  void _configureVoice(AppData data) => ref
      .read(narrationProvider)
      .configure(data.settings, data.profile?.gender ?? ChildGender.boy);

  @override
  void initState() {
    super.initState();
    _configureVoice(ref.read(appProvider));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider);
    // Narration follows settings and the active child; configured on change,
    // not on every rebuild (AUD-016).
    ref.listen(
      appProvider.select((d) => (d.settings, d.profile?.gender)),
      (_, _) => _configureVoice(ref.read(appProvider)),
    );
    // The account session and sync live as long as the app; they run in the
    // background and never block play (device-only: they do nothing).
    ref.listen(syncProvider, (_, _) {});
    return MaterialApp(
      title: 'My School Adventures',
      debugShowCheckedModeBanner: false,
      theme: adventureTheme(data.profile),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: const AdventureHome(),
      // Production has no preview routes (AUD-014); see lib/main_preview.dart.
      initialRoute: widget.initialRoute,
      routes: widget.routes,
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
  bool _childChosen = false;

  /// Past the login page for this run: signed in, or chose to continue
  /// without the Internet (the page comes back next time the app opens).
  bool _pastLogin = false;
  bool _parent = false, _resumed = true, _breakOpen = false, _exitOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ref.read(appProvider.notifier);
    // A saved session goes straight in; a sign-in that ends later (signed out
    // in the parent area, or the session expired) never interrupts play.
    _pastLogin = ref.read(accountProvider).signedIn;
    ref.read(narrationProvider).initialize();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _tick());
    // A newer APK on the family server? Never waited for (ADR-0020).
    unawaited(ref.read(updateProvider.notifier).start());
  }

  late final AppController _controller;

  // Play time is buffered and written as one span every minute or when play
  // stops, instead of a save every 10 s (AUD-004).
  late final UsageBuffer _usage = UsageBuffer(_controller.usageFor);

  Future<void> _report(Future<void>? write) async {
    try {
      await write;
    } catch (error, stack) {
      if (mounted) showSaveError(context, error, stack, area: 'usage');
    }
  }

  void _bufferUsage(DateTime from, DateTime to, String owner) =>
      unawaited(_report(_usage.add(from, to, owner)));

  Future<void> _flushUsage() => _report(_usage.flush());

  void _parentChanged(bool value) {
    _tick();
    unawaited(_flushUsage());
    _parent = value;
    _last = null;
  }

  Future<void> _tick() async {
    final now = DateTime.now();
    final active =
        _resumed &&
        !_parent &&
        !_breakOpen &&
        _childChosen &&
        ref.read(appProvider).profile != null;
    if (!active) {
      _last = null;
      await _flushUsage();
      return;
    }
    final last = _last;
    _last = now;
    if (last != null) {
      _sessionSeconds += now.difference(last).inSeconds;
      _bufferUsage(last, now, ref.read(appProvider).activeChildId);
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
      unawaited(_flushUsage()); // Never keep play time only in memory.
      ref.read(narrationProvider).stop();
    }
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.paused) {
      ref
          .read(syncProvider.notifier)
          .lifecycle(foreground: state == AppLifecycleState.resumed);
    }
    _resumed = state == AppLifecycleState.resumed;
    _last = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_flushUsage());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _exit() async {
    if (_exitOpen) return;
    _exitOpen = true;
    await ref.read(narrationProvider).stop();
    if (mounted &&
        await parentGate(
          context,
          gender: ref.read(appProvider).profile?.gender,
        )) {
      await SystemNavigator.pop();
    }
    _exitOpen = false;
  }

  /// The children with a profile, as one comparable value (no child JSON).
  static String _childIds(AppData d) => ([
    ...d.savedChildren.keys,
    if (d.profile != null) d.activeChildId,
  ]..sort()).join(',');

  /// A child was just created while a parent is signed in: offer to save
  /// it in the account (children are saved one by one, ADR-0018).
  Future<void> _offerToSave(Set<String> ids) async {
    final store = ref.read(storeProvider);
    final account = ref.read(accountProvider);
    if (store is! DriftProgressStore ||
        account.mode != AccountMode.account ||
        !account.signedIn) {
      return;
    }
    for (final id in ids) {
      final data = ref.read(appProvider);
      final record = data.savedChildren[id]?['profile'];
      final child = id == data.activeChildId
          ? data.profile
          : record == null
          ? null
          : ChildProfile.fromJson(Map<String, dynamic>.from(record as Map));
      if (!mounted ||
          child == null ||
          store.linkedChildren.contains(id) ||
          !SyncStore.nameSyncable(child.name)) {
        continue;
      }
      if (!await offerToSaveChild(
        context,
        arabic: data.settings.arabic,
        name: child.name,
        gender: child.gender,
      )) {
        continue;
      }
      try {
        await ref.read(syncProvider.notifier).link(id);
      } catch (error, stack) {
        if (mounted) showSaveError(context, error, stack, area: 'sync');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appProvider.select((data) => data.activeChildId), (
      previous,
      next,
    ) {
      _last = null;
      _sessionSeconds = 0;
    });
    ref.listen(appProvider.select(_childIds), (previous, next) {
      if (previous == null) return;
      final added = next.split(',').toSet()
        ..removeAll(previous.split(','))
        ..remove('');
      if (added.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_offerToSave(added)),
      );
    });
    ref.listen(accountProvider.select((a) => a.signedIn), (previous, next) {
      if (next && !_pastLogin) setState(() => _pastLogin = true);
    });
    // The playing child was deleted in the parent area (or from the account
    // elsewhere): the next child is now active, so the children choose again.
    ref.listen(appProvider.select((d) => d.activeChildId), (previous, next) {
      if (previous != next && _childChosen) {
        setState(() => _childChosen = false);
      }
    });
    // On builds with accounts, each time the app opens until a parent signs
    // in: sign in, or continue without the Internet (ADR-0002).
    final askLogin =
        !_pastLogin &&
        ref.watch(accountProvider.select((a) => a.available && !a.signedIn)) &&
        ref.watch(syncProvider.select((s) => s.supported));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _exit();
      },
      child: askLogin
          ? LoginPage(onOffline: () => setState(() => _pastLogin = true))
          : ref.watch(appProvider).profile == null
          ? const ProfileEditor()
          : !_childChosen
          ? ChildChooser(
              onSelected: () => setState(() {
                _childChosen = true;
                _last = null;
              }),
              onParentChanged: _parentChanged,
            )
          : SubjectHub(onParentChanged: _parentChanged),
    );
  }
}
