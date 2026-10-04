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
  static const availableIds = [
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
  static Future<LessonLibrary> load() async {
    final result = <String, Lesson>{};
    for (final id in availableIds) {
      result[id] = Lesson(
        jsonDecode(
          await rootBundle.loadString('assets/content/playable/$id.json'),
        ),
      );
    }
    return LessonLibrary(result);
  }
}
