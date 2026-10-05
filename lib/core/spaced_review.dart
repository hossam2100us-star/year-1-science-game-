import '../content/lesson.dart';
import '../features/garden/garden_model.dart';
import 'models.dart';

/// Local, child-scoped practice. Unit attempts are immutable learning evidence.
class ReviewTask {
  const ReviewTask(
    this.lessonId,
    this.objective,
    this.stepId,
    this.due,
    this.level, {
    this.gardenScene,
  });
  final String lessonId, objective, stepId;
  final String? gardenScene;
  final DateTime due;
  final int level;
  String get key => '$lessonId:$objective';
  String get cardKey => '$lessonId:${gardenScene ?? ''}:$stepId';
}

class SpacedReview {
  static const storageKey = 'science.review';
  static String day(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _cardKey(Map<dynamic, dynamic> entry) =>
      '${entry['lessonId']}:${entry['gardenScene'] ?? ''}:${entry['stepId']}';

  static Set<String> _completedCards(
    Map<dynamic, dynamic> saved,
    String today,
  ) {
    if (saved['completedDay'] != today) return {};
    // Old journals counted goals; several goals can share one discovery card.
    final entries = saved['entries'] as Map;
    return {
      ...List<String>.from(saved['completedCards'] ?? []),
      for (final key in List<String>.from(saved['completed'] ?? []))
        if (entries[key] is Map) _cardKey(entries[key]),
    };
  }

  /// Also seeds existing installations from their latest completed attempts.
  static Map<String, dynamic> schedule(AppData data, LessonLibrary library) {
    final saved = data.journeys[storageKey] ?? {};
    final entries = Map<String, dynamic>.from(saved['entries'] ?? {});
    for (final lesson in library.lessons.values) {
      final attempt = data.latest(lesson.id);
      if (attempt == null) continue;
      for (final goal in attempt.objectives.entries) {
        final step = lesson.steps
            .where(
              (s) =>
                  s.assessedObjectives.contains(goal.key) &&
                  s.answer != null &&
                  !s.isFree,
            )
            .firstOrNull;
        if (step == null) continue;
        final key = '${lesson.id}:${goal.key}';
        final previous = entries[key] as Map?;
        final evidence = attempt.attemptId.isEmpty
            ? attempt.completedAt.toIso8601String()
            : attempt.attemptId;
        if (previous?['evidence'] == evidence) continue;
        entries[key] = {
          'lessonId': lesson.id,
          'objective': goal.key,
          'stepId': step.id,
          'evidence': evidence,
          'due': day(
            dateOnly(attempt.completedAt).add(
              Duration(days: goal.value == DecisionOutcome.firstTry ? 3 : 1),
            ),
          ),
          'level': 0,
          'weak': goal.value != DecisionOutcome.firstTry,
        };
      }
    }
    final alive = library.lessons['unit_01'];
    if (alive != null) {
      for (final raw in [
        alive.json['garden'],
        ...List<dynamic>.from(alive.json['aliveScenes'] ?? []),
      ]) {
        if (raw is! Map<String, dynamic>) continue;
        final scene = GardenContent(raw);
        final journal = data.journeys[scene.storageKey];
        if (journal == null) continue;
        final results = Map<String, String>.from(journal['results'] ?? {});
        final observedAt = journal['observedAt'] as Map? ?? {};
        final micros = int.tryParse(journal['roundId']?.toString() ?? '');
        // Undated legacy discoveries are overdue, not postponed at every load.
        final legacyObserved = micros == null
            ? DateTime(1970)
            : DateTime.fromMicrosecondsSinceEpoch(micros);
        for (final item in scene.items.where(
          (i) => results.containsKey(i.id),
        )) {
          final key = 'unit_01:scene.${scene.id}.${item.id}';
          final evidence = '${journal['roundId']}:${results[item.id]}';
          if ((entries[key] as Map?)?['evidence'] == evidence) continue;
          final recorded = observedAt[item.id];
          final observed = recorded is String
              ? DateTime.tryParse(recorded)?.toLocal() ?? legacyObserved
              : legacyObserved;
          final weak = results[item.id] != 'firstTry';
          entries[key] = {
            'lessonId': 'unit_01',
            'objective': 'scene.${scene.id}.${item.id}',
            'stepId': item.id,
            'gardenScene': scene.id,
            'evidence': evidence,
            'due': day(dateOnly(observed).add(Duration(days: weak ? 1 : 3))),
            'level': 0,
            'weak': weak,
          };
        }
      }
    }
    return {...saved, 'version': 2, 'entries': entries};
  }

  static List<ReviewTask> due(
    AppData data,
    LessonLibrary library,
    DateTime now,
  ) {
    final saved = schedule(data, library);
    final today = day(now);
    final completedToday = List<String>.from(
      saved['completedDay'] == today ? saved['completed'] ?? [] : [],
    );
    final completedCards = _completedCards(saved, today);
    final available = <ReviewTask>[];
    for (final raw in (saved['entries'] as Map).values) {
      final item = Map<String, dynamic>.from(raw);
      final date = DateTime.tryParse(item['due'] ?? '');
      final lesson = library.lessons[item['lessonId']];
      if (lesson != null && item['gardenScene'] != null) {
        final scenes = [
          lesson.json['garden'],
          ...List<dynamic>.from(lesson.json['aliveScenes'] ?? []),
        ];
        final exists = scenes.whereType<Map<dynamic, dynamic>>().any(
          (scene) =>
              (scene['id'] ?? 'garden') == item['gardenScene'] &&
              (scene['items'] as List? ?? []).any(
                (subject) => subject['id'] == item['stepId'],
              ),
        );
        if (!exists) continue;
      }
      if (date == null ||
          date.isAfter(dateOnly(now)) ||
          lesson == null ||
          (item['gardenScene'] == null &&
              !lesson.steps.any((s) => s.id == item['stepId']))) {
        continue;
      }
      final task = ReviewTask(
        lesson.id,
        item['objective'],
        item['stepId'],
        date,
        item['level'] ?? 0,
        gardenScene: item['gardenScene'],
      );
      if (!completedToday.contains(task.key) &&
          !completedCards.contains(task.cardKey)) {
        available.add(task);
      }
    }
    available.sort((a, b) {
      final entries = saved['entries'] as Map;
      final weakA = entries[a.key]['weak'] == true,
          weakB = entries[b.key]['weak'] == true;
      if (weakA != weakB) return weakA ? -1 : 1;
      final date = a.due.compareTo(b.due);
      return date == 0 ? a.key.compareTo(b.key) : date;
    });
    final seen = <String>{};
    return available
        .where((task) => seen.add(task.cardKey))
        .take((3 - completedCards.length).clamp(0, 3))
        .toList();
  }

  static Map<String, dynamic> complete(
    AppData data,
    LessonLibrary library,
    ReviewTask task,
    DecisionOutcome outcome,
    DateTime now,
  ) {
    final saved = schedule(data, library);
    final entries = Map<String, dynamic>.from(saved['entries']);
    final previous = entries[task.key];
    if (previous is! Map) return saved;
    final today = day(now);
    final completed = List<String>.from(
      saved['completedDay'] == today ? saved['completed'] ?? [] : [],
    );
    final completedCards = _completedCards(saved, today);
    if (completedCards.contains(task.cardKey)) {
      return saved; // Boundary saves are idempotent.
    }
    final independent = outcome == DecisionOutcome.firstTry;
    final covered = entries.entries
        .where(
          (entry) =>
              entry.value is Map && _cardKey(entry.value) == task.cardKey,
        )
        .map((entry) => entry.key)
        .toList();
    // A shared activity rehearses all its goals once, not the same screen five
    // times. Retain each goal's own repetition level and historical evidence.
    for (final key in covered) {
      final current = entries[key] as Map;
      final level = independent
          ? ((current['level'] as int? ?? 0) + 1).clamp(1, 4)
          : 0;
      entries[key] = {
        ...current,
        'level': level,
        'weak': !independent,
        'due': day(
          dateOnly(now).add(Duration(days: const [1, 3, 7, 14, 30][level])),
        ),
        'lastPracticed': today,
        'practiceOutcome': outcome.name,
      };
    }
    return {
      ...saved,
      'entries': entries,
      'completedDay': today,
      'completed': {...completed, ...covered}.toList(),
      'completedCards': {...completedCards, task.cardKey}.toList(),
    };
  }
}
