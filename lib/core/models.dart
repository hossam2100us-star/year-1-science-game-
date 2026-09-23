import 'dart:convert';
import 'dart:typed_data';

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
  AppSettings copyWith({
    bool? arabic,
    int? breakMinutes,
    bool? sound,
    bool? music,
    bool? narration,
    double? volume,
    String? boyVoice,
    String? girlVoice,
  }) => AppSettings(
    arabic: arabic ?? this.arabic,
    breakMinutes: breakMinutes ?? this.breakMinutes,
    sound: sound ?? this.sound,
    music: music ?? this.music,
    narration: narration ?? this.narration,
    volume: volume ?? this.volume,
    boyVoice: boyVoice ?? this.boyVoice,
    girlVoice: girlVoice ?? this.girlVoice,
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
  });
  final String unitId;
  final DateTime completedAt;
  final Map<String, DecisionOutcome> objectives;
  final bool completed;
  final int effortStars;
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
  });
  final ChildProfile? profile;
  final AppSettings settings;
  final List<UnitAttempt> attempts;
  final Map<String, int> dailySeconds;
  final bool pendingPhoto;
  AppData copyWith({
    ChildProfile? profile,
    AppSettings? settings,
    List<UnitAttempt>? attempts,
    Map<String, int>? dailySeconds,
    bool? pendingPhoto,
  }) => AppData(
    profile: profile ?? this.profile,
    settings: settings ?? this.settings,
    attempts: attempts ?? this.attempts,
    dailySeconds: dailySeconds ?? this.dailySeconds,
    pendingPhoto: pendingPhoto ?? this.pendingPhoto,
  );
  AppData resetProgress() => AppData(profile: profile, settings: settings);
  bool isComplete(String id) =>
      attempts.any((a) => a.unitId == id && a.completed);
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
    'schemaVersion': 1,
    'profile': profile?.toJson(),
    'settings': settings.toJson(),
    'attempts': attempts.map((a) => a.toJson()).toList(),
    'dailySeconds': dailySeconds,
    'pendingPhoto': pendingPhoto,
  };
  factory AppData.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] != 1)
      throw const FormatException('Unsupported save version');
    return AppData(
      profile: j['profile'] == null
          ? null
          : ChildProfile.fromJson(Map<String, dynamic>.from(j['profile'])),
      settings: AppSettings.fromJson(Map<String, dynamic>.from(j['settings'])),
      attempts: (j['attempts'] as List)
          .map((a) => UnitAttempt.fromJson(Map<String, dynamic>.from(a)))
          .toList(),
      dailySeconds: Map<String, int>.from(j['dailySeconds']),
      pendingPhoto: j['pendingPhoto'] as bool? ?? false,
    );
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
