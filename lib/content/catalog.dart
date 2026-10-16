import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    : subject = j['subject'] as String? ?? 'science',
      title = j['title'] as String? ?? 'Science',
      arabic = j['ar'] as String? ?? 'العلوم',
      welcome =
          j['welcome'] as String? ??
          'Welcome to our science islands. Tap Biology Island to explore.',
      islands = (j['islands'] as List)
          .map((v) => IslandInfo.fromJson(Map<String, dynamic>.from(v)))
          .toList(),
      parentRules = List<Map<String, dynamic>>.from(j['parentRules']);
  final String subject, title, arabic, welcome;
  final List<IslandInfo> islands;
  final List<Map<String, dynamic>> parentRules;
  Iterable<LevelInfo> get levels => islands.expand((i) => i.levels);
  bool islandUnlocked(int index, AppData data) =>
      index == 0 ||
      data
          .progressForSubject(subject)
          .isAdventureComplete(islands[index - 1].levels.last.id);
  bool levelUnlocked(int islandIndex, int levelIndex, AppData data) =>
      islandUnlocked(islandIndex, data) &&
      (levelIndex == 0 ||
          data
              .progressForSubject(subject)
              .isAdventureComplete(
                islands[islandIndex].levels[levelIndex - 1].id,
              ));
  static Future<Catalog> load() async => Catalog.fromJson(
    jsonDecode(await rootBundle.loadString('assets/content/catalog.json'))
        as Map<String, dynamic>,
  );
  static Future<Catalog> loadMaths() async => Catalog.fromJson(
    jsonDecode(await rootBundle.loadString('assets/content/maths_catalog.json'))
        as Map<String, dynamic>,
  );
}

final mathsCatalogProvider = FutureProvider<Catalog>(
  (ref) => Catalog.loadMaths(),
);
