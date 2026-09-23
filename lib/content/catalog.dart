import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/models.dart';

class LevelInfo {
  LevelInfo.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      title = j['title'] as String,
      arabic = j['ar'] as String,
      quiz = j['quiz'] as bool? ?? false;
  final String id, title, arabic;
  final bool quiz;
}

class IslandInfo {
  IslandInfo.fromJson(Map<String, dynamic> j)
    : title = j['title'] as String,
      arabic = j['ar'] as String,
      color = int.parse(j['color'] as String, radix: 16),
      levels = (j['levels'] as List)
          .map((v) => LevelInfo.fromJson(Map<String, dynamic>.from(v)))
          .toList();
  final String title, arabic;
  final int color;
  final List<LevelInfo> levels;
}

class Catalog {
  Catalog.fromJson(Map<String, dynamic> j)
    : islands = (j['islands'] as List)
          .map((v) => IslandInfo.fromJson(Map<String, dynamic>.from(v)))
          .toList(),
      parentRules = List<Map<String, dynamic>>.from(j['parentRules']);
  final List<IslandInfo> islands;
  final List<Map<String, dynamic>> parentRules;
  Iterable<LevelInfo> get levels => islands.expand((i) => i.levels);
  bool islandUnlocked(int index, AppData data) =>
      index == 0 || data.isComplete(islands[index - 1].levels.last.id);
  bool levelUnlocked(int islandIndex, int levelIndex, AppData data) =>
      islandUnlocked(islandIndex, data) &&
      (levelIndex == 0 ||
          data.isComplete(islands[islandIndex].levels[levelIndex - 1].id));
  static Future<Catalog> load() async => Catalog.fromJson(
    jsonDecode(await rootBundle.loadString('assets/content/catalog.json'))
        as Map<String, dynamic>,
  );
}
