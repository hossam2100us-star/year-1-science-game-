import 'package:flutter/foundation.dart';

/// Typed form of a saved lesson journey (AUD-003).
///
/// Parsing is strict about types: a field with the wrong type throws a
/// [FormatException] here, at the storage boundary, instead of a cast error
/// deep inside a scene. Fields are nullable so a saved journey round-trips
/// exactly: absent keys stay absent. Scene-specific state (`lab`, `bean`,
/// `light`) and keys this version does not know are carried verbatim in
/// [StepState.extras], so nothing written by a newer or older app is lost.
@immutable
class JourneyState {
  const JourneyState({
    required this.version,
    required this.attemptId,
    required this.index,
    this.stepId,
    this.hasStepId = false,
    this.responses = const {},
    this.current = const StepState(),
    this.extras = const {},
  });

  /// Content version of the lesson when this journey was saved.
  final int version;
  final String attemptId;
  final int index;

  /// Step the child was on; null when finished. [hasStepId] distinguishes
  /// "null" from "absent" (old saves had no stepId).
  final String? stepId;
  final bool hasStepId;
  final Map<String, StepState> responses;
  final StepState current;
  final Map<String, Object?> extras;

  static const _known = {
    'version',
    'attemptId',
    'index',
    'stepId',
    'responses',
    'current',
  };

  factory JourneyState.fromJson(Map<dynamic, dynamic> json) {
    final responses = _map(json, 'responses') ?? const {};
    final current = _map(json, 'current') ?? const {};
    return JourneyState(
      version: _required<int>(json, 'version'),
      attemptId: _required<String>(json, 'attemptId'),
      index: _required<int>(json, 'index'),
      stepId: _optional<String>(json, 'stepId'),
      hasStepId: json.containsKey('stepId'),
      responses: {
        for (final entry in responses.entries)
          '${entry.key}': StepState.fromJson(
            _asMap(entry.value, 'responses.${entry.key}'),
          ),
      },
      current: StepState.fromJson(current),
      extras: _extras(json, _known),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'attemptId': attemptId,
    'index': index,
    if (hasStepId) 'stepId': stepId,
    'responses': {for (final e in responses.entries) e.key: e.value.toJson()},
    'current': current.toJson(),
    ...extras,
  };
}

/// One step's saved state: either a finished response or the work in
/// progress (`current`, `resumeState`).
@immutable
class StepState {
  const StepState({
    this.completed,
    this.done,
    this.freeDone,
    this.needsCorrection,
    this.migrated,
    this.legacySoundChart,
    this.outcome,
    this.mistakes,
    this.selected,
    this.touched,
    this.reviewItems,
    this.placements,
    this.objectiveEvidence,
    this.prediction,
    this.frame,
    this.shoeA,
    this.shoeB,
    this.feedback,
    this.resumeState,
    this.extras = const {},
    this.explicitNulls = const {},
  });

  final bool? completed, done, freeDone, needsCorrection, migrated;
  final bool? legacySoundChart;

  /// `firstTry`, `afterHint` or `explained` (see [outcomes]).
  final String? outcome;
  final int? mistakes, frame, shoeA, shoeB;
  final List<String>? selected, touched, reviewItems;
  final Map<String, String>? placements, objectiveEvidence;
  final String? prediction, feedback;
  final StepState? resumeState;

  /// Scene state (`lab`, `bean`, `light`, ...) and unknown keys, verbatim.
  final Map<String, Object?> extras;

  /// Known keys that were stored as an explicit `null` (kept so a saved
  /// journey round-trips exactly; `null` and absent mean the same).
  final Set<String> explicitNulls;

  static const outcomes = {'firstTry', 'afterHint', 'explained'};

  bool get isCompleted => completed == true;

  static const _known = {
    'completed',
    'done',
    'freeDone',
    'needsCorrection',
    'migrated',
    'legacySoundChart',
    'outcome',
    'mistakes',
    'selected',
    'touched',
    'reviewItems',
    'placements',
    'objectiveEvidence',
    'prediction',
    'frame',
    'shoeA',
    'shoeB',
    'feedback',
    'resumeState',
  };

  factory StepState.fromJson(Map<dynamic, dynamic> json) {
    final outcome = _optional<String>(json, 'outcome');
    if (outcome != null && !outcomes.contains(outcome)) {
      throw FormatException('Unknown outcome', outcome);
    }
    final evidence = _stringMap(json, 'objectiveEvidence');
    if (evidence != null && evidence.values.any((v) => !outcomes.contains(v))) {
      throw const FormatException('Unknown objective outcome');
    }
    final resume = _map(json, 'resumeState');
    return StepState(
      completed: _optional<bool>(json, 'completed'),
      done: _optional<bool>(json, 'done'),
      freeDone: _optional<bool>(json, 'freeDone'),
      needsCorrection: _optional<bool>(json, 'needsCorrection'),
      migrated: _optional<bool>(json, 'migrated'),
      legacySoundChart: _optional<bool>(json, 'legacySoundChart'),
      outcome: outcome,
      mistakes: _optional<int>(json, 'mistakes'),
      selected: _stringList(json, 'selected'),
      touched: _stringList(json, 'touched'),
      reviewItems: _stringList(json, 'reviewItems'),
      placements: _stringMap(json, 'placements'),
      objectiveEvidence: evidence,
      prediction: _optional<String>(json, 'prediction'),
      frame: _optional<int>(json, 'frame'),
      shoeA: _optional<int>(json, 'shoeA'),
      shoeB: _optional<int>(json, 'shoeB'),
      feedback: _optional<String>(json, 'feedback'),
      resumeState: resume == null ? null : StepState.fromJson(resume),
      extras: _extras(json, _known),
      explicitNulls: {
        for (final e in json.entries)
          if (e.value == null && _known.contains('${e.key}')) '${e.key}',
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'completed': ?completed,
    'done': ?done,
    'freeDone': ?freeDone,
    'needsCorrection': ?needsCorrection,
    'migrated': ?migrated,
    'legacySoundChart': ?legacySoundChart,
    'outcome': ?outcome,
    'mistakes': ?mistakes,
    'selected': ?selected,
    'touched': ?touched,
    'reviewItems': ?reviewItems,
    'placements': ?placements,
    'objectiveEvidence': ?objectiveEvidence,
    'prediction': ?prediction,
    'frame': ?frame,
    'shoeA': ?shoeA,
    'shoeB': ?shoeB,
    'feedback': ?feedback,
    if (resumeState != null) 'resumeState': resumeState!.toJson(),
    for (final key in explicitNulls) key: null,
    ...extras,
  };
}

// ---- strict field readers --------------------------------------------------

T _required<T>(Map<dynamic, dynamic> json, String key) {
  final value = json[key];
  if (value is T) return value;
  throw FormatException('Expected $T for "$key"', '${value.runtimeType}');
}

T? _optional<T>(Map<dynamic, dynamic> json, String key) {
  final value = json[key];
  if (value == null || value is T) return value as T?;
  throw FormatException('Expected $T for "$key"', '${value.runtimeType}');
}

Map<dynamic, dynamic>? _map(Map<dynamic, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  return _asMap(value, key);
}

Map<dynamic, dynamic> _asMap(Object? value, String key) {
  if (value is Map) return value;
  throw FormatException(
    'Expected an object for "$key"',
    '${value.runtimeType}',
  );
}

List<String>? _stringList(Map<dynamic, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is List && value.every((v) => v is String)) {
    return List<String>.unmodifiable(value.cast<String>());
  }
  throw FormatException('Expected a list of strings for "$key"');
}

Map<String, String>? _stringMap(Map<dynamic, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is Map && value.values.every((v) => v is String)) {
    return Map<String, String>.unmodifiable({
      for (final e in value.entries) '${e.key}': e.value as String,
    });
  }
  throw FormatException('Expected a string map for "$key"');
}

Map<String, Object?> _extras(Map<dynamic, dynamic> json, Set<String> known) => {
  for (final e in json.entries)
    if (!known.contains('${e.key}')) '${e.key}': e.value,
};
