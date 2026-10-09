import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../account/account_controller.dart';
import '../drift_progress_store.dart';
import 'sync_engine.dart';
import 'sync_store.dart';

@immutable
class SyncState {
  const SyncState({
    this.supported = false,
    this.enabled = false,
    this.running = false,
    this.lastSync,
    this.waiting = 0,
    this.quarantined = 0,
    this.failure,
    this.issues = const [],
    this.linked = const {},
  });

  /// This install keeps data in the database (Android); the web build plays
  /// on its own storage and has no sync yet.
  final bool supported;

  /// A parent is signed in, so sync runs.
  final bool enabled;
  final bool running;
  final DateTime? lastSync;

  /// Changes not yet confirmed by the account.
  final int waiting;

  /// Changes the account refused; kept until the parent retries them.
  final int quarantined;
  final SyncFailure? failure;
  final List<SyncIssue> issues;

  /// Children synced with the account.
  final Set<String> linked;

  SyncState copyWith({
    bool? running,
    DateTime? lastSync,
    int? waiting,
    int? quarantined,
    SyncFailure? Function()? failure,
    List<SyncIssue>? issues,
    Set<String>? linked,
  }) => SyncState(
    supported: supported,
    enabled: enabled,
    running: running ?? this.running,
    lastSync: lastSync ?? this.lastSync,
    waiting: waiting ?? this.waiting,
    quarantined: quarantined ?? this.quarantined,
    failure: failure == null ? this.failure : failure(),
    issues: issues ?? this.issues,
    linked: linked ?? this.linked,
  );
}

final syncProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

/// When sync runs (§12): at start-up and sign-in, when the app comes back
/// to the foreground, a few seconds after play changes something (at most
/// once a minute), every 15 minutes while the app is open, and when a
/// parent asks. Never in device-only mode, and play never waits for it.
class SyncController extends Notifier<SyncState> {
  static const _afterChange = Duration(seconds: 5);
  static const _minGap = Duration(minutes: 1);
  static const _periodic = Duration(minutes: 15);
  static const _maxBackoff = Duration(minutes: 15);

  SyncStore? _store;
  DriftProgressStore? _progress;
  SyncEngine? _engine;
  Timer? _timer, _soon;
  Future<void>? _running;
  bool _again = false;
  DateTime _lastStart = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _notBefore = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _backoff = _minGap;

  AppController get _app => ref.read(appProvider.notifier);

  @override
  SyncState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _soon?.cancel();
    });
    _timer?.cancel();
    _soon?.cancel();
    _engine = null;
    final progress = ref.read(storeProvider);
    if (progress is! DriftProgressStore) return const SyncState();
    _progress = progress;
    final store = _store = SyncStore(progress.db, deviceId: progress.deviceId);
    final account = ref.watch(
      accountProvider.select(
        (a) => (
          available: a.available,
          mode: a.mode,
          user: a.user?.id,
          verified: a.user?.emailVerified,
        ),
      ),
    );
    final client = ref.read(accountProvider.notifier).client;
    final user = account.user;
    final enabled =
        account.available &&
        account.mode == AccountMode.account &&
        user != null &&
        client != null;
    if (enabled) {
      _engine = SyncEngine(
        store: store,
        client: client,
        userId: user,
        exclusive: _app.exclusive,
        applyExternal: (apply) =>
            _app.applyExternal(apply, reload: progress.reload),
      );
      _timer = Timer.periodic(_periodic, (_) => unawaited(syncNow()));
      ref.listen(appProvider, (_, _) => _changed());
      Future.microtask(syncNow);
    } else {
      Future.microtask(_refresh);
    }
    return SyncState(
      supported: true,
      enabled: enabled,
      linked: progress.linkedChildren,
    );
  }

  /// Play changed something: sync a little later, at most once a minute.
  void _changed() {
    if (_engine == null || _running != null || _soon != null) return;
    final now = DateTime.now();
    var at = now.add(_afterChange);
    final earliest = _lastStart.add(_minGap);
    if (at.isBefore(earliest)) at = earliest;
    if (at.isBefore(_notBefore)) at = _notBefore;
    _soon = Timer(at.difference(now), () {
      _soon = null;
      unawaited(syncNow());
    });
  }

  /// The app came back to the foreground, or is going to the background
  /// (best effort: Android may pause it before the request finishes).
  void lifecycle({required bool foreground}) {
    if (_engine == null) return;
    if (foreground || state.waiting > 0) unawaited(syncNow());
  }

  /// Runs a sync now (or after the one already running).
  Future<void> syncNow() {
    final engine = _engine;
    if (engine == null) return _refresh();
    if (_running != null) {
      _again = true;
      return _running!;
    }
    _soon?.cancel();
    _soon = null;
    _lastStart = DateTime.now();
    state = state.copyWith(running: true);
    return _running = _run(engine).whenComplete(() {
      _running = null;
      if (_again) {
        _again = false;
        unawaited(syncNow());
      }
    });
  }

  Future<void> _run(SyncEngine engine) async {
    final failure = await engine.run();
    if (!ref.mounted) return;
    if (failure == null) {
      _backoff = _minGap;
      _notBefore = DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      _notBefore = DateTime.now().add(_backoff);
      _backoff = _backoff * 2 > _maxBackoff ? _maxBackoff : _backoff * 2;
    }
    state = state.copyWith(running: false, failure: () => failure);
    await _refresh();
    if (failure == SyncFailure.signedOut) {
      await ref.read(accountProvider.notifier).sessionEnded();
    } else if (failure == null && state.waiting > 0) {
      _changed(); // Changes made while syncing.
    }
  }

  Future<void> _refresh() async {
    final store = _store;
    final progress = _progress;
    if (store == null || progress == null || !ref.mounted) return;
    final waiting = await store.outbox.waitingCount();
    final quarantined = (await store.outbox.quarantined()).length;
    final issues = await store.issues();
    final last = await store.lastSync();
    if (!ref.mounted) return;
    state = state.copyWith(
      waiting: waiting,
      quarantined: quarantined,
      issues: issues,
      lastSync: last,
      linked: progress.linkedChildren,
    );
  }

  SyncStore get _sync {
    final store = _store;
    if (store == null) throw StateError('Sync is not supported here');
    return store;
  }

  /// Starts syncing [childId] with the signed-in parent's account.
  Future<void> link(String childId) async {
    final user = ref.read(accountProvider).user;
    if (user == null) throw StateError('No parent signed in');
    await _app.applyExternal(() async {
      await _sync.useAccount(user.id);
      await _sync.link(childId);
      return true;
    }, reload: _progress!.reload);
    await _refresh();
    unawaited(syncNow());
  }

  /// Back to "this device only": signs out and stops syncing. Every child
  /// stays on this device with all its progress; nothing is deleted.
  Future<void> leaveAccount() async {
    await ref.read(accountProvider.notifier).useDeviceOnly();
    await _unlinkAll();
  }

  /// Deletes the parent account on the server. The children and their
  /// progress stay on this device, now device-only.
  Future<DateTime> deleteAccount({
    String? password,
    String? googleIdToken,
  }) async {
    final account = ref.read(accountProvider.notifier);
    final when = await account.deleteAccount(
      password: password,
      googleIdToken: googleIdToken,
    );
    await account.useDeviceOnly();
    await _unlinkAll();
    return when;
  }

  Future<void> _unlinkAll() async {
    if (_store == null) return;
    await _app.applyExternal(() async {
      await _sync.unlinkAll();
      return true;
    }, reload: _progress!.reload);
    await _refresh();
  }

  /// Sends the refused changes again (after the parent fixed the cause).
  Future<void> retryRefused() async {
    await _app.exclusive(_sync.outbox.retryQuarantined);
    await syncNow();
  }

  /// The parent keeps the account's value: the notice goes away.
  Future<void> dismiss(SyncIssue issue) async {
    await _app.exclusive(() => _sync.dismissIssue(issue));
    await _refresh();
  }

  /// The parent prefers this device's value of a conflicting field: it is
  /// saved again as a normal change, which the account then accepts.
  Future<void> useMine(SyncIssue issue) async {
    final field = issue.field;
    final mine = issue.mine;
    if (issue.kind != 'field' || mine is! String) return dismiss(issue);
    await _app.changeProfileOf(issue.childId, (p) {
      return switch (field) {
        'displayName' => p.copyWith(name: mine),
        'gender' => p.copyWith(
          gender: ChildGender.values.asNameMap()[mine] ?? p.gender,
        ),
        _ => p,
      };
    });
    await dismiss(issue);
    unawaited(syncNow());
  }
}
