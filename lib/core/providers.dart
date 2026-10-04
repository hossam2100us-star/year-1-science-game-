import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:math';

import 'models.dart';
import 'storage.dart';
import 'narration.dart';
import '../content/catalog.dart';
import '../content/lesson.dart';
import 'spaced_review.dart';

final lessonLibraryProvider = FutureProvider<LessonLibrary>(
  (ref) => LessonLibrary.load(),
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

  Future<void> _commit(AppData Function(AppData) change) {
    final task = _tail.then((_) async {
      final next = change(state);
      await ref.read(storeProvider).write(next);
      state = next;
    });
    _tail = task.catchError((Object _) {});
    return task;
  }

  Future<void> _childCommit(AppData Function(AppData) change) {
    final owner = state.activeChildId;
    return _commit((s) => s.changeChild(owner, change));
  }

  Future<void> selectChild(String id) => _commit((s) => s.selectChild(id));
  Future<void> removeChild(String id) => _commit(
    (s) => s.removeChild(
      id,
      emptyId:
          'empty-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
    ),
  );
  Future<void> addChild(ChildProfile profile) {
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return _commit((s) => s.addChild(id, profile));
  }

  Future<void> saveProfile(ChildProfile profile) =>
      _childCommit((s) => s.copyWith(profile: profile));
  Future<void> settings(AppSettings settings) =>
      _childCommit((s) => s.copyWith(settings: settings));
  Future<void> photoPending(bool value) =>
      _childCommit((s) => s.copyWith(pendingPhoto: value));
  Future<void> recordAttempt(UnitAttempt attempt) =>
      _childCommit((s) => s.copyWith(attempts: [...s.attempts, attempt]));
  Future<void> usage(DateTime start, DateTime end) => _childCommit(
    (s) => s.copyWith(dailySeconds: addUsage(s.dailySeconds, start, end)),
  );
  Future<void> saveJourney(String id, Map<String, dynamic> journey) =>
      _childCommit((s) {
        var next = s.copyWith(journeys: {...s.journeys, id: journey});
        final library = ref.read(lessonLibraryProvider).value;
        if (id.startsWith('unit_01.') && library != null) {
          next = next.copyWith(
            journeys: {
              ...next.journeys,
              SpacedReview.storageKey: SpacedReview.schedule(next, library),
            },
          );
        }
        return next;
      });
  Future<void> completeJourney(UnitAttempt attempt) => _childCommit((s) {
    final journeys = Map<String, Map<String, dynamic>>.from(s.journeys)
      ..remove(attempt.unitId);
    final exists = s.attempts.any(
      (a) => a.attemptId.isNotEmpty && a.attemptId == attempt.attemptId,
    );
    var next = s.copyWith(
      journeys: journeys,
      attempts: exists ? s.attempts : [...s.attempts, attempt],
    );
    final library = ref.read(lessonLibraryProvider).value;
    if (library != null) {
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
}
