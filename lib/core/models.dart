import 'dart:convert';
import 'dart:typed_data';

import 'adventure_progress.dart';
import 'ids.dart';

enum ChildGender { boy, girl }

enum PaletteChoice { automatic, ocean, berry, forest }

enum DecisionOutcome { firstTry, afterHint, explained }

class ChildProfile {
  const ChildProfile({
    this.name = '',
    this.gender = ChildGender.boy,
    this.avatar = 0,
    this.photo,
    this.palette = PaletteChoice.automatic,
  });
  final String name;
  final ChildGender gender;
  final int avatar;
  final Uint8List? photo;
  final PaletteChoice palette;
  String get guideName => gender == ChildGender.girl ? 'Zizi' : 'Zizo';
  String get greeting =>
      name.trim().isEmpty ? 'Hello, scientist!' : 'Hello, ${name.trim()}!';
  Map<String, dynamic> toJson() => {
    'name': name,
    'gender': gender.name,
    'avatar': avatar,
    'photo': photo == null ? null : base64Encode(photo!),
    'palette': palette.name,
  };
  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
    name: json['name'] as String? ?? '',
    gender: ChildGender.values.byName(json['gender'] as String? ?? 'boy'),
    avatar: (json['avatar'] as int? ?? 0).clamp(0, 2),
    photo: json['photo'] == null ? null : base64Decode(json['photo'] as String),
    palette: PaletteChoice.values.byName(
      json['palette'] as String? ?? 'automatic',
    ),
  );
}

class AppSettings {
  const AppSettings({
    this.arabic = true,
    this.breakMinutes = 12,
    this.sound = true,
    this.music = true,
    this.narration = true,
    this.volume = .85,
    this.boyVoice,
    this.girlVoice,
  });
  final bool arabic, sound, music, narration;
  final int breakMinutes;
  final double volume;
  final String? boyVoice, girlVoice;

  /// Voices are passed as getters so a caller can reset one to the device
  /// default: `copyWith(boyVoice: () => null)`. Omitting it keeps the value.
  AppSettings copyWith({
    bool? arabic,
    int? breakMinutes,
    bool? sound,
    bool? music,
    bool? narration,
    double? volume,
    String? Function()? boyVoice,
    String? Function()? girlVoice,
  }) => AppSettings(
    arabic: arabic ?? this.arabic,
    breakMinutes: breakMinutes ?? this.breakMinutes,
    sound: sound ?? this.sound,
    music: music ?? this.music,
    narration: narration ?? this.narration,
    volume: volume ?? this.volume,
    boyVoice: boyVoice == null ? this.boyVoice : boyVoice(),
    girlVoice: girlVoice == null ? this.girlVoice : girlVoice(),
  );
  Map<String, dynamic> toJson() => {
    'arabic': arabic,
    'breakMinutes': breakMinutes,
    'sound': sound,
    'music': music,
    'narration': narration,
    'volume': volume,
    'boyVoice': boyVoice,
    'girlVoice': girlVoice,
  };
  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    arabic: j['arabic'] as bool? ?? true,
    breakMinutes: (j['breakMinutes'] as int? ?? 12).clamp(5, 30),
    sound: j['sound'] as bool? ?? true,
    music: j['music'] as bool? ?? true,
    narration: j['narration'] as bool? ?? true,
    volume: (j['volume'] as num? ?? .85).toDouble().clamp(0, 1),
    boyVoice: j['boyVoice'] as String?,
    girlVoice: j['girlVoice'] as String?,
  );
}

/// A completed assessment attempt. Exploration and predictions are excluded.
/// The first recorded outcome per objective is retained, preventing score inflation.
class UnitAttempt {
  const UnitAttempt({
    required this.unitId,
    required this.completedAt,
    required this.objectives,
    required this.completed,
    required this.effortStars,
    this.attemptId = '',
    this.contentVersion = 1,
  });
  final String unitId;
  final DateTime completedAt;
  final Map<String, DecisionOutcome> objectives;
  final bool completed;
  final int effortStars;
  final String attemptId;
  final int contentVersion;
  int get firstTry =>
      objectives.values.where((o) => o == DecisionOutcome.firstTry).length;
  int get afterHint =>
      objectives.values.where((o) => o == DecisionOutcome.afterHint).length;
  int get explained =>
      objectives.values.where((o) => o == DecisionOutcome.explained).length;
  double? get accuracy =>
      objectives.isEmpty ? null : firstTry / objectives.length;
  Map<String, dynamic> toJson() => {
    'unitId': unitId,
    'completedAt': completedAt.toIso8601String(),
    'objectives': objectives.map((k, v) => MapEntry(k, v.name)),
    'completed': completed,
    'effortStars': effortStars,
    'attemptId': attemptId,
    'contentVersion': contentVersion,
  };
  factory UnitAttempt.fromJson(Map<String, dynamic> j) => UnitAttempt(
    unitId: j['unitId'] as String,
    completedAt: DateTime.parse(j['completedAt'] as String),
    objectives: (j['objectives'] as Map).map(
      (k, v) =>
          MapEntry(k as String, DecisionOutcome.values.byName(v as String)),
    ),
    completed: j['completed'] as bool,
    effortStars: (j['effortStars'] as int).clamp(0, 3),
    attemptId: j['attemptId'] as String? ?? '',
    contentVersion: j['contentVersion'] as int? ?? 1,
  );
}

class AttemptRecorder {
  final Map<String, DecisionOutcome> _outcomes = {};
  void record(String id, DecisionOutcome outcome, {bool assessed = true}) {
    if (assessed) _outcomes.putIfAbsent(id, () => outcome);
  }

  Map<String, DecisionOutcome> get outcomes => Map.unmodifiable(_outcomes);
}

class AppData {
  const AppData({
    this.profile,
    this.settings = const AppSettings(),
    this.attempts = const [],
    this.dailySeconds = const {},
    this.pendingPhoto = false,
    this.journeys = const {},
    this.otherSubjects = const {},
    this.activeChildId = 'local-child',
    this.savedChildren = const {},
    this.quarantinedChildren = const {},
  });
  final ChildProfile? profile;
  final AppSettings settings;
  final List<UnitAttempt> attempts;
  final Map<String, int> dailySeconds;
  final bool pendingPhoto;
  final Map<String, Map<String, dynamic>> journeys;

  /// Science retains its typed accessors; other subjects have isolated records.
  final Map<String, Map<String, dynamic>> otherSubjects;
  final String activeChildId;
  final Map<String, Map<String, dynamic>> savedChildren;

  /// Child records that could not be read, kept verbatim (AUD-006).
  ///
  /// They are not selectable, are written back unchanged on every save so
  /// nothing is lost, and are offered to parents as a rescue export.
  final Map<String, Object?> quarantinedChildren;
  Map<String, Map<String, dynamic>> get childRecords => {
    ...savedChildren,
    activeChildId: _childJson(),
  };
  AppData selectChild(String id) {
    if (id == activeChildId) return this;
    final records = childRecords;
    final child = records.remove(id);
    if (child == null) throw StateError('Unknown child');
    return AppData.fromJson(child).copyWith(
      activeChildId: id,
      savedChildren: records,
      quarantinedChildren: quarantinedChildren,
    );
  }

  AppData addChild(String id, ChildProfile child) {
    if (childRecords.containsKey(id)) throw StateError('Duplicate child ID');
    return AppData(
      profile: child,
      settings: settings,
      activeChildId: id,
      savedChildren: {
        for (final entry in childRecords.entries)
          if (entry.value['profile'] != null) entry.key: entry.value,
      },
      quarantinedChildren: quarantinedChildren,
    );
  }

  AppData removeChild(String id, {required String emptyId}) {
    final records = childRecords;
    if (records.remove(id) == null) throw StateError('Unknown child');
    if (id != activeChildId) {
      records.remove(activeChildId);
      return copyWith(savedChildren: records);
    }
    records.removeWhere((_, value) => value['profile'] == null);
    if (records.isEmpty) {
      return AppData(
        activeChildId: emptyId,
        quarantinedChildren: quarantinedChildren,
      );
    }
    final nextId = records.keys.first;
    final next = records.remove(nextId)!;
    return AppData.fromJson(next).copyWith(
      activeChildId: nextId,
      savedChildren: records,
      quarantinedChildren: quarantinedChildren,
    );
  }

  AppData changeChild(String id, AppData Function(AppData) change) {
    if (id == activeChildId) return change(this);
    final updated = change(selectChild(id));
    return copyWith(
      savedChildren: {...savedChildren, id: updated._childJson()},
    );
  }

  AppData copyWith({
    ChildProfile? profile,
    AppSettings? settings,
    List<UnitAttempt>? attempts,
    Map<String, int>? dailySeconds,
    bool? pendingPhoto,
    Map<String, Map<String, dynamic>>? journeys,
    Map<String, Map<String, dynamic>>? otherSubjects,
    String? activeChildId,
    Map<String, Map<String, dynamic>>? savedChildren,
    Map<String, Object?>? quarantinedChildren,
  }) => AppData(
    profile: profile ?? this.profile,
    settings: settings ?? this.settings,
    attempts: attempts ?? this.attempts,
    dailySeconds: dailySeconds ?? this.dailySeconds,
    pendingPhoto: pendingPhoto ?? this.pendingPhoto,
    journeys: journeys ?? this.journeys,
    otherSubjects: otherSubjects ?? this.otherSubjects,
    activeChildId: activeChildId ?? this.activeChildId,
    savedChildren: savedChildren ?? this.savedChildren,
    quarantinedChildren: quarantinedChildren ?? this.quarantinedChildren,
  );
  AppData resetProgress() => AppData(
    profile: profile,
    settings: settings,
    activeChildId: activeChildId,
    savedChildren: savedChildren,
    quarantinedChildren: quarantinedChildren,
  );
  bool isComplete(String id) =>
      attempts.any((a) => a.unitId == id && a.completed);

  /// Gameplay progression is separate from the parent's assessment scores.
  bool isAdventureComplete(String id) =>
      isComplete(id) ||
      (id == 'unit_01' && gardenAdventureComplete(journeys['unit_01.garden']));
  UnitAttempt? latest(String id) {
    final all = attempts.where((a) => a.unitId == id && a.completed).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return all.isEmpty ? null : all.first;
  }

  UnitAttempt? best(String id) {
    final all =
        attempts
            .where((a) => a.unitId == id && a.completed && a.accuracy != null)
            .toList()
          ..sort((a, b) => b.accuracy!.compareTo(a.accuracy!));
    return all.isEmpty ? null : all.first;
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 3,
    'activeChildId': activeChildId,
    'children': childRecords,
    if (quarantinedChildren.isNotEmpty) 'quarantine': quarantinedChildren,
  };
  Map<String, dynamic> _childJson() => {
    'schemaVersion': 2,
    'profile': profile?.toJson(),
    'settings': settings.toJson(),
    'dailySeconds': dailySeconds,
    'pendingPhoto': pendingPhoto,
    'subjects': {
      ...otherSubjects,
      'science': {
        'attempts': attempts.map((a) => a.toJson()).toList(),
        'journeys': journeys,
      },
    },
  };
  factory AppData.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] == 3) return AppData._fromFamily(j);
    if (j['schemaVersion'] != 1 && j['schemaVersion'] != 2)
      throw const FormatException('Unsupported save version');
    final subjects = Map<String, dynamic>.from(j['subjects'] ?? {});
    final science = j['schemaVersion'] == 1
        ? j
        : Map<String, dynamic>.from(subjects['science'] ?? {});
    return AppData(
      profile: j['profile'] == null
          ? null
          : ChildProfile.fromJson(Map<String, dynamic>.from(j['profile'])),
      settings: j['settings'] == null
          ? const AppSettings()
          : AppSettings.fromJson(Map<String, dynamic>.from(j['settings'])),
      attempts: (science['attempts'] as List? ?? [])
          .map((a) => UnitAttempt.fromJson(Map<String, dynamic>.from(a)))
          .toList(),
      dailySeconds: Map<String, int>.from(j['dailySeconds'] ?? const {}),
      pendingPhoto: j['pendingPhoto'] as bool? ?? false,
      journeys: (science['journeys'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, Map<String, dynamic>.from(v)),
      ),
      otherSubjects: {
        for (final entry in subjects.entries)
          if (entry.key != 'science')
            entry.key: Map<String, dynamic>.from(entry.value),
      },
    );
  }

  /// Reads a schema-3 family save one child at a time, so a single damaged
  /// record no longer makes every child's progress unreadable (AUD-006).
  static AppData _fromFamily(Map<String, dynamic> j) {
    final children = j['children'];
    if (children is! Map) throw const FormatException('Invalid child list');
    final quarantine = <String, Object?>{
      ...?(j['quarantine'] as Map?)?.map((k, v) => MapEntry('$k', v)),
    };
    final readable = <String, Map<String, dynamic>>{};
    for (final entry in children.entries) {
      final id = '${entry.key}';
      final record = entry.value;
      if (_readableChild(record)) {
        readable[id] = Map<String, dynamic>.from(record as Map);
      } else {
        quarantine[id] = record;
      }
    }
    final saved = j['activeChildId'];
    final id = saved is String && readable.containsKey(saved)
        ? saved
        : readable.keys.firstOrNull;
    if (id == null) {
      // Every record is damaged: start empty under a fresh ID while the
      // damaged records stay in quarantine.
      return AppData(
        activeChildId: Ids.uuidV7(),
        quarantinedChildren: quarantine,
      );
    }
    final active = readable.remove(id)!;
    return AppData.fromJson(active).copyWith(
      activeChildId: id,
      savedChildren: readable,
      quarantinedChildren: quarantine,
    );
  }

  static bool _readableChild(Object? record) {
    if (record is! Map) return false;
    if (!const [1, 2].contains(record['schemaVersion'])) return false;
    try {
      AppData.fromJson(Map<String, dynamic>.from(record));
      return true;
    } on Object {
      return false;
    }
  }
}

/// Split foreground usage across calendar days, including midnight.
Map<String, int> addUsage(
  Map<String, int> original,
  DateTime start,
  DateTime end,
) {
  final result = Map<String, int>.from(original);
  var cursor = start;
  while (cursor.isBefore(end)) {
    final midnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
    final boundary = midnight.isBefore(end) ? midnight : end;
    final key =
        '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
    result[key] = (result[key] ?? 0) + boundary.difference(cursor).inSeconds;
    cursor = boundary;
  }
  return result;
}
