import '../../core/models.dart';
import '../../core/adventure_progress.dart';

class GardenItem {
  GardenItem(Map<String, dynamic> j)
    : id = j['id'],
      name = j['name'],
      nameAr = j['nameAr'],
      alive = j['alive'],
      hint = j['hint'],
      explanation = j['explanation'];
  final String id, name, nameAr, hint, explanation;
  final bool alive;
}

class GardenContent {
  GardenContent(this.json)
    : items = (json['items'] as List)
          .map((i) => GardenItem(Map<String, dynamic>.from(i)))
          .toList();
  final Map<String, dynamic> json;
  final List<GardenItem> items;
  String text(String key) => json['ui'][key] as String;
  GardenItem item(String id) => items.firstWhere((i) => i.id == id);
  int get version => json['version'];
}

/// Practice is deliberately separate from the complete unit assessment.
class GardenRound {
  GardenRound({
    required this.version,
    String? roundId,
    this.selected,
    this.mistakes = 0,
    this.feedback = false,
    this.completedOnce = false,
    Map<String, String>? results,
    List<Map<String, dynamic>>? history,
  }) : roundId = roundId ?? DateTime.now().microsecondsSinceEpoch.toString(),
       results = results ?? {},
       history = history ?? [];
  static const storageKey = 'unit_01.garden';
  final int version;
  final String roundId;
  String? selected;
  int mistakes;
  bool feedback;
  final bool completedOnce;
  final Map<String, String> results;
  final List<Map<String, dynamic>> history;
  bool finished(GardenContent c) =>
      results.length == c.items.length && selected == null;
  DecisionOutcome? answer(GardenItem item, bool alive) {
    if (feedback || results.containsKey(item.id)) return null;
    if (alive == item.alive) {
      final outcome = mistakes == 0
          ? DecisionOutcome.firstTry
          : DecisionOutcome.afterHint;
      results[item.id] = outcome.name;
      feedback = true;
      return outcome;
    }
    mistakes++;
    if (mistakes >= 2) {
      results[item.id] = DecisionOutcome.explained.name;
      feedback = true;
      return DecisionOutcome.explained;
    }
    return null;
  }

  void select(String id) {
    if (results.containsKey(id)) return;
    selected = id;
    mistakes = 0;
    feedback = false;
  }

  void next() {
    selected = null;
    mistakes = 0;
    feedback = false;
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'completedOnce': completedOnce || gardenResultsComplete(results),
    'roundId': roundId,
    'selected': selected,
    'mistakes': mistakes,
    'feedback': feedback,
    'results': Map<String, String>.from(results),
    'history': history.map((h) => Map<String, dynamic>.from(h)).toList(),
  };
  factory GardenRound.restore(Map<String, dynamic> j, GardenContent content) {
    if (j['version'] != content.version)
      return GardenRound(version: content.version);
    final results = Map<String, String>.from(j['results'] ?? {})
      ..removeWhere(
        (id, v) =>
            !content.items.any((i) => i.id == id) ||
            !DecisionOutcome.values.any((o) => o.name == v),
      );
    final selected = j['selected'] as String?;
    return GardenRound(
      version: content.version,
      completedOnce: gardenAdventureComplete(j),
      roundId: j['roundId'],
      selected: content.items.any((i) => i.id == selected) ? selected : null,
      mistakes: (j['mistakes'] as int? ?? 0).clamp(0, 2),
      feedback: j['feedback'] == true,
      results: results,
      history: List<Map<String, dynamic>>.from(j['history'] ?? []),
    );
  }
  GardenRound replay() => GardenRound(
    version: version,
    completedOnce: gardenAdventureComplete(toJson()),
    history: [
      ...history,
      {
        'roundId': roundId,
        'date': DateTime.now().toIso8601String(),
        'results': Map<String, String>.from(results),
      },
    ].reversed.take(20).toList().reversed.toList(),
  );
}
