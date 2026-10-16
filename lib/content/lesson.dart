import 'dart:convert';

import 'package:flutter/services.dart';

class PictureItem {
  PictureItem.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      label = j['label'],
      art = j['art'] ?? j['id'];
  final String id, label, art;
}

class LessonStep {
  LessonStep(this.json);
  final Map<String, dynamic> json;
  String get id => json['id'];
  String get kind => json['kind'];
  String get title => json['title'];
  String get prompt => json['prompt'];
  String get scene => json['scene'] ?? 'garden';
  String get section => json['section'] ?? 'Explore';
  String get hint => json['hint'] ?? '';
  String get explanation => json['explanation'] ?? '';
  String get shortExplanation => json['shortExplanation'] ?? explanation;
  String get objective => json['objective'] ?? '';
  Set<String> get assessedObjectives => assessed
      ? {objective, ...List<String>.from(json['extraObjectives'] ?? [])}
      : {};
  String? get focus => json['focus'];
  bool get assessed => json['assessed'] == true;
  List<PictureItem> get options => (json['options'] as List)
      .map((v) => PictureItem.fromJson(Map<String, dynamic>.from(v)))
      .toList();
  List<PictureItem> get targets => (json['targets'] as List)
      .map((v) => PictureItem.fromJson(Map<String, dynamic>.from(v)))
      .toList();
  Map<String, dynamic>? get answer =>
      json['answer'] == null ? null : Map<String, dynamic>.from(json['answer']);
  List<Map<String, dynamic>> get frames =>
      List<Map<String, dynamic>>.from(json['frames'] ?? []);
  List<Map<String, dynamic>> get table =>
      List<Map<String, dynamic>>.from(json['table'] ?? []);
  bool get isMapping => answer?['type'] == 'mapping';
  bool get isMulti => answer?['type'] == 'set';
  bool get isOrder => answer?['type'] == 'sequence';
  bool get isFree => [
    'explore',
    'story',
    'free-pair',
    'free-plant',
    'science-lab',
    'free-measure',
    'predict-then-reveal',
  ].contains(kind);
  String label(String id) =>
      [...options, ...targets].where((e) => e.id == id).firstOrNull?.label ??
      id.replaceAll('_', ' ');

  /// What a discovery says and shows: the name first (it is the word being
  /// taught), then the description, unless the description already names it
  /// ("Ocean. The biggest water of all, and salty."; teacher review 4).
  String discoveryText(String id) {
    final name = label(id);
    final description = json['senseDescriptions']?[id];
    if (description is! String || description.isEmpty) return name;
    final named = RegExp(
      '\\b${RegExp.escape(name)}\\b',
      caseSensitive: false,
    ).hasMatch(description);
    return named ? description : '$name. $description';
  }
}

class Lesson {
  Lesson(this.json)
    : steps = (json['steps'] as List)
          .map((v) => LessonStep(Map<String, dynamic>.from(v)))
          .toList();
  final Map<String, dynamic> json;
  final List<LessonStep> steps;
  String get id => json['id'];
  String get title => json['title'];
  String get subject => json['subject'] as String? ?? 'science';
  bool get quiz => json['quiz'] == true;
  int get version => json['contentVersion'];
  List<Map<String, dynamic>> get stickers =>
      List<Map<String, dynamic>>.from(json['stickers']);
  List<Map<String, dynamic>> get homeActivities =>
      List<Map<String, dynamic>>.from(json['homeActivities']);
  Set<String> get objectives =>
      steps.expand((s) => s.assessedObjectives).toSet();
}

class LessonLibrary {
  LessonLibrary(this.lessons);
  final Map<String, Lesson> lessons;
  static const scienceIds = [
    'unit_01',
    'unit_02',
    'unit_03',
    'quiz_01',
    'unit_04',
    'quiz_02',
    'unit_05',
    'unit_06',
    'unit_07',
    'quiz_03',
    'unit_08',
    'unit_09',
    'quiz_04',
  ];
  static const mathsIds = [
    'math_unit_01',
    'math_unit_02',
    'math_unit_03',
    'math_unit_04',
    'math_unit_05',
    'math_unit_06',
    'math_quiz_01',
    'math_unit_07',
    'math_unit_08',
    'math_unit_09',
    'math_unit_10',
    'math_unit_11',
    'math_unit_12',
    'math_quiz_02',
    'math_unit_13',
    'math_unit_14',
    'math_unit_15',
    'math_unit_16',
    'math_unit_17',
    'math_unit_18',
    'math_quiz_03',
    'math_charts',
  ];
  static const availableIds = [...scienceIds, ...mathsIds];
  static Future<LessonLibrary> load() async {
    final result = <String, Lesson>{};
    final arabic = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString('assets/content/parent_ar.json')),
    );
    for (final id in scienceIds) {
      final json = Map<String, dynamic>.from(
        jsonDecode(
          await rootBundle.loadString('assets/content/playable/$id.json'),
        ),
      );
      addParentArabic(id, json, arabic);
      result[id] = Lesson(json);
    }
    return LessonLibrary(result);
  }

  static Future<LessonLibrary> loadMaths() async {
    final entries = await Future.wait<MapEntry<String, Lesson>>(
      mathsIds.map((id) async {
        final json = Map<String, dynamic>.from(
          jsonDecode(
            await rootBundle.loadString('assets/content/playable/$id.json'),
          ),
        );
        return MapEntry(id, Lesson(json));
      }),
    );
    return LessonLibrary(Map.fromEntries(entries));
  }

  static Future<LessonLibrary> loadAll() async {
    final libraries = await Future.wait<LessonLibrary>([load(), loadMaths()]);
    return LessonLibrary({...libraries[0].lessons, ...libraries[1].lessons});
  }

  /// Adds `textAr`/`safetyAr` to the activities shown in the Arabic parent
  /// area (`assets/content/parent_ar.json`). An activity without Arabic keeps
  /// only its English text, which the report then shows left to right.
  static void addParentArabic(
    String id,
    Map<String, dynamic> lesson,
    Map<String, dynamic> arabic,
  ) {
    final goals = Map<String, dynamic>.from(arabic['goal'] ?? const {});
    final homes = Map<String, dynamic>.from(arabic['home'] ?? const {});
    final safety = Map<String, dynamic>.from(arabic['safety'] ?? const {});
    for (final activity in [...?lesson['goalActivities'] as List?]) {
      final a = activity as Map<String, dynamic>;
      a['textAr'] = goals['$id/${a['objective']}'];
      a['safetyAr'] = safety[a['safety']];
    }
    for (final activity in [...?lesson['homeActivities'] as List?]) {
      final a = activity as Map<String, dynamic>;
      a['textAr'] = homes[id];
      a['safetyAr'] = safety[a['safety']];
    }
  }
}
