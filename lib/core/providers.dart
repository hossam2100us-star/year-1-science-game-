import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/canonical_json.dart';
import '../domain/journey/journey_state.dart';
import 'ids.dart';
import 'models.dart';
import 'storage.dart';
import 'narration.dart';
import '../content/catalog.dart';
import '../content/lesson.dart';
import 'spaced_review.dart';

final lessonLibraryProvider = FutureProvider<LessonLibrary>(
  (ref) => LessonLibrary.loadAll(),
);

final storeProvider = Provider<ProgressStore>(
  (ref) => throw StateError('Store must be initialized'),
);
final catalogProvider = Provider<Catalog>(
  (ref) => throw StateError('Catalog must be loaded'),
);
final narrationProvider = Provider<NarrationService>((ref) {
  final service = NarrationService();
  ref.onDispose(service.dispose);
  return service;
});
final appProvider = NotifierProvider<AppController, AppData>(AppController.new);

class AppController extends Notifier<AppData> {
  Future<void> _tail = Future.value();
  @override
  AppData build() => ref.read(storeProvider).read();

  Future<void> _commit(AppData Function(AppData) change) => exclusive(() async {
    final next = change(state);
    await ref.read(storeProvider).write(next);
    state = next;
  });

  /// Runs [action] between saves, never during one.
  Future<T> exclusive<T>(Future<T> Function() action) {
    final task = _tail.then((_) => action());
    _tail = task.then<void>((_) {}, onError: (Object _) {});
    return task;
  }

  /// For changes written to the store directly (sync applying what another
  /// device changed): [apply] runs between saves, and when it reports a
  /// change the store is [reload]ed and the app shows the new data. Saves
  /// queued meanwhile then build on that data instead of overwriting it.
  Future<bool> applyExternal(
    Future<bool> Function() apply, {
    required Future<void> Function() reload,
  }) => exclusive(() async {
    final changed = await apply();
    if (changed) {
      await reload();
      state = ref.read(storeProvider).read();
    }
    return changed;
  });

  Future<void> _childCommit(AppData Function(AppData) change) {
    final owner = state.activeChildId;
    return _commit((s) => s.changeChild(owner, change));
  }

  Future<void> selectChild(String id) => _commit((s) => s.selectChild(id));
  Future<void> removeChild(String id) =>
      _commit((s) => s.removeChild(id, emptyId: Ids.uuidV7()));
  Future<void> addChild(ChildProfile profile) =>
      _commit((s) => s.addChild(Ids.uuidV7(), profile));

  Future<void> saveProfile(ChildProfile profile) =>
      _childCommit((s) => s.copyWith(profile: profile));

  /// Changes the profile of [childId], active or not (a parent choosing
  /// which name to keep after a sync conflict).
  Future<void> changeProfileOf(
    String childId,
    ChildProfile Function(ChildProfile) change,
  ) => _commit(
    (s) => s.childRecords.containsKey(childId)
        ? s.changeChild(
            childId,
            (c) =>
                c.profile == null ? c : c.copyWith(profile: change(c.profile!)),
          )
        : s,
  );
  Future<void> settings(AppSettings settings) =>
      _childCommit((s) => s.copyWith(settings: settings));
  Future<void> photoPending(bool value) =>
      _childCommit((s) => s.copyWith(pendingPhoto: value));
  Future<void> recordAttempt(
    UnitAttempt attempt, {
    String subject = 'science',
  }) => _childCommit(
    (s) => s.withSubjectProgress(
      subject,
      attempts: [...s.progressForSubject(subject).attempts, attempt],
    ),
  );
  Future<void> usage(DateTime start, DateTime end) => _childCommit(
    (s) => s.copyWith(dailySeconds: addUsage(s.dailySeconds, start, end)),
  );

  /// Adds buffered play time to the child it was recorded for, even if
  /// another child is active by the time it is written. Time of a child that
  /// was deleted meanwhile is dropped with the child.
  Future<void> usageFor(String owner, DateTime start, DateTime end) => _commit(
    (s) => s.childRecords.containsKey(owner)
        ? s.changeChild(
            owner,
            (c) =>
                c.copyWith(dailySeconds: addUsage(c.dailySeconds, start, end)),
          )
        : s,
  );
  Future<void> saveJourney(
    String id,
    Map<String, dynamic> journey, {
    String subject = 'science',
  }) {
    if (LessonLibrary.availableIds.contains(id)) {
      // Lesson journeys must match the typed contract before they are
      // stored (AUD-003); a malformed one fails here, visibly.
      final typed = JourneyState.fromJson(journey);
      assert(
        canonicalJson(typed.toJson()) == canonicalJson(journey),
        'Journey for $id does not round-trip through JourneyState',
      );
    }
    return _childCommit((s) {
      var next = s.withSubjectProgress(
        subject,
        journeys: {...s.progressForSubject(subject).journeys, id: journey},
      );
      final library = ref.read(lessonLibraryProvider).value;
      if (subject == 'science' &&
          id.startsWith('unit_01.') &&
          library != null) {
        next = next.copyWith(
          journeys: {
            ...next.journeys,
            SpacedReview.storageKey: SpacedReview.schedule(next, library),
          },
        );
      }
      return next;
    });
  }

  Future<void> completeJourney(
    UnitAttempt attempt, {
    String subject = 'science',
  }) => _childCommit((s) {
    final progress = s.progressForSubject(subject);
    final journeys = Map<String, Map<String, dynamic>>.from(progress.journeys)
      ..remove(attempt.unitId);
    final exists = progress.attempts.any(
      (a) => a.attemptId.isNotEmpty && a.attemptId == attempt.attemptId,
    );
    var next = s.withSubjectProgress(
      subject,
      journeys: journeys,
      attempts: exists ? progress.attempts : [...progress.attempts, attempt],
    );
    final library = ref.read(lessonLibraryProvider).value;
    if (subject == 'science' && library != null) {
      next = next.copyWith(
        journeys: {
          ...next.journeys,
          SpacedReview.storageKey: SpacedReview.schedule(next, library),
        },
      );
    }
    return next;
  });
  Future<void> completeReview(
    String owner,
    LessonLibrary library,
    ReviewTask task,
    DecisionOutcome outcome,
    DateTime now,
  ) => _commit(
    (s) => s.changeChild(
      owner,
      (child) => child.copyWith(
        journeys: {
          ...child.journeys,
          SpacedReview.storageKey: SpacedReview.complete(
            child,
            library,
            task,
            outcome,
            now,
          ),
        },
      ),
    ),
  );
  Future<void> resetProgress() => _childCommit((s) => s.resetProgress());

  /// Deletes child records that could not be read. Only called after a
  /// parent exported them and confirmed behind the parent gate (AUD-006).
  Future<void> discardQuarantine() =>
      _commit((s) => s.copyWith(quarantinedChildren: const {}));
}
