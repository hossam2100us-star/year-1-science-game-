import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'storage.dart';
import 'narration.dart';
import '../content/catalog.dart';
import '../content/lesson.dart';

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

  Future<void> saveProfile(ChildProfile profile) =>
      _commit((s) => s.copyWith(profile: profile));
  Future<void> settings(AppSettings settings) =>
      _commit((s) => s.copyWith(settings: settings));
  Future<void> photoPending(bool value) =>
      _commit((s) => s.copyWith(pendingPhoto: value));
  Future<void> recordAttempt(UnitAttempt attempt) =>
      _commit((s) => s.copyWith(attempts: [...s.attempts, attempt]));
  Future<void> usage(DateTime start, DateTime end) => _commit(
    (s) => s.copyWith(dailySeconds: addUsage(s.dailySeconds, start, end)),
  );
  Future<void> saveJourney(String id, Map<String, dynamic> journey) =>
      _commit((s) => s.copyWith(journeys: {...s.journeys, id: journey}));
  Future<void> completeJourney(UnitAttempt attempt) => _commit((s) {
    final journeys = Map<String, Map<String, dynamic>>.from(s.journeys)
      ..remove(attempt.unitId);
    final exists = s.attempts.any(
      (a) => a.attemptId.isNotEmpty && a.attemptId == attempt.attemptId,
    );
    return s.copyWith(
      journeys: journeys,
      attempts: exists ? s.attempts : [...s.attempts, attempt],
    );
  });
  Future<void> resetProgress() => _commit((s) => s.resetProgress());
}
